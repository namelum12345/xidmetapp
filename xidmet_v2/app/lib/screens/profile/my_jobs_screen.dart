import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/listings_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_card.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<ListingModel> _myListings = [];
  List<ListingModel> _favorites = [];
  bool _loadingMy = true;
  bool _loadingFav = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMy();
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadMy() async {
    setState(() => _loadingMy = true);
    try {
      final listings = await ListingsService.instance.getMyListings();
      if (mounted) setState(() { _myListings = listings; _loadingMy = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFav = true);
    try {
      final favs = await ListingsService.instance.getFavorites();
      if (mounted) setState(() { _favorites = favs; _loadingFav = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = AuthService.instance.user?.isWorker ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elanlar'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Elanlarım'), Tab(text: 'Seçilmişlər')],
        ),
        actions: [
          if (isWorker)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push('/listing/create'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ListView(
            listings: _myListings,
            loading: _loadingMy,
            onRefresh: _loadMy,
            onTap: (l) => context.push('/listing/${l.id}'),
            emptyText: isWorker ? 'Hələ elan yerləşdirməmisiniz' : 'Hələ elan yoxdur',
          ),
          _ListView(
            listings: _favorites,
            loading: _loadingFav,
            onRefresh: _loadFavorites,
            onTap: (l) => context.push('/listing/${l.id}'),
            emptyText: 'Seçilmiş elan yoxdur',
          ),
        ],
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.listings, required this.loading, required this.onRefresh, required this.onTap, required this.emptyText});
  final List<ListingModel> listings;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(ListingModel) onTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (listings.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: kTextSecondary)));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => ListingCard(listing: listings[i], onTap: () => onTap(listings[i])),
      ),
    );
  }
}
