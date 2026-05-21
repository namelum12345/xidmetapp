import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String q = '']) async {
    setState(() => _loading = true);
    try {
      final users = await AdminService.instance.getUsers(q: q);
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block(String uid) async {
    try {
      final blocked = await AdminService.instance.toggleBlock(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked ? 'Bloklandı' : 'Blok açıldı')),
      );
      _load(_searchCtrl.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kError));
    }
  }

  Future<void> _delete(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İstifadəçini sil'),
        content: const Text('Bu istifadəçini silmək istəyirsiniz?'),
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
      await AdminService.instance.deleteUser(uid);
      _load(_searchCtrl.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kError));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstifadəçilər', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Axtarış...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
              onChanged: (v) { if (v.isEmpty || v.length >= 2) _load(v); },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('İstifadəçi tapılmadı', style: TextStyle(color: kTextSecondary)))
                    : RefreshIndicator(
                        onRefresh: () => _load(_searchCtrl.text),
                        color: kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: kPrimary.withOpacity(0.1),
                                  child: Text(
                                    u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                                    style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                title: Text('${u.name} ${u.surname}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(u.email, style: TextStyle(color: kTextSecondary, fontSize: 12)),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'block') _block(u.id);
                                    if (v == 'delete') _delete(u.id);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Text(u.isBlocked ? 'Bloku aç' : 'Blokla'),
                                    ),
                                    const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: kError))),
                                  ],
                                ),
                                isThreeLine: false,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
