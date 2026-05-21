import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/workers_service.dart';
import '../../theme/app_theme.dart';

class WorkerSkillsScreen extends StatefulWidget {
  const WorkerSkillsScreen({super.key});

  @override
  State<WorkerSkillsScreen> createState() => _WorkerSkillsScreenState();
}

class _WorkerSkillsScreenState extends State<WorkerSkillsScreen> {
  final List<String> _selected = [];
  bool _loading = false, _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final w = await WorkersService.instance.getMyProfile();
      _selected.addAll(w.categories);
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await WorkersService.instance.updateMyProfile({'categories': _selected});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kateqoriyalar yeniləndi')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kError));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xidmət kateqoriyaları'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Hansı sahələrdə xidmət göstərirsiniz?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text('Birdən çox seçə bilərsiniz', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kCategories.map((cat) {
                    final sel = _selected.contains(cat);
                    return GestureDetector(
                      onTap: () => setState(() {
                        sel ? _selected.remove(cat) : _selected.add(cat);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : kPrimary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? kPrimary : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(kCategoryIcons[cat] ?? '✨', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                color: sel ? Colors.white : kPrimary,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (sel) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: kPrimary),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Saxla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}
