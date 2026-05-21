import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class SuperAdminsScreen extends StatefulWidget {
  const SuperAdminsScreen({super.key});

  @override
  State<SuperAdminsScreen> createState() => _SuperAdminsScreenState();
}

class _SuperAdminsScreenState extends State<SuperAdminsScreen> {
  List<UserModel> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await AdminService.instance.getUsers();
      if (mounted) setState(() {
        _admins = users.where((u) => u.role == 'admin').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreate() {
    final nameCtrl = TextEditingController();
    final surnameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Admin', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
            const SizedBox(height: 10),
            TextField(controller: surnameCtrl, decoration: const InputDecoration(labelText: 'Soyad')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-poçt')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await AdminService.instance.createAdmin(
                      name: nameCtrl.text.trim(),
                      surname: surnameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin yaradıldı! Şifrə: admin123')),
                      );
                      _load();
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: kError),
                    );
                  }
                },
                child: const Text('Yarat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adminlər', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_rounded), onPressed: _showCreate),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, size: 64, color: kTextSecondary),
                      const SizedBox(height: 12),
                      const Text('Heç bir admin yoxdur', style: TextStyle(color: kTextSecondary)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Admin əlavə et'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _admins.length,
                    itemBuilder: (_, i) {
                      final a = _admins[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withOpacity(0.1),
                            child: Text(
                              a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text('${a.name} ${a.surname}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(a.email, style: TextStyle(color: kTextSecondary, fontSize: 12)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'block') {
                                await AdminService.instance.toggleBlock(a.id);
                                _load();
                              } else if (v == 'remove') {
                                await AdminService.instance.changeRole(a.id, 'user');
                                _load();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'block', child: Text(a.isBlocked ? 'Bloku aç' : 'Blokla')),
                              const PopupMenuItem(value: 'remove', child: Text('Admin sil')),
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
