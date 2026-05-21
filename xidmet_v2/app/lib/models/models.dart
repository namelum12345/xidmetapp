class UserModel {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String? phone;
  final String role;
  final String? photoUrl;
  final double lat;
  final double lng;
  final String address;
  final bool isBlocked;
  final bool isOnline;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.phone,
    required this.role,
    this.photoUrl,
    this.lat = 40.4093,
    this.lng = 49.8671,
    this.address = '',
    this.isBlocked = false,
    this.isOnline = false,
    this.createdAt = '',
  });

  String get displayName => '$name $surname'.trim();
  bool get isWorker => role == 'worker';
  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isSuperAdmin => role == 'superadmin';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        surname: j['surname'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] as String?,
        role: j['role'] ?? 'user',
        photoUrl: (j['photo_url'] as String?)?.isNotEmpty == true ? j['photo_url'] as String : null,
        lat: (j['lat'] as num?)?.toDouble() ?? 40.4093,
        lng: (j['lng'] as num?)?.toDouble() ?? 49.8671,
        address: j['address'] ?? '',
        isBlocked: j['is_blocked'] ?? false,
        isOnline: j['is_online'] ?? false,
        createdAt: j['created_at'] ?? '',
      );
}

class WorkerModel {
  final String id;
  final String name;
  final String surname;
  final String? photoUrl;
  final double lat;
  final double lng;
  final bool isOnline;
  final String? bio;
  final List<String> categories;
  final int experienceYears;
  final double minPrice;
  final double? hourlyRate;
  final String workHours;
  final bool isUrgentAvailable;
  final bool homeService;
  final String? contactPhone;
  final String? availability;
  final double rating;
  final int ratingCount;
  final int completedCount;

  const WorkerModel({
    required this.id,
    this.name = '',
    this.surname = '',
    this.photoUrl,
    this.lat = 40.4093,
    this.lng = 49.8671,
    this.isOnline = false,
    this.bio,
    this.categories = const [],
    this.experienceYears = 0,
    this.minPrice = 0,
    this.hourlyRate,
    this.workHours = '09:00-18:00',
    this.isUrgentAvailable = false,
    this.homeService = false,
    this.contactPhone,
    this.availability,
    this.rating = 0,
    this.ratingCount = 0,
    this.completedCount = 0,
  });

  String get displayName => '$name $surname'.trim();

  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        surname: j['surname'] ?? '',
        photoUrl: (j['photo_url'] as String?)?.isNotEmpty == true ? j['photo_url'] as String : null,
        lat: (j['lat'] as num?)?.toDouble() ?? 40.4093,
        lng: (j['lng'] as num?)?.toDouble() ?? 49.8671,
        isOnline: j['is_online'] ?? false,
        bio: (j['bio'] as String?)?.isNotEmpty == true ? j['bio'] as String : null,
        categories: (j['categories'] as List?)?.map((s) => s.toString()).toList() ?? [],
        experienceYears: j['experience_years'] ?? 0,
        minPrice: (j['min_price'] as num?)?.toDouble() ?? 0,
        hourlyRate: (j['hourly_rate'] as num?)?.toDouble(),
        workHours: j['work_hours'] ?? '09:00-18:00',
        isUrgentAvailable: j['is_urgent_available'] ?? false,
        homeService: j['home_service'] ?? false,
        contactPhone: j['contact_phone'] as String?,
        availability: j['availability'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: j['rating_count'] ?? 0,
        completedCount: j['completed_count'] ?? 0,
      );
}

class ListingModel {
  final String id;
  final String workerId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final double minPrice;
  final double maxPrice;
  final String address;
  final double lat;
  final double lng;
  final String workHours;
  final bool isUrgent;
  final bool homeService;
  final String contactPhone;
  final bool isActive;
  final int viewCount;
  final String createdAt;
  // Joined worker info
  final String workerName;
  final String workerPhoto;
  final bool workerIsOnline;
  final double workerRating;
  final int workerRatingCount;
  final bool isFavorite;
  final double? distanceKm;

