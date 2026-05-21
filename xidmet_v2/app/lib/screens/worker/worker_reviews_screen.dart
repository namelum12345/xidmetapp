import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/workers_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class WorkerReviewsScreen extends StatefulWidget {
  const WorkerReviewsScreen({super.key});

  @override
  State<WorkerReviewsScreen> createState() => _WorkerReviewsScreenState();
}

class _WorkerReviewsScreenState extends State<WorkerReviewsScreen> {
  List<ReviewModel> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = AuthService.instance.user?.id ?? '';
      final reviews = await WorkersService.instance.getReviews(uid);
      if (mounted) setState(() { _reviews = reviews; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rəylər'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border_rounded, size: 64, color: kTextSecondary),
                      SizedBox(height: 12),
                      Text('Hələ rəy yoxdur', style: TextStyle(color: kTextSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = _reviews[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (si) => Icon(
                                        si < r.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: kWarning,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('ID: ${r.reviewerId}', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                                ],
                              ),
                              if (r.comment?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Text(r.comment!, style: TextStyle(color: kTextSecondary, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
