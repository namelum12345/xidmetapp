import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  List<UserModel> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final workers = await AdminService.instance.getWorkers();
      if (mounted) setState(() { _workers = workers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşçilər', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? const Center(child: Text('İşçi tapılmadı', style: TextStyle(color: kTextSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workers.length,
                    itemBuilder: (_, i) {
                      final w = _workers[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kSuccess.withOpacity(0.1),
                            child: Text(
                              w.name.isNotEmpty ? w.name[0].toUpperCase() : 'W',
                              style: TextStyle(color: kSuccess, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text('${w.name} ${w.surname}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.email, style: TextStyle(color: kTextSecondary, fontSize: 12)),
                              if (w.isBlocked)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kError.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Bloklanmış', style: TextStyle(color: kError, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'block') {
                                await AdminService.instance.toggleBlock(w.id);
                                _load();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'block', child: Text(w.isBlocked ? 'Bloku aç' : 'Blokla')),
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
