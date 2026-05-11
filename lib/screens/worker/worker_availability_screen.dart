import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({super.key});

  @override
  State<WorkerAvailabilityScreen> createState() => _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  String _mode = 'active';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final w = await UserService.instance.fetchWorkerDoc(uid);
      if (!mounted) return;
      setState(() {
        _mode = w?['availability'] as String? ?? 'active';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply(String mode) async {
    setState(() {
      _mode = mode;
      _saving = true;
    });
    try {
      final isAvailable = mode == 'active';
      await UserService.instance.updateMyWorkerFields({
        'availability': mode,
        'isAvailable': isAvailable,
      });
      await AuthService.instance.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status yeniləndi')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aktivlik statusu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Statusunuzu dəyişin — yeni iş uyğunluğu buna görə tənzimlənir.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _ModeCard(
                  title: 'Aktiv',
                  subtitle: 'Yeni işlər və təkliflər üçün açıqsınız',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF22C55E),
                  selected: _mode == 'active',
                  busy: _saving,
                  onTap: () => _apply('active'),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: 'Məşğul',
                  subtitle: 'Müvəqqəti olaraq yeni iş götürmürsünüz',
                  icon: Icons.pause_circle_outline_rounded,
                  color: const Color(0xFFF59E0B),
                  selected: _mode == 'busy',
                  busy: _saving,
                  onTap: () => _apply('busy'),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: 'Offline',
                  subtitle: 'Platformada görünmürsünüz',
                  icon: Icons.do_not_disturb_on_outlined,
                  color: const Color(0xFF9CA3AF),
                  selected: _mode == 'offline',
                  busy: _saving,
                  onTap: () => _apply('offline'),
                ),
              ],
            ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: busy ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: busy ? null : onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF1C1C24)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_rounded, color: AppColors.primary, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
