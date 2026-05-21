import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/listings_service.dart';
import '../../theme/app_theme.dart';

class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen> {
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
      final listings = await ListingsService.instance.getMyListings();
      if (mounted) setState(() { _listings = listings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _listings.fold<double>(0, (sum, l) => sum + l.viewCount);
    final active = _listings.where((l) => l.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Elanlar', value: _listings.length.toString(), color: kPrimary, icon: Icons.list_alt_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Aktiv', value: active.toString(), color: kSuccess, icon: Icons.check_circle_outline_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Görüntülənmə', value: total.toInt().toString(), color: Colors.orange, icon: Icons.visibility_outlined)),
                  ],
                ),
                const SizedBox(height: 20),
                if (_listings.isEmpty)
                  const Center(child: Text('Hələ elan yoxdur', style: TextStyle(color: kTextSecondary)))
                else
                  ..._listings.map((l) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Text(kCategoryIcons[l.category] ?? '✨', style: const TextStyle(fontSize: 24)),
                          title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l.category, style: TextStyle(color: kTextSecondary)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(l.priceRange, style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${l.viewCount} görüntülənmə', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
