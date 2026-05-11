import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

/// İstifadəçi və icraçı profilləri üçün birbaşa Firestore əməliyyatları.
///
/// Auth sessiyası [FirebaseAuth] ilə; profil yenilənəndən sonra çağıran
/// [AuthService.refreshProfile] çağırmalıdır (əgər UI sinxron qalmalıdırsa).
class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<Map<String, dynamic>?> fetchWorkerDoc(String uid) async {
    final doc = await _db.collection('workers').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> writeLocation(GeoPoint location) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'location': location,
    });
  }

  /// Sahib öz `users/{uid}` sənədində təhlükəsizlik qaydalarına uyğun sahələri yeniləyir.
  Future<void> updateMyUserFields(Map<String, dynamic> patch) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    if (patch.isEmpty) return;
    await _db.collection('users').doc(uid).update(patch);
  }

  /// İcraçı öz `workers/{uid}` sənədini yeniləyir (bacarıq, mövcudluq və s.).
  Future<void> updateMyWorkerFields(Map<String, dynamic> patch) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    if (patch.isEmpty) return;
    await _db.collection('workers').doc(uid).update(patch);
  }

  /// Profil şəkli — `avatars/{uid}.jpg`, sonra `photoUrl` Firestore-da.
  Future<String> uploadProfilePhoto(XFile file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    final bytes = await file.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Telefon dəyişəndə `login_aliases` köçürülür.
  Future<void> updatePhoneKeyFromRawInput(String rawPhone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Giriş tapılmadı');
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw StateError('E-poçt tapılmadı');
    }
    final newKey = AuthService.loginPhoneKeyFromIdentifier(rawPhone);
    if (newKey == null) {
      throw StateError('Düzgün Azərbaycan mobil nömrəsi daxil edin');
    }
    final uid = user.uid;
    final snap = await _db.collection('users').doc(uid).get();
    final oldKey = (snap.data()?['phoneKey'] as String? ?? '').trim();
    if (oldKey == newKey) return;

    final batch = _db.batch();
    if (oldKey.isNotEmpty) {
      batch.delete(_db.collection('login_aliases').doc(oldKey));
    }
    batch.set(
      _db.collection('login_aliases').doc(newKey),
      {'email': email},
    );
    batch.update(_db.collection('users').doc(uid), {
      'phoneKey': newKey,
      'phone': newKey,
    });
    await batch.commit();
  }
}
