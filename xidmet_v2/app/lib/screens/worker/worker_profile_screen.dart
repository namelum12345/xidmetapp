import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/workers_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  WorkerModel? _worker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final w = await WorkersService.instance.getMyProfile();
      if (mounted) setState(() { _worker = w; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: kPrimary.withOpacity(0.1),
                          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null
                              ? Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'W',
                                  style: TextStyle(color: kPrimary, fontSize: 32, fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user?.name ?? ''} ${user?.surname ?? ''}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(user?.email ?? '', style: TextStyle(color: kTextSecondary)),
                        if (_worker != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatChip(Icons.star_rounded, '${_worker!.rating.toStringAsFixed(1)}', kWarning),
                              const SizedBox(width: 12),
                              _StatChip(Icons.check_circle_outline_rounded, '${_worker!.completedCount}', kSuccess),
                              if (_worker!.hourlyRate != null) ...[
                                const SizedBox(width: 12),
                                _StatChip(Icons.attach_money_rounded, '${_worker!.hourlyRate!.toStringAsFixed(0)} ₼/s', kPrimary),
                              ],
                            ],
                          ),
                          if (_worker!.bio?.isNotEmpty == true) ...[
                            const SizedBox(height: 16),
                            Text(_worker!.bio!, textAlign: TextAlign.center, style: TextStyle(color: kTextSecondary, height: 1.5)),
                          ],
                          if (_worker!.categories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: _worker!.categories.map((s) => Chip(
                                label: Text('${kCategoryIcons[s] ?? ''} $s'),
                              )).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Hesab'),
                  _Tile(Icons.edit_outlined, 'Profili düzənlə', () => context.push('/w/profile/edit')),
                  _Tile(Icons.build_circle_outlined, 'Bacarıqlar', () => context.push('/w/profile/skills')),
                  _Tile(Icons.calendar_month_outlined, 'Mövcudluq', () => context.push('/w/profile/availability')),
                  _Tile(Icons.monetization_on_outlined, 'Qazanc', () => context.push('/w/profile/earnings')),
                  _Tile(Icons.star_border_rounded, 'Rəylər', () => context.push('/w/profile/reviews')),
                  _Tile(Icons.work_outline_rounded, 'Mənim işlərim', () => context.push('/w/profile/my-jobs')),
                  _Tile(Icons.lock_outline_rounded, 'Şifrəni dəyiş', () => context.push('/w/profile/change-password')),
                  const SizedBox(height: 8),
                  _SectionTitle('Digər'),
                  _Tile(Icons.notifications_outlined, 'Bildirişlər', () => context.push('/w/profile/notifications')),
                  _Tile(Icons.settings_outlined, 'Parametrlər', () => context.push('/w/profile/settings')),
                  _Tile(Icons.help_outline_rounded, 'Yardım', () => context.push('/w/profile/support')),
                  const SizedBox(height: 8),
                  _Tile(
                    Icons.logout_rounded,
                    'Çıxış',
                    () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Çıxış'),
                          content: const Text('Hesabdan çıxmaq istəyirsiniz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıx')),
                          ],
                        ),
                      );
                      if (confirmed == true) await AuthService.instance.signOut();
                    },
                    color: kError,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(text, style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, this.onTap, {this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: kTextSecondary),
        onTap: onTap,
      ),
    );
  }
}
