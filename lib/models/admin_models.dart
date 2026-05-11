/// Mock rows for admin lists (replace with API).
class AdminUserRecord {
  AdminUserRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.roleLabel,
    this.banned = false,
  });

  final String id;
  final String name;
  final String phone;
  final String roleLabel;
  bool banned;
}

class AdminWorkerRecord {
  AdminWorkerRecord({
    required this.id,
    required this.name,
    required this.skills,
    required this.rating,
    this.approved = true,
    this.disabled = false,
  });

  final String id;
  final String name;
  final List<String> skills;
  double rating;
  bool approved;
  bool disabled;
}

enum AdminJobLifecycle {
  active,
  completed,
}
