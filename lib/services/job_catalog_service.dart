import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/job_category.dart';
import '../models/job_listing.dart';
import '../utils/geo_utils.dart';
import '../utils/job_worker_matching.dart';
import 'auth_service.dart';

/// Firestore-backed jobs + matching (5 km, skills).
class JobCatalogService extends ChangeNotifier {
  JobCatalogService._();
  static final JobCatalogService instance = JobCatalogService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final Map<String, Map<String, dynamic>> _jobData = {};
  List<String> _order = [];

  /// Birinci Firestore snapshot-u gəldikdən sonra `true` (boş siyahı da ola bilər).
  bool _catalogSynced = false;
  bool _seedTried = false;

  bool get hasJobsCatalogSynced => _catalogSynced;

  void startListening() {
    _sub?.cancel();
    _catalogSynced = false;
    notifyListeners();
    if (!_seedTried) {
      _seedTried = true;
      ensureTestJobsIfEmpty();
    }
    _sub = _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        debugPrint('[jobs] snapshot size: ${snap.docs.length}');
        _catalogSynced = true;
        _jobData
          ..clear()
          ..addEntries(
            snap.docs.map((d) => MapEntry(d.id, d.data())),
          );
        _order = snap.docs.map((d) => d.id).toList();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[jobs] stream error: $e');
        _catalogSynced = true;
        _jobData.clear();
        _order = [];
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _catalogSynced = false;
  }

  /// Seed 3 test jobs for development if collection is empty.
  Future<void> ensureTestJobsIfEmpty() async {
    try {
      final first = await _db.collection('jobs').limit(1).get();
      if (first.docs.isNotEmpty) return;
      final uid = AuthService.instance.firebaseUser?.uid;
      if (uid == null) return;
      final p = AuthService.instance.profile;
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();
      final jobs = <Map<String, dynamic>>[
        {
          'title': 'Kondisioner təmiri',
          'description': 'Soyutmur, baxış və təmir lazımdır.',
          'category': JobCategoryId.repair.name,
          'location': const GeoPoint(40.4093, 49.8671),
          'locationLabel': 'Bakı mərkəz',
          'priceAzn': 50,
        },
        {
          'title': 'Ev təmizliyi',
          'description': '2 otaqlı mənzil üçün ümumi təmizlik.',
          'category': JobCategoryId.cleaning.name,
          'location': const GeoPoint(40.3947, 49.8467),
          'locationLabel': 'Yasamal',
          'priceAzn': 35,
        },
        {
          'title': 'Elektrik rozetka dəyişimi',
          'description': '2 rozetka işləmədiyi üçün dəyişilməlidir.',
          'category': JobCategoryId.electric.name,
          'location': const GeoPoint(40.3777, 49.8920),
          'locationLabel': 'Nərimanov',
          'priceAzn': 25,
        },
      ];
      for (final j in jobs) {
        final ref = _db.collection('jobs').doc();
        batch.set(ref, {
          ...j,
          'createdBy': uid,
          'status': 'active',
          'createdAt': now,
          'posterName': p?.displayName.isNotEmpty == true
              ? p!.displayName
              : 'İstifadəçi',
          'posterHint': p?.email ?? '',
          'matchedWorkerIds': const <String>[],
        });
      }
      await batch.commit();
      debugPrint('[jobs] seeded 3 test jobs');
    } catch (e) {
      debugPrint('[jobs] seed error: $e');
    }
  }

  List<JobListing> allJobs() {
    return _order
        .map(
          (id) => _toListing(
            id,
            _jobData[id]!,
            forWorker: false,
          ),
        )
        .toList();
  }

  /// Elanı yaradan istifadəçi üçün.
  List<JobListing> jobsCreatedBy(String uid) {
    return allJobs().where((j) => j.createdBy == uid).toList();
  }

