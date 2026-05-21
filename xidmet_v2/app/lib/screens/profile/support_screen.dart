import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _FaqTile(
            q: 'İş necə sifariş verilir?',
            a: 'Ana səhifədə "İş yaz" düyməsini basın, formu doldurun və göndərin. İşçilər müraciət edəcək.',
          ),
          const _FaqTile(
            q: 'Ödəniş necə edilir?',
            a: 'Ödəniş işçi ilə bilavasitə razılaşdırılır. Tətbiq hazırda nağd ödənişi dəstəkləyir.',
          ),
          const _FaqTile(
            q: 'İşçini necə qiymətləndirirəm?',
            a: 'İş tamamlandıqdan sonra işçinin profilinə keçin və qiymətləndirmə yazın.',
          ),
          const _FaqTile(
            q: 'Hesabımı necə siləm?',
            a: 'Hesabınızı silmək üçün bizimlə əlaqə saxlayın: destek@qonsudan.az',
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bizimlə əlaqə', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mesajınız',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_msgCtrl.text.trim().isEmpty) return;
                        _msgCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mesajınız göndərildi!')),
                        );
                      },
                      child: const Text('Göndər'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(a, style: TextStyle(color: kTextSecondary, height: 1.5))],
      ),
    );
  }
}