  const ListingModel({
    required this.id,
    required this.workerId,
    required this.title,
    this.description = '',
    required this.category,
    this.images = const [],
    this.minPrice = 0,
    this.maxPrice = 0,
    this.address = '',
    this.lat = 40.4093,
    this.lng = 49.8671,
    this.workHours = '09:00-18:00',
    this.isUrgent = false,
    this.homeService = false,
    this.contactPhone = '',
    this.isActive = true,
    this.viewCount = 0,
    this.createdAt = '',
    this.workerName = '',
    this.workerPhoto = '',
    this.workerIsOnline = false,
    this.workerRating = 0,
    this.workerRatingCount = 0,
    this.isFavorite = false,
    this.distanceKm,
  });

  String get priceRange {
    if (minPrice == 0 && maxPrice == 0) return 'Razılaşma ilə';
    if (maxPrice == 0 || minPrice == maxPrice) return '${minPrice.toInt()} ₼';
    return '${minPrice.toInt()}-${maxPrice.toInt()} ₼';
  }

  factory ListingModel.fromJson(Map<String, dynamic> j) => ListingModel(
        id: j['id'] ?? '',
        workerId: j['worker_id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        category: j['category'] ?? '',
        images: (j['images'] as List?)?.map((s) => s.toString()).toList() ?? [],
        minPrice: (j['min_price'] as num?)?.toDouble() ?? 0,
        maxPrice: (j['max_price'] as num?)?.toDouble() ?? 0,
        address: j['address'] ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 40.4093,
        lng: (j['lng'] as num?)?.toDouble() ?? 49.8671,
        workHours: j['work_hours'] ?? '09:00-18:00',
        isUrgent: j['is_urgent'] ?? false,
        homeService: j['home_service'] ?? false,
        contactPhone: j['contact_phone'] ?? '',
        isActive: j['is_active'] ?? true,
        viewCount: j['view_count'] ?? 0,
        createdAt: j['created_at'] ?? '',
        workerName: j['worker_name'] ?? '',
        workerPhoto: j['worker_photo'] ?? '',
        workerIsOnline: j['worker_is_online'] ?? false,
        workerRating: (j['worker_rating'] as num?)?.toDouble() ?? 0,
        workerRatingCount: j['worker_rating_count'] ?? 0,
        isFavorite: j['is_favorite'] ?? false,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
      );
}

class ReviewModel {
  final String id;
  final String? workerId;
  final String? listingId;
  final String? reviewerId;
  final double rating;
  final String? comment;
  final String createdAt;
  final String reviewerName;
  final String reviewerPhoto;

  const ReviewModel({
    required this.id,
    this.workerId,
    this.listingId,
    this.reviewerId,
    this.rating = 0,
    this.comment,
    this.createdAt = '',
    this.reviewerName = '',
    this.reviewerPhoto = '',
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: j['id'] ?? '',
        workerId: j['worker_id'] as String?,
        listingId: j['listing_id'] as String?,
        reviewerId: j['reviewer_id'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        comment: j['comment'] as String?,
        createdAt: j['created_at'] ?? '',
        reviewerName: j['reviewer_name'] ?? '',
        reviewerPhoto: j['reviewer_photo'] ?? '',
      );
}

class ChatThreadModel {
  final String id;
  final String? listingId;
  final String ownerId;
  final String workerId;
  final String? lastMessage;
  final int unread;
  final String updatedAt;
  final String otherName;
  final String otherPhoto;

  const ChatThreadModel({
    required this.id,
    this.listingId,
    required this.ownerId,
    required this.workerId,
    this.lastMessage,
    this.unread = 0,
    this.updatedAt = '',
    this.otherName = '',
    this.otherPhoto = '',
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> j) => ChatThreadModel(
        id: j['id'] ?? '',
        listingId: j['listing_id'] as String?,
        ownerId: j['owner_id'] ?? '',
        workerId: j['worker_id'] ?? '',
        lastMessage: j['last_message'] as String?,
        unread: j['unread'] ?? 0,
        updatedAt: j['updated_at'] ?? '',
        otherName: j['other_name'] ?? '',
        otherPhoto: j['other_photo'] ?? '',
      );
}

class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final String sentAt;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'] ?? '',
        threadId: j['thread_id'] ?? '',
        senderId: j['sender_id'] ?? '',
        text: j['text'] ?? '',
        sentAt: j['sent_at'] ?? '',
      );
}

class JobModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final double budgetMin;
  final double budgetMax;
  final String address;
  final double lat;
  final double lng;
  final bool isUrgent;
  final bool isActive;
  final String status;
  final int applicationsCount;
  final bool hasApplied;
  final String createdAt;
  final String updatedAt;
  final String userName;
  final String userPhoto;
  final bool userIsOnline;
  final double? distanceKm;