  /// İcraçı seçilmiş və ya təklif göndərilmiş elanlar (collectionGroup).
  Stream<Set<String>> jobIdsWithWorkerApplicationStream(String workerUid) {
    return _db
        .collectionGroup('applications')
        .where('workerId', isEqualTo: workerUid)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => d.reference.parent.parent?.id)
              .whereType<String>()
              .toSet(),
        );
  }

  List<JobListing> jobsSortedForWorker() {
    return _order
        .map(
          (id) => _toListing(
            id,
            _jobData[id]!,
            forWorker: true,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byScore = b.matchScore.compareTo(a.matchScore);
        if (byScore != 0) return byScore;
        if (a.matchesWorkerSkills != b.matchesWorkerSkills) {
          return a.matchesWorkerSkills ? -1 : 1;
        }
        return a.distanceKm.compareTo(b.distanceKm);
      });
  }

  JobListing? getById(String id) {
    final d = _jobData[id];
    if (d == null) return null;
    final isWorker = AuthService.instance.profile?.role == 'worker';
    return _toListing(
      id,
      d,
      forWorker: isWorker,
    );
  }

  /// İcraçı üçün tamamlanmış elanlardan qazanc və say (məbləğ `priceAzn`-dən).
  ({
    int completedCount,
    double totalEarningsAzn,
    double thisMonthEarningsAzn,
    int thisMonthCompleted,
  }) workerCompletedStats(String workerId) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    var completedCount = 0;
    var totalEarningsAzn = 0.0;
    var thisMonthEarningsAzn = 0.0;
    var thisMonthCompleted = 0;

    for (final id in _order) {
      final d = _jobData[id];
      if (d == null) continue;
      if ((d['status'] as String?) != 'completed') continue;
      if ((d['selectedWorkerId'] as String?) != workerId) continue;
      completedCount++;
      final price = (d['priceAzn'] as num?)?.toDouble() ?? 0.0;
      totalEarningsAzn += price;
      final completedAt = (d['completedAt'] as Timestamp?)?.toDate();
      if (completedAt != null &&
          !completedAt.isBefore(monthStart) &&
          completedAt.isBefore(nextMonth)) {
        thisMonthEarningsAzn += price;
        thisMonthCompleted++;
      }
    }
    return (
      completedCount: completedCount,
      totalEarningsAzn: totalEarningsAzn,
      thisMonthEarningsAzn: thisMonthEarningsAzn,
      thisMonthCompleted: thisMonthCompleted,
    );
  }

  Future<JobListing?> fetchJobById(String id) async {
    if (_jobData.containsKey(id)) {
      return getById(id);
    }
    final doc = await _db.collection('jobs').doc(id).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    final isWorker = AuthService.instance.profile?.role == 'worker';
    return _toListing(
      id,
      d,
      forWorker: isWorker,
    );
  }

  String _formatPosted(DateTime? t) {
    if (t == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inHours < 1) return '${diff.inMinutes} dəq əvvəl';
    if (now.day == t.day) {
      return DateFormat('HH:mm').format(t);
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE', 'az').format(t);
    }
    return DateFormat('d MMM', 'az').format(t);
  }

  String _short(String full) {
    final t = full.trim();
    if (t.length <= 100) return t;
    return '${t.substring(0, 97)}…';
  }

  JobCategoryId _parseCategory(String? s) {
    for (final c in JobCategoryId.values) {
      if (c.name == s) return c;
    }
    return JobCategoryId.cleaning;
  }

  JobListing _toListing(
    String id,
    Map<String, dynamic> d, {
    required bool forWorker,
  }) {
    final cat = _parseCategory(d['category'] as String?);
    final jobLoc = d['location'] as GeoPoint?;
    final created = (d['createdAt'] as Timestamp?)?.toDate();

    final viewerLoc = AuthService.instance.profile?.location;
    double dist = 0;
    var match = false;
    var score = 0.0;
    var badge = false;
    const workerRadiusKm = 5.0;

    if (forWorker) {
      final skills = AuthService.instance.workerSkillIds;
      match = skills.contains(cat.name);
      final hasJL = jobLoc != null;
      final hasVL = viewerLoc != null;
      if (jobLoc != null && viewerLoc != null) {
        dist = distanceKmBetween(viewerLoc, jobLoc);
      }
      score = JobWorkerMatching.jobFeedScore(
        skillMatch: match,
        distanceKm: dist,
        radiusKm: workerRadiusKm,
        hasViewerLocation: hasVL,
        hasJobLocation: hasJL,
      );
      badge = JobWorkerMatching.recommendBadge(
        skillMatch: match,
        distanceKm: dist,
        radiusKm: workerRadiusKm,
        hasViewerLocation: hasVL,
        hasJobLocation: hasJL,
      );
    }

    return JobListing(
      id: id,
      title: d['title'] as String? ?? '',
      shortDescription: _short(d['description'] as String? ?? ''),
      fullDescription: d['description'] as String? ?? '',
      categoryId: cat,
      priceAzn: (d['priceAzn'] as num?)?.toDouble(),
      distanceKm: dist,
      postedLabel: _formatPosted(created),
      locationLabel: d['locationLabel'] as String? ?? '',
      posterName: d['posterName'] as String? ?? '',
      posterHint: d['posterHint'] as String? ?? '',
      matchesWorkerSkills: match,
      matchScore: score,
      recommendForWorker: badge,
      createdBy: d['createdBy'] as String?,
      status: d['status'] as String? ?? 'active',
      selectedWorkerId: d['selectedWorkerId'] as String?,
      userRating: (d['userRating'] as num?)?.toInt(),
    );
  }

  /// Yaxınlıq (`radiusKm`) + işçinin bacarığında `category.name` olan aktiv işçilər.
  Future<List<String>> _findMatchedWorkers(
    GeoPoint jobLoc,
    JobCategoryId category,
    double radiusKm,
  ) async {
    final snap =
        await _db.collection('workers').where('isAvailable', isEqualTo: true).get();

    final scored = <({String id, double score})>[];
    for (final d in snap.docs) {
      final data = d.data();
      final skills = List<String>.from(data['skills'] ?? []);
      if (!skills.contains(category.name)) continue;

      final uid = d.id;
      final udoc = await _db.collection('users').doc(uid).get();
      final loc = udoc.data()?['location'] as GeoPoint?;
      if (loc == null) continue;

      final dist = distanceKmBetween(jobLoc, loc);
      if (dist > radiusKm) continue;

      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final score = JobWorkerMatching.notifyListScore(
        distanceKm: dist,
        radiusKm: radiusKm,
        workerRatingOutOf5: rating,
      );
      scored.add((id: uid, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.id).toList();
  }

  Future<String> createJob({
    required String title,
    required String description,
    required JobCategoryId category,
    required double? priceAzn,
    required GeoPoint location,
    required String locationLabel,
    double matchRadiusKm = 5,
  }) async {
    final uid = AuthService.instance.firebaseUser!.uid;
    final profile = AuthService.instance.profile!;

    final ref = _db.collection('jobs').doc();
    final id = ref.id;

    final matched = await _findMatchedWorkers(
      location,
      category,
      matchRadiusKm,
    );

    await ref.set({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.name,
      'createdBy': uid,
      'location': location,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'locationLabel': locationLabel.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'priceAzn': priceAzn,
      'posterName': profile.displayName.isEmpty ? 'İstifadəçi' : profile.displayName,
      'posterHint': profile.email,
      'matchedWorkerIds': matched,
    });

    return id;
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  Stream<List<Map<String, dynamic>>> applicationsStream(String jobId) {
    return _db
        .collection('jobs')
        .doc(jobId)
        .collection('applications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final m = Map<String, dynamic>.from(d.data());
            m['id'] = d.id;
            return m;
          }).toList(),
        );
  }

  Future<void> selectWorker(String jobId, String workerId) async {
    final batch = _db.batch();
    final jobRef = _db.collection('jobs').doc(jobId);
    batch.update(jobRef, {'selectedWorkerId': workerId});

    final apps =
        await _db.collection('jobs').doc(jobId).collection('applications').get();
    for (final d in apps.docs) {
      batch.update(d.reference, {
        'status': d.id == workerId ? 'accepted' : 'rejected',
      });
    }
    await batch.commit();
  }

  Future<void> completeJobWithRating({
    required String jobId,
    required int rating,
    String? reviewComment,
  }) async {
    final uid = AuthService.instance.firebaseUser!.uid;
    final jobRef = _db.collection('jobs').doc(jobId);

    await _db.runTransaction((tx) async {
      final jobSnap = await tx.get(jobRef);
      if (!jobSnap.exists) return;
      final data = jobSnap.data()!;
      if (data['createdBy'] != uid) {
        throw StateError('Yalnız elan sahibi bağlaya bilər');
      }
      if ((data['status'] as String?) == 'completed') {
        throw StateError('Elan artıq tamamlanıb');
      }
      final workerId = data['selectedWorkerId'] as String?;
      if (workerId == null || workerId.isEmpty) {
        throw StateError('İcraçı seçilməyib');
      }

      tx.update(jobRef, {
        'status': 'completed',
        'userRating': rating,
        'completedAt': FieldValue.serverTimestamp(),
      });

      final wRef = _db.collection('workers').doc(workerId);
      final wSnap = await tx.get(wRef);
      final wd = wSnap.data() ?? {};
      final rc = (wd['ratingCount'] as num?)?.toInt() ?? 0;
      final r = (wd['rating'] as num?)?.toDouble() ?? 0.0;
      final newCount = rc + 1;
      final newRating = (r * rc + rating) / newCount;
      tx.update(wRef, {
        'rating': newRating,
        'ratingCount': newCount,
      });

      final poster = AuthService.instance.profile;
      final reviewerName = poster?.displayName.isNotEmpty == true
          ? poster!.displayName
          : 'İstifadəçi';
      final title = data['title'] as String? ?? '';
      final comment = reviewComment?.trim() ?? '';
      if (comment.length > 2000) {
        throw StateError('Rəy çox uzundur (maks. 2000 simvol)');
      }

      final reviewRef =
          _db.collection('workers').doc(workerId).collection('reviews').doc(jobId);
      tx.set(reviewRef, {
        'jobId': jobId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'jobTitle': title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
