import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/listings_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  ListingModel? _listing;
  List<ReviewModel> _reviews = [];
  bool _loading = true;
  bool _reviewLoading = false;
  int _imageIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final listing = await ListingsService.instance.get(widget.listingId);
      final reviews = await ListingsService.instance.getReviews(widget.listingId);
      if (mounted) setState(() { _listing = listing; _reviews = reviews; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_listing == null) return;
    try {
      final isFav = await ListingsService.instance.toggleFavorite(_listing!.id);
      setState(() => _listing = ListingModel.fromJson({..._toMap(_listing!), 'is_favorite': isFav}));
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _startChat() async {
    final listing = _listing;
    if (listing == null) return;
    final me = AuthService.instance.user;
    if (me == null) return;
    if (me.id == listing.workerId) {
      _snack('Öz elanınıza mesaj göndərə bilməzsiniz');
      return;
    }
    try {
      final result = await ChatService.instance.sendMessage(
        text: 'Salam! "${listing.title}" elanınıza marağım var.',
        otherUserId: listing.workerId,
        listingId: listing.id,
      );
      if (mounted) context.push('/chat/${result['thread_id']}');
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _callWorker() async {
    final phone = _listing?.contactPhone ?? '';
    if (phone.isEmpty) {
      _snack('Telefon nömrəsi yoxdur');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Zəng edə bilmədi');
    }
  }

  Future<void> _showReviewDialog() async {
    double rating = 5;
    final commentCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rəy yaz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (r) => rating = r,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(hintText: 'Şərh (istəyə bağlı)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Göndər'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _reviewLoading = true);
      try {
        await ListingsService.instance.addReview(
          widget.listingId,
          rating: rating,
          comment: commentCtrl.text.trim(),
        );
        await _load();
      } catch (e) {
        _snack(e.toString());
      } finally {
        if (mounted) setState(() => _reviewLoading = false);
      }
    }
    commentCtrl.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Map<String, dynamic> _toMap(ListingModel l) => {
    'id': l.id, 'worker_id': l.workerId, 'title': l.title,
    'description': l.description, 'category': l.category,
    'images': l.images, 'min_price': l.minPrice, 'max_price': l.maxPrice,
    'address': l.address, 'lat': l.lat, 'lng': l.lng,
    'work_hours': l.workHours, 'is_urgent': l.isUrgent,
    'home_service': l.homeService, 'contact_phone': l.contactPhone,
    'is_active': l.isActive, 'view_count': l.viewCount,
    'created_at': l.createdAt, 'worker_name': l.workerName,
    'worker_photo': l.workerPhoto, 'worker_is_online': l.workerIsOnline,
    'worker_rating': l.workerRating, 'worker_rating_count': l.workerRatingCount,
    'is_favorite': l.isFavorite,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'Xəta'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Yenilə')),
          ],
        )),
      );
    }
    final listing = _listing!;
    final me = AuthService.instance.user;
    final isOwner = me?.id == listing.workerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: listing.images.isNotEmpty ? 260 : 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: listing.images.isNotEmpty
                  ? _ImageCarousel(images: listing.images, currentIndex: _imageIndex, onChanged: (i) => setState(() => _imageIndex = i))
                  : Container(
                      color: kPrimary.withOpacity(0.1),
                      child: Center(child: Text(kCategoryIcons[listing.category] ?? '✨', style: const TextStyle(fontSize: 72))),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(listing.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: listing.isFavorite ? Colors.red : Colors.white),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(listing.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      if (listing.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                          child: const Text('⚡ Təcili', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(listing.category, style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  // Worker card
                  _WorkerCard(listing: listing),
                  const SizedBox(height: 16),

                  // Price
                  _InfoCard(children: [
                    _InfoRow(icon: Icons.payments_outlined, label: 'Qiymət', value: listing.priceRange),
                    _InfoRow(icon: Icons.schedule_rounded, label: 'İş saatları', value: listing.workHours),
                    if (listing.address.isNotEmpty)
                      _InfoRow(icon: Icons.location_on_outlined, label: 'Ünvan', value: listing.address),
                    if (listing.homeService)
                      _InfoRow(icon: Icons.home_rounded, label: 'Evə gəlmə', value: 'Bəli'),
                  ]),
                  const SizedBox(height: 16),

                  // Description
                  if (listing.description.isNotEmpty) ...[
                    const Text('Haqqında', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(listing.description, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rəylər (${_reviews.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      if (!isOwner)
                        TextButton.icon(
                          onPressed: _reviewLoading ? null : _showReviewDialog,
                          icon: const Icon(Icons.rate_review_outlined, size: 16),
                          label: const Text('Rəy yaz'),
                        ),
                    ],
                  ),
                  if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('Hələ rəy yoxdur', style: TextStyle(color: kTextSecondary))),
                    )
                  else
                    ..._reviews.map((r) => _ReviewTile(review: r)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? _OwnerActions(listing: listing)
          : _UserActions(onChat: _startChat, onCall: _callWorker, contactPhone: listing.contactPhone),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.images, required this.currentIndex, required this.onChanged});
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onChanged,
          itemBuilder: (_, i) => Image.network(
            '${ApiService.baseUrl}${images[i]}',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.1)),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == currentIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == currentIndex ? kPrimary : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kPrimary.withOpacity(0.15),
                backgroundImage: listing.workerPhoto.isNotEmpty
                    ? NetworkImage('${ApiService.baseUrl}${listing.workerPhoto}')
                    : null,
                child: listing.workerPhoto.isEmpty
                    ? Text(
                        listing.workerName.isNotEmpty ? listing.workerName[0].toUpperCase() : 'U',
                        style: TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              if (listing.workerIsOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.workerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text('${listing.workerRating.toStringAsFixed(1)} (${listing.workerRatingCount} rəy)',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                  ],
                ),
                if (listing.workerIsOnline)
                  const Text('🟢 Online', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kPrimary.withOpacity(0.1),
                backgroundImage: review.reviewerPhoto.isNotEmpty ? NetworkImage('${ApiService.baseUrl}${review.reviewerPhoto}') : null,
                child: review.reviewerPhoto.isEmpty
                    ? Text(review.reviewerName.isNotEmpty ? review.reviewerName[0] : 'U', style: TextStyle(color: kPrimary, fontSize: 12))
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 13, color: i < review.rating ? Colors.amber : Colors.grey.shade300))),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({required this.onChat, required this.onCall, required this.contactPhone});
  final VoidCallback onChat;
  final VoidCallback onCall;
  final String contactPhone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: contactPhone.isNotEmpty ? onCall : null,
                icon: const Icon(Icons.call_rounded),
                label: const Text('Zəng et'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Mesaj göndər'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/listing/${listing.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Redaktə et'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
