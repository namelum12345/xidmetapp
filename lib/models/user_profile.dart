import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Firestore `users/{uid}` profile + helpers.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.surname,
    required this.email,
    required this.phoneKey,
    required this.role,
    this.location,
    this.createdAt,
    this.fcmToken,
    this.photoUrl,
    this.isBlocked = false,
  });

  final String uid;
  final String name;
  final String surname;
  final String email;
  final String phoneKey;

  /// Firestore string: user | worker | admin | superadmin
  final String role;
  final GeoPoint? location;
  final DateTime? createdAt;
  final String? fcmToken;
  /// Firebase Storage və ya şəbəkə URL (avatar).
  final String? photoUrl;
  final bool isBlocked;

  String get displayName => '$name $surname'.trim();

  UserRole get marketplaceRole {
    if (role == 'worker') return UserRole.worker;
    return UserRole.user;
  }

  bool get isAdmin => role == 'admin';

  bool get isSuperAdmin => role == 'superadmin' || role == 'super_admin';

  /// Admin panel və ya super panel üçün icazə (marketplace admin işçiləri).
  bool get canAccessAdminPanel => isAdmin || isSuperAdmin;

  static UserProfile fromMap(String uid, Map<String, dynamic> d) {
    final ts = d['createdAt'];
    return UserProfile(
      uid: uid,
      name: d['name'] as String? ?? '',
      surname: d['surname'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phoneKey:
          (d['phoneKey'] ?? d['phone']) as String? ?? '',
      role: d['role'] as String? ?? 'user',
      location: d['location'] as GeoPoint?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      fcmToken: d['fcmToken'] as String?,
      photoUrl: d['photoUrl'] as String?,
      isBlocked: d['isBlocked'] == true || d['banned'] == true,
    );
  }

  Map<String, dynamic> toCreateMap({
    required GeoPoint location,
    required DateTime createdAt,
  }) {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'phoneKey': phoneKey,
      'phone': phoneKey,
      'role': role,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
