import 'job_category.dart';

/// İcraçı bacarıq seçimi (Firestore `workers.skills` massivində saxlanılan id-lər).
abstract final class WorkerSkillCatalog {
  static const List<({String id, String labelAz})> all = [
    (id: 'electric', labelAz: 'Elektrik'),
    (id: 'plumbing', labelAz: 'Santexnik'),
    (id: 'aircon', labelAz: 'Kondisioner'),
    (id: 'cleaning', labelAz: 'Təmizlik'),
    (id: 'tv_repair', labelAz: 'TV təmiri'),
    (id: 'garden', labelAz: 'Bağ işi'),
    (id: 'repair', labelAz: 'Təmir'),
    (id: 'delivery', labelAz: 'Çatdırılma'),
    (id: 'beauty', labelAz: 'Gözəllik'),
    (id: 'moving', labelAz: 'Daşıma'),
  ];

  static String labelForId(String id) {
    for (final e in all) {
      if (e.id == id) return e.labelAz;
    }
    for (final c in JobCategoryId.values) {
      if (c.name == id) return c.labelAz;
    }
    return id;
  }
}