  const JobModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.category,
    this.budgetMin = 0,
    this.budgetMax = 0,
    this.address = '',
    this.lat = 40.4093,
    this.lng = 49.8671,
    this.isUrgent = false,
    this.isActive = true,
    this.status = 'open',
    this.applicationsCount = 0,
    this.hasApplied = false,
    this.createdAt = '',
    this.updatedAt = '',
    this.userName = '',
    this.userPhoto = '',
    this.userIsOnline = false,
    this.distanceKm,
  });

  String get budgetRange {
    if (budgetMin == 0 && budgetMax == 0) return 'Razılaşma ilə';
    if (budgetMax == 0 || budgetMin == budgetMax) return '${budgetMin.toInt()} ₼';
    return '${budgetMin.toInt()}-${budgetMax.toInt()} ₼';
  }

  factory JobModel.fromJson(Map<String, dynamic> j) => JobModel(
        id: j['id'] ?? '',
        userId: j['user_id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        category: j['category'] ?? '',
        budgetMin: (j['budget_min'] as num?)?.toDouble() ?? 0,
        budgetMax: (j['budget_max'] as num?)?.toDouble() ?? 0,
        address: j['address'] ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 40.4093,
        lng: (j['lng'] as num?)?.toDouble() ?? 49.8671,
        isUrgent: j['is_urgent'] ?? false,
        isActive: j['is_active'] ?? true,
        status: j['status'] ?? 'open',
        applicationsCount: j['applications_count'] ?? 0,
        hasApplied: j['has_applied'] ?? false,
        createdAt: j['created_at'] ?? '',
        updatedAt: j['updated_at'] ?? '',
        userName: j['user_name'] ?? '',
        userPhoto: j['user_photo'] ?? '',
        userIsOnline: j['user_is_online'] ?? false,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
      );
}

class JobApplicationModel {
  final String id;
  final String jobId;
  final String workerId;
  final String coverLetter;
  final String status;
  final String createdAt;

  const JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.coverLetter = '',
    this.status = 'pending',
    this.createdAt = '',
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> j) => JobApplicationModel(
        id: j['id'] ?? '',
        jobId: j['job_id'] ?? '',
        workerId: j['worker_id'] ?? '',
        coverLetter: j['cover_letter'] ?? '',
        status: j['status'] ?? 'pending',
        createdAt: j['created_at'] ?? '',
      );
}

const kCategories = [
  'Elektrik',
  'Santexnika',
  'Təmir',
  'Təmizlik',
  'Köçürmə',
  'Rəngkarlıq',
  'Bağça',
  'İT Xidmət',
  'Digər',
];

const kCategoryIcons = {
  'Elektrik': '⚡',
  'Santexnika': '🔧',
  'Təmir': '🏠',
  'Təmizlik': '🧹',
  'Köçürmə': '📦',
  'Rəngkarlıq': '🎨',
  'Bağça': '🌿',
  'İT Xidmət': '💻',
  'Digər': '✨',
};
