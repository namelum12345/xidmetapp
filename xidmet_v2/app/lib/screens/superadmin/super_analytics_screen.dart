import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class SuperAnalyticsScreen extends StatefulWidget {
  const SuperAnalyticsScreen({super.key});

  @override
  State<SuperAnalyticsScreen> createState() => _SuperAnalyticsScreenState();
}

class _SuperAnalyticsScreenState extends State<SuperAnalyticsScreen> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await AdminService.instance.getStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitika', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Platforma Statistikası', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _AnalyticRow('Ümumi istifadəçi', _stats['users'] ?? 0, Icons.people_rounded, kPrimary),
                  _AnalyticRow('Ümumi işçi', _stats['workers'] ?? 0, Icons.construction_rounded, kSuccess),
                  _AnalyticRow('Ümumi iş', _stats['jobs'] ?? 0, Icons.work_rounded, kWarning),
                  _AnalyticRow('Ümumi çat', _stats['chats'] ?? 0, Icons.chat_bubble_rounded, Colors.blue),
                  const SizedBox(height: 24),
                  Text('Aktivlik', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('İş/İstifadəçi nisbəti', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            _stats['users'] != null && _stats['users']! > 0
                                ? '${((_stats['jobs'] ?? 0) / _stats['users']!).toStringAsFixed(2)}'
                                : '0',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kPrimary),
                          ),
                          Text('iş / istifadəçi', style: TextStyle(color: kTextSecondary)),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _stats['users'] != null && _stats['users']! > 0
                                ? ((_stats['jobs'] ?? 0) / (_stats['users']! * 5)).clamp(0.0, 1.0)
                                : 0,
                            backgroundColor: kPrimary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(kPrimary),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AnalyticRow extends StatelessWidget {
  const _AnalyticRow(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
