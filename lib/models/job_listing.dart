import 'job_category.dart';

/// Marketplace job (Firestore + UI).
class JobListing {
  const JobListing({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.categoryId,
    required this.priceAzn,
    required this.distanceKm,
    required this.postedLabel,
    required this.locationLabel,
    required this.posterName,
    required this.posterHint,
    this.matchesWorkerSkills = false,
    this.matchScore = 0,
    this.recommendForWorker = false,
    this.createdBy,
    this.status = 'active',
    this.selectedWorkerId,
    this.userRating,
  });

  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final JobCategoryId categoryId;
  final double? priceAzn;
  final double distanceKm;
  final String postedLabel;
  final String locationLabel;
  final String posterName;
  final String posterHint;
  final bool matchesWorkerSkills;

  /// İşçi üçün uyğunluq ballı (0–1 tipli normallaşdırılmış).
  final double matchScore;

  /// «Sənə uyğun» nişanı (bacarıq + radius içində məsafə).
  final bool recommendForWorker;

  final String? createdBy;
  final String status;
  final String? selectedWorkerId;
  final int? userRating;

  JobCategoryId get category => categoryId;
}
