/**
 * Auth + Firestore emulyatorları işlək olanda işə salın:
 *   npm run seed:emulator   (layihə kökündən) və ya
 *   cd functions && npm run seed:emulator
 *
 * Yaradır: 1 superadmin, 1 admin, 1 marketplace user, 1 worker (+ workers sənədi).
 * Firebase Auth minimum şifrə uzunluğu 6-dır.
 */
const admin = require('firebase-admin');

const PROJECT_ID = 'demo-qonsudan-xidmet';

process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

const db = admin.firestore();
const loc = new admin.firestore.GeoPoint(40.4093, 49.8671);

async function ensureAuthUser(email, password, displayName) {
  const e = email.trim().toLowerCase();
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(e);
    await admin.auth().updateUser(userRecord.uid, { password, displayName });
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      userRecord = await admin.auth().createUser({
        email: e,
        password,
        displayName,
      });
    } else {
      throw err;
    }
  }
  return userRecord.uid;
}

async function upsertStaffUser({
  email,
  password,
  role,
  name,
  surname,
  phoneKey,
}) {
  const e = email.trim().toLowerCase();
  const uid = await ensureAuthUser(
    e,
    password,
    `${name} ${surname}`.trim(),
  );
  await db
    .collection('users')
    .doc(uid)
    .set(
      {
        id: uid,
        name,
        surname,
        email: e,
        phoneKey,
        phone: phoneKey,
        role,
        location: loc,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isBlocked: false,
      },
      { merge: true },
    );
  console.log(`[seed] ${role}: ${e}  uid=${uid}`);
}

async function upsertMarketplaceUser({
  email,
  password,
  role,
  name,
  surname,
  phoneKey,
}) {
  if (role !== 'user' && role !== 'worker') {
    throw new Error(`upsertMarketplaceUser: invalid role ${role}`);
  }
  const e = email.trim().toLowerCase();
  const uid = await ensureAuthUser(
    e,
    password,
    `${name} ${surname}`.trim(),
  );
  await db
    .collection('users')
    .doc(uid)
    .set(
      {
        id: uid,
        name,
        surname,
        email: e,
        phoneKey,
        phone: phoneKey,
        role,
        location: loc,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isBlocked: false,
      },
      { merge: true },
    );

  if (role === 'worker') {
    const dn = `${name} ${surname}`.trim();
    await db
      .collection('workers')
      .doc(uid)
      .set(
        {
          userId: uid,
          displayName: dn.length ? dn : 'İcraçı',
          skills: ['cleaning', 'repair'],
          rating: 0,
          ratingCount: 0,
          isAvailable: true,
          availability: 'active',
          bio: 'Demo icraçı (emulyator)',
        },
        { merge: true },
      );
  }
  console.log(`[seed] ${role}: ${e}  uid=${uid}`);
}

(async () => {
  const adminPass = process.env.ADMIN_SEED_PASSWORD || 'admin1';
  const demoPass = process.env.DEMO_USER_SEED_PASSWORD || 'demo123456';
  if (adminPass.length < 6 || demoPass.length < 6) {
    console.error('[seed] Passwords must be at least 6 characters.');
    process.exit(1);
  }

  await upsertStaffUser({
    email: 'superadmin@demo.local',
    password: 'superadmin',
    role: 'superadmin',
    name: 'Super',
    surname: 'Admin',
    phoneKey: '+994501111111',
  });
  await upsertStaffUser({
    email: 'admin@demo.local',
    password: adminPass,
    role: 'admin',
    name: 'Panel',
    surname: 'Admin',
    phoneKey: '+994502222222',
  });
  await upsertMarketplaceUser({
    email: 'user@demo.local',
    password: demoPass,
    role: 'user',
    name: 'Demo',
    surname: 'İstifadəçi',
    phoneKey: '+994503333333',
  });
  await upsertMarketplaceUser({
    email: 'worker@demo.local',
    password: demoPass,
    role: 'worker',
    name: 'Demo',
    surname: 'İcraçı',
    phoneKey: '+994504444444',
  });

  console.log('');
  console.log('[seed] Hazır hesablar (emulyator):');
  console.log('  superadmin@demo.local  / superadmin');
  console.log(`  admin@demo.local       / ${adminPass}`);
  console.log(`  user@demo.local        / ${demoPass}`);
  console.log(`  worker@demo.local      / ${demoPass}`);
  console.log('[seed] done.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
