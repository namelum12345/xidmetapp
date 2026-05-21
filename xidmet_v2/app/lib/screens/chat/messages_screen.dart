import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ChatThreadModel> _threads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final threads = await ChatService.instance.getThreads();
      if (mounted) setState(() { _threads = threads; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.instance.user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Yenilə')),
                    ],
                  ),
                )
              : _threads.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kTextSecondary),
                          SizedBox(height: 12),
                          Text('Heç bir mesaj yoxdur', style: TextStyle(color: kTextSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPrimary,
                      child: ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (_, i) {
                          final t = _threads[i];
                          final unread = t.unread;
                          final otherName = t.otherName.isNotEmpty ? t.otherName : 'İstifadəçi';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: kPrimary.withOpacity(0.1),
                              child: Text(
                                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                                style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              t.lastMessage ?? 'Mesaj yoxdur',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: kTextSecondary),
                            ),
                            trailing: unread > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  )
                                : null,
                            onTap: () => context.push('/chat/${t.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
