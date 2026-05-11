/// Sub-administrator managed by superadmin.
enum SubAdminRole {
  moderator,
  support,
  fullAdmin,
}

extension SubAdminRoleLabel on SubAdminRole {
  String get labelAz => switch (this) {
        SubAdminRole.moderator => 'Moderator',
        SubAdminRole.support => 'Dəstək',
        SubAdminRole.fullAdmin => 'Tam admin',
      };
}

/// Fine-grained toggles (mirrored in UI).
class PermissionSet {
  PermissionSet({
    this.manageUsers = true,
    this.manageWorkers = true,
    this.manageJobs = true,
    this.accessChats = false,
    this.banUsers = false,
  });

  bool manageUsers;
  bool manageWorkers;
  bool manageJobs;
  bool accessChats;
  bool banUsers;

  PermissionSet copy() => PermissionSet(
        manageUsers: manageUsers,
        manageWorkers: manageWorkers,
        manageJobs: manageJobs,
        accessChats: accessChats,
        banUsers: banUsers,
      );
}

class SubAdminRecord {
  SubAdminRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String name;
  final String email;
  SubAdminRole role;
  PermissionSet permissions;
}

enum ComplaintTargetType {
  user,
  worker,
  job,
}

class ComplaintRecord {
  ComplaintRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.reporter,
    this.targetId,
    this.pending = true,
  });

  final String id;
  final ComplaintTargetType type;
  final String title;
  final String reporter;
  final String? targetId;
  bool pending;
}

enum AuditAction {
  deleteUser,
  banUser,
  editJob,
  createAdmin,
  deleteAdmin,
}

class AuditLogEntry {
  AuditLogEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.detail,
    required this.at,
  });

  final String id;
  final String actor;
  final AuditAction action;
  final String detail;
  final DateTime at;
}
