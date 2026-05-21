import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onFavoriteToggle,
  });

  final ListingModel listing;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSection(listing: listing, onFavoriteToggle: onFavoriteToggle),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkerRow(listing: listing),
                  const SizedBox(height: 8),
                  Text(
                    listing.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _BadgeRow(listing: listing),
                  const SizedBox(height: 10),
                  _BottomRow(listing: listing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.listing, this.onFavoriteToggle});
  final ListingModel listing;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: listing.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: '${ApiService.baseUrl}${listing.images.first}',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _ImagePlaceholder(category: listing.category),
                  errorWidget: (_, __, ___) => _ImagePlaceholder(category: listing.category),
                )
              : _ImagePlaceholder(category: listing.category),
        ),
        // Category badge
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${kCategoryIcons[listing.category] ?? '✨'} ${listing.category}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Favorite button
        if (onFavoriteToggle != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                child: Icon(
                  listing.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: listing.isFavorite ? Colors.red : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ),
        // Urgent badge
        if (listing.isUrgent)
          Positioned(
            bottom: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
              child: const Text('⚡ Təcili', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: kPrimary.withOpacity(0.08),
      child: Center(
        child: Text(kCategoryIcons[category] ?? '✨', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: kPrimary.withOpacity(0.1),
              backgroundImage: listing.workerPhoto.isNotEmpty
                  ? NetworkImage('${ApiService.baseUrl}${listing.workerPhoto}')
                  : null,
              child: listing.workerPhoto.isEmpty
                  ? Text(
                      listing.workerName.isNotEmpty ? listing.workerName[0].toUpperCase() : 'U',
                      style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            if (listing.workerIsOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            listing.workerName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              listing.workerRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              ' (${listing.workerRatingCount})',
              style: const TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (listing.homeService) _Badge(label: '🏠 Evə gəlir', color: Colors.blue.shade50, textColor: Colors.blue.shade700),
        if (listing.distanceKm != null)
          _Badge(
            label: '📍 ${listing.distanceKm! < 1 ? '${(listing.distanceKm! * 1000).toInt()} m' : '${listing.distanceKm!.toStringAsFixed(1)} km'}',
            color: Colors.green.shade50,
            textColor: Colors.green.shade700,
          ),
        _Badge(
          label: '🕐 ${listing.workHours}',
          color: Colors.grey.shade100,
          textColor: Colors.grey.shade700,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Qiymət', style: TextStyle(fontSize: 11, color: kTextSecondary)),
            Text(
              listing.priceRange,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary),
            ),
          ],
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: null, // Handled by onTap of the card
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary.withOpacity(0.1),
            foregroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
          ),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          label: const Text('Bax', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
