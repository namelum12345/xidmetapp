import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, User, UserCredential;
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'user_service.dart';

/// Firebase Auth + Firestore user profile.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserProfile? _profile;
  List<String> _workerSkillIds = [];

  /// Eyni UID üçün paralel `_loadProfile` çağırışlarını birləşdirir (veb Firestore JS SDK
  /// emulyator + `getDoc` yarışında "INTERNAL ASSERTION ... ve:-1" verməsin).
  final Map<String, Future<void>> _profileLoadsInFlight = {};

  User? get firebaseUser => _auth.currentUser;

  UserProfile? get profile => _profile;

  List<String> get workerSkillIds => List.unmodifiable(_workerSkillIds);

  UserRole? get marketplaceRole => _profile?.marketplaceRole;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> init() async {
    _auth.authStateChanges().listen((u) async {
      if (u == null) {
        _profile = null;
        _workerSkillIds = [];
        notifyListeners();
        return;
      }
      await _loadProfile(u.uid);
    });
    final u = _auth.currentUser;
    if (u != null) {
      await _loadProfile(u.uid);
    }
  }

  GetOptions get _userDocGetOptions => kIsWeb
      ? const GetOptions(source: Source.server)
      : const GetOptions();

  Future<void> _loadProfile(String uid) {
    return _profileLoadsInFlight.putIfAbsent(uid, () => _loadProfileOnce(uid));
  }

  Future<void> _loadProfileOnce(String uid) async {
    try {
      _workerSkillIds = [];
      final doc =
          await _db.collection('users').doc(uid).get(_userDocGetOptions);
      if (doc.exists && doc.data() != null) {
        _profile = UserProfile.fromMap(uid, doc.data()!);
        if (_profile!.role == 'worker') {
          final wdoc =
              await _db.collection('workers').doc(uid).get(_userDocGetOptions);
          final skills = wdoc.data()?['skills'];
          if (skills is List) {
            _workerSkillIds = skills.map((e) => '$e').toList();
          }
        }
      } else {
        _profile = null;
      }
    } catch (_) {
      _profile = null;
      _workerSkillIds = [];
    } finally {
      _profileLoadsInFlight.remove(uid);
    }
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final u = firebaseUser;
    if (u != null) await _loadProfile(u.uid);
  }

  Future<void> updateLocation(GeoPoint location) async {
    if (firebaseUser == null) return;
    await UserService.instance.writeLocation(location);
    await refreshProfile();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String phoneKey,
    required UserRole role,
    required GeoPoint location,
    List<String> workerSkillIds = const [],
  }) async {
    final aliasRef = _db.collection('login_aliases').doc(phoneKey);
    final existingAlias = await aliasRef.get();
    if (existingAlias.exists) {
      throw FirebaseAuthException(
        code: 'phone-already-in-use',
        message: 'Bu telefon nömrəsi artıq qeydiyyatdan keçib',
      );
    }

    late UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }

    final uid = cred.user!.uid;
    final now = DateTime.now();

    final roleStr = switch (role) {
      UserRole.user => 'user',
      UserRole.worker => 'worker',
    };

    final profile = UserProfile(
      uid: uid,
      name: name.trim(),
      surname: surname.trim(),
      email: email.trim().toLowerCase(),
      phoneKey: phoneKey,
      role: roleStr,
      location: location,
      createdAt: now,
    );

    try {
      final batch = _db.batch();
      final userRef = _db.collection('users').doc(uid);
      batch.set(
        userRef,
        {
          ...profile.toCreateMap(location: location, createdAt: now),
          'id': uid,
        },
      );

      if (role == UserRole.worker) {
        final skills = workerSkillIds.isEmpty
            ? ['repair', 'electric', 'plumbing']
            : workerSkillIds;
        final dn = '${name.trim()} ${surname.trim()}'.trim();
        batch.set(_db.collection('workers').doc(uid), {
          'userId': uid,
          'displayName': dn.isEmpty ? 'İcraçı' : dn,
          'skills': skills,
          'rating': 0.0,
          'ratingCount': 0,
          'isAvailable': true,
          'availability': 'active',
          'bio': '',
        });
      }

      batch.set(aliasRef, {'email': email.trim().toLowerCase()});

      await batch.commit();
      await _loadProfile(uid);
    } catch (e) {
      try {
        await cred.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Normalizes phone input to `login_aliases` document id (e.g. `+994501234567`).
  static String? loginPhoneKeyFromIdentifier(String identifier) {
    var digits = identifier.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 12 && digits.startsWith('994')) {
      return '+$digits';
    }
    if (digits.length == 9) {
      return '+994$digits';
    }
    return null;
  }

  /// Login with email **or** phone (email resolved via [login_aliases]).
  ///
  /// Throws [FirebaseAuthException] on auth failures or missing Firestore profile after auth.
  Future<UserRole> signIn(String identifier, String password) async {
    final raw = identifier.trim();
    String email;
    if (raw.contains('@')) {
      email = raw.toLowerCase();
    } else {
      final phoneKey = loginPhoneKeyFromIdentifier(raw);
      if (phoneKey == null) {
        throw FirebaseAuthException(
          code: 'invalid-phone',
          message: 'Düzgün Azərbaycan mobil nömrəsi daxil edin',
        );
      }
      final aliasDoc =
          await _db.collection('login_aliases').doc(phoneKey).get();
      if (!aliasDoc.exists) {
        throw FirebaseAuthException(
          code: 'phone-account-not-found',
          message:
              'Bu nömrə ilə hesab tapılmadı. E-poçt ilə daxil olun və ya qeydiyyatdan keçin.',
        );
      }
      final resolved = aliasDoc.data()?['email'] as String? ?? '';
      if (resolved.isEmpty) {
        throw FirebaseAuthException(
          code: 'phone-email-missing',
          message: 'Bu nömrə üçün e-poçt təyin olunmayıb.',
        );
      }
      email = resolved.trim().toLowerCase();
    }

    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = _auth.currentUser!.uid;
    await _loadProfile(uid);

    if (_profile == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'missing-profile',
        message:
            'Profil yüklənmədi və ya hesab tamamlanmayıb. Şəbəkəni yoxlayın və ya yenidən qeydiyyatdan keçin.',
      );
    }
    if (_profile!.isBlocked) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-blocked',
        message: 'Hesab bloklanıb',
      );
    }

    if (_profile!.isSuperAdmin || _profile!.isAdmin) {
      return UserRole.user;
    }
    return _profile!.marketplaceRole;
  }

  bool get isFirebaseAdmin => _profile?.isAdmin ?? false;

  bool get isFirebaseSuperAdmin => _profile?.isSuperAdmin ?? false;

  bool get canAccessAdminPanel => _profile?.canAccessAdminPanel ?? false;

  Future<void> signOut() async {
    await _auth.signOut();
    _profile = null;
    _workerSkillIds = [];
    notifyListeners();
  }

  /// Legacy helper — phone normalization (registration).
  static String normalizePhoneKey(String dialCode, String nineDigits) {
    return '$dialCode$nineDigits'.replaceAll(RegExp(r'\s'), '');
  }

  /// Clears auth — testing hook (optional).
  Future<void> clearAccountsForTesting() async {
    await signOut();
  }
}
