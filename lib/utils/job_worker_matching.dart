import 'dart:math' as math;

/// Elan ↔ işçi uyğunluğu üçün çəki sistemi (0–1 məntiqi normallaşdırma).
///
/// **İşçiyə bildiriş** siyahısı: bacarıq artıq süzgəcdən keçib → `skillMatch = true`.
/// **İşçi lentində** elan kartları: `rating` əsasən məsafə+bacarıq (elan tərəfində reytinq yoxdur).
abstract final class JobWorkerMatching {
  /// Elan yaradılanda yaxın işçilərin sıralaması (FCM üçün).
  static double notifyListScore({
    required double distanceKm,
    required double radiusKm,
    required double workerRatingOutOf5,
    double distanceWeight = 0.35,
    double ratingWeight = 0.35,
    double skillWeight = 0.30,
  }) {
    final distNorm =
        1.0 - (distanceKm / math.max(radiusKm, 0.001)).clamp(0.0, 1.0);
    final ratingNorm =
        (workerRatingOutOf5 / 5.0).clamp(0.0, 1.0);
    const skillNorm = 1.0;
    return distanceWeight * distNorm +
        ratingWeight * ratingNorm +
        skillWeight * skillNorm;
  }

  /// İşçi marketplace lentində elan kartları üçün (reytinq çəkisi elanda yoxdur → 0).
  static double jobFeedScore({
    required bool skillMatch,
    required double distanceKm,
    required double radiusKm,
    required bool hasViewerLocation,
    required bool hasJobLocation,
    double distanceWeight = 0.45,
    double skillWeight = 0.55,
  }) {
    final skillNorm = skillMatch ? 1.0 : 0.0;
    if (!hasViewerLocation || !hasJobLocation || distanceKm <= 0) {
      return skillWeight * skillNorm;
    }
    final distNorm =
        1.0 - (distanceKm / math.max(radiusKm, 0.001)).clamp(0.0, 1.0);
    return distanceWeight * distNorm + skillWeight * skillNorm;
  }

  /// «Sənə uyğun» nişanı: bacarıq + 5 km içində real məsafə.
  static bool recommendBadge({
    required bool skillMatch,
    required double distanceKm,
    required double radiusKm,
    required bool hasViewerLocation,
    required bool hasJobLocation,
  }) {
    if (!skillMatch || !hasViewerLocation || !hasJobLocation) return false;
    return distanceKm <= radiusKm;
  }
}
