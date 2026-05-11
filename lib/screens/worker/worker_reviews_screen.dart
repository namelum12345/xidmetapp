import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/worker_review.dart';
import '../../services/auth_service.dart';
import '../../services/worker_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/worker/review_card.dart';

class WorkerReviewsScreen extends StatelessWidget {
  const WorkerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Giriş tapılmadı')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rəylər'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: WorkerProfileService.instance.reviewsStreamFor(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Hələ rəy yoxdur',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = WorkerReview.fromDoc(docs[i]);
              return ReviewCard(
                reviewerName: r.reviewerName.isEmpty ? 'İstifadəçi' : r.reviewerName,
                rating: r.rating.clamp(1, 5),
                comment: r.comment,
                jobTitle: r.jobTitle,
                date: r.createdAt,
              );
            },
          );
        },
      ),
    );
  }
}
