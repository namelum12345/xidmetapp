import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/workers_service.dart';
import '../../theme/app_theme.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({super.key});

  @override
  State<WorkerAvailabilityScreen> createState() => _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  String _availability = 'available';
  bool _loading = false, _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final w = await WorkersService.instance.getMyProfile();
      _availability = w.availability ?? 'available';
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await WorkersService.instance.updateMyProfile({'availability': _availability});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mövcudluq yeniləndi')));
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
        title: const Text('Mövcudluq'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Hazırkı vəziyyətinizi seçin', style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _AvailOption(
                  value: 'available',
                  label: 'Mövcud',
                  subtitle: 'Yeni sifarişlər qəbul edirəm',
                  icon: Icons.check_circle_outline_rounded,
                  color: kSuccess,
                  selected: _availability == 'available',
                  onTap: () => setState(() => _availability = 'available'),
                ),
                const SizedBox(height: 10),
                _AvailOption(
                  value: 'busy',
                  label: 'Məşğul',
                  subtitle: 'Hazırda yeni iş qəbul etmirəm',
                  icon: Icons.hourglass_empty_rounded,
                  color: kWarning,
                  selected: _availability == 'busy',
                  onTap: () => setState(() => _availability = 'busy'),
                ),
                const SizedBox(height: 10),
                _AvailOption(
                  value: 'offline',
                  label: 'Oflayn',
                  subtitle: 'Aktiv deyiləm',
                  icon: Icons.offline_bolt_outlined,
                  color: kTextSecondary,
                  selected: _availability == 'offline',
                  onTap: () => setState(() => _availability = 'offline'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
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

class _AvailOption extends StatelessWidget {
  const _AvailOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String value, label, subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: selected ? color : kBorder, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  Text(subtitle, style: TextStyle(color: kTextSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (selected) Icon(Icons.radio_button_checked_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
