const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * When a job is created, notify matched workers via FCM (tokens on users/{uid}.fcmToken).
 */
exports.notifyMatchedWorkersOnJobCreate = functions.firestore
  .document('jobs/{jobId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const ids = data.matchedWorkerIds || [];
    if (!ids.length) return null;

    const title = 'Yeni elan';
    const body =
      (data.title && String(data.title).slice(0, 120)) || 'Yaxınlıqda yeni iş';

    const tokens = [];
    for (const uid of ids) {
      const u = await admin.firestore().collection('users').doc(uid).get();
      const t = u.get('fcmToken');
      if (t) tokens.push(t);
    }

    if (!tokens.length) return null;

    const res = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        jobId: String(context.params.jobId),
        kind: 'new_job',
      },
    });

    functions.logger.info(
      `FCM job notify: success ${res.successCount}, failure ${res.failureCount}`,
    );
    return null;
  });

/**
 * Yeni chat mesajı — qarşı tərəfə FCM (token `users/{uid}.fcmToken`).
 */
exports.notifyChatRecipientOnNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    const senderId = msg.senderId;
    if (!senderId) return null;

    const chatSnap = await admin
      .firestore()
      .collection('chats')
      .doc(context.params.chatId)
      .get();

    if (!chatSnap.exists) return null;

    const participants = chatSnap.get('participantIds') || [];
    const receiverId = participants.find((p) => p !== senderId);
    if (!receiverId) return null;

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(receiverId)
      .get();

    const token = userSnap.get('fcmToken');
    if (!token) return null;

    const preview =
      (msg.text && String(msg.text).slice(0, 140)) || 'Yeni mesaj';

    await admin.messaging().send({
      token,
      notification: {
        title: 'Yeni mesaj',
        body: preview,
      },
      data: {
        kind: 'new_message',
        threadId: String(context.params.chatId),
        senderId: String(senderId),
      },
    });

    functions.logger.info(
      `FCM chat notify → ${receiverId} (chat ${context.params.chatId})`,
    );
    return null;
  });

/**
 * Superadmin queue push -> FCM send.
 * Source document: notification_queue/{id}
 * { message: string, workersOnly: bool }
 */
exports.sendQueuedNotification = functions.firestore
  .document('notification_queue/{queueId}')
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const message = String(data.message || '').trim();
    const workersOnly = data.workersOnly === true;
    if (!message) return null;

    let usersRef = admin.firestore().collection('users');
    if (workersOnly) {
      usersRef = usersRef.where('role', '==', 'worker');
    }

    const users = await usersRef.get();
    const tokens = users.docs
      .map((d) => d.get('fcmToken'))
      .filter((t) => typeof t === 'string' && t.length > 0);

    if (!tokens.length) return null;

    const res = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: workersOnly ? 'İcraçılar üçün bildiriş' : 'Sistem bildirişi',
        body: message.slice(0, 160),
      },
      data: {
        kind: 'super_broadcast',
      },
    });

    functions.logger.info(
      `FCM queued push: success ${res.successCount}, failure ${res.failureCount}`,
    );
    return null;
  });

async function requireSuperadmin(auth) {
  if (!auth || !auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Login tələb olunur');
  }
  const me = await admin.firestore().collection('users').doc(auth.uid).get();
  const role = me.get('role');
  if (role !== 'superadmin') {
    throw new functions.https.HttpsError('permission-denied', 'Yalnız superadmin');
  }
  return me;
}

exports.createAdminUserBySuperadmin = functions.https.onCall(async (data, context) => {
  await requireSuperadmin(context.auth);

  const name = String(data.name || '').trim();
  const email = String(data.email || '').trim().toLowerCase();
  const password = String(data.password || '');
  if (!name || !email || password.length < 6) {
    throw new functions.https.HttpsError('invalid-argument', 'Məlumatlar yanlışdır');
  }

  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (_) {
    userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });
  }

  await admin.firestore().collection('users').doc(userRecord.uid).set({
    id: userRecord.uid,
    name,
    email,
    role: 'admin',
    isBlocked: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await admin.firestore().collection('logs').add({
    action: 'create_admin',
    performedBy: context.auth.uid,
    targetId: userRecord.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid: userRecord.uid };
});

exports.deleteUserBySuperadmin = functions.https.onCall(async (data, context) => {
  await requireSuperadmin(context.auth);
  const uid = String(data.uid || '').trim();
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'uid tələb olunur');
  }

  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const role = userDoc.get('role');
  if (role === 'superadmin' || role === 'super_admin') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Superadmin silinə bilməz',
    );
  }

  await admin.firestore().collection('users').doc(uid).delete();
  await admin.firestore().collection('workers').doc(uid).delete();
  try {
    await admin.auth().deleteUser(uid);
  } catch (_) {}

  await admin.firestore().collection('logs').add({
    action: 'delete_user',
    performedBy: context.auth.uid,
    targetId: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
