import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class SuperAuditScreen extends StatefulWidget {
  const SuperAuditScreen({super.key});

  @override
  State<SuperAuditScreen> createState() => _SuperAuditScreenState();
}

class _SuperAuditScreenState extends State<SuperAuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await AdminService.instance.getAuditLogs();
      if (mounted) setState(() { _logs = logs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Jurnalı'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Jurnal yoxdur', style: TextStyle(color: kTextSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history_rounded, color: kPrimary),
                          title: Text(log['action'] ?? 'Naməlum', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (log['detail'] != null)
                                Text(log['detail'], style: TextStyle(color: kTextSecondary, fontSize: 12)),
                              Text('Aktyor: ${log['actor_id'] ?? '?'}', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
