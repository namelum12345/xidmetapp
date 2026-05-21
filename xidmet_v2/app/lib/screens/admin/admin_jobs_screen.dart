import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  List<ListingModel> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final listings = await AdminService.instance.getListings();
      if (mounted) setState(() { _listings = listings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elanı sil'),
        content: const Text('Bu elanı silmək istəyirsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: kError),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.instance.deleteListing(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kError));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elanlar', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? const Center(child: Text('Elan tapılmadı', style: TextStyle(color: kTextSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _listings.length,
                    itemBuilder: (_, i) {
                      final l = _listings[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(kCategoryIcons[l.category] ?? '✨', style: const TextStyle(fontSize: 24)),
                          title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${l.category} • ${l.isActive ? 'Aktiv' : 'Deaktiv'}',
                            style: TextStyle(color: l.isActive ? kSuccess : kTextSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.priceRange, style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                              PopupMenuButton<String>(
                                onSelected: (v) { if (v == 'delete') _delete(l.id); },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: kError))),
                                ],
                              ),
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
