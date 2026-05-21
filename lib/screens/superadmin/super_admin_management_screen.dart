import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/superadmin_control_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';

/// Superadmin → "Adminlər" tabı.
/// - Sistemdəki bütün adminlərin geniş siyahısı (axtarış + status filtri)
/// - Hər admin üçün avatar, ad, email, telefon, qeydiyyat tarixi, status pill
/// - Tap → bottom sheet (tam məlumat + əməliyyatlar: blok / silmə / promotion).
class SuperAdminManagementScreen extends StatefulWidget {
  const SuperAdminManagementScreen({super.key});

  @override
  State<SuperAdminManagementScreen> createState() =>
      _SuperAdminManagementScreenState();
}

class _SuperAdminManagementScreenState
    extends State<SuperAdminManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _AdminFilter _filter = _AdminFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateAdminDialog() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: 'admin123');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni admin yarat'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Ad daxil edin' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-poçt'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'E-poçt daxil edin';
                    if (!t.contains('@')) return 'E-poçt düzgün deyil';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Şifrə (min 6)'),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'Min 6 simvol' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ləğv'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await SuperadminControlService.instance.createAdmin(
                    name: name.text.trim(),
                    email: email.text.trim(),
                    password: password.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (err) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Xəta: $err')),
                  );
                }
              },
              child: const Text('Yarat'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin yaradıldı')),
      );
    }
  }

  Future<void> _openAdminSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return _AdminDetailSheet(
          uid: doc.id,
          initialData: doc.data(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SuperadminControlService.instance.usersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firestore: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final raw = snap.data?.docs ?? const [];
          final allAdmins = raw.where((d) {
            final r =
                (d.data()['role'] as String? ?? '').trim().toLowerCase();
            return r == 'admin';
          }).toList()
            ..sort(_byCreatedAtDesc);

          final total = allAdmins.length;
          final blocked =
              allAdmins.where((d) => _isBlocked(d.data())).length;
          final active = total - blocked;

          var list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            allAdmins,
          );
          if (_filter == _AdminFilter.active) {
            list = list.where((d) => !_isBlocked(d.data())).toList();
          } else if (_filter == _AdminFilter.blocked) {
            list = list.where((d) => _isBlocked(d.data())).toList();
          }
          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            list = list.where((d) {
              final m = d.data();
              return [
                m['name'],
                m['surname'],
                m['email'],
                m['phone'],
                m['phoneKey'],
              ].any((e) =>
                  (e?.toString().toLowerCase() ?? '').contains(q));
            }).toList();
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adminlər',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sistemdə qeydiyyatda olan adminlərin idarəetməsi',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _AdminSummaryCard(
                    total: total,
                    active: active,
                    blocked: blocked,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: GradientPrimaryButton(
                    label: '+ Yeni admin yarat',
                    onPressed: _showCreateAdminDialog,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      for (final f in _AdminFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.18),
                            labelStyle: TextStyle(
                              color: _filter == f
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: _filter == f
                                    ? AppColors.primary
                                    : AppColors.outline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          total == 0
                              ? 'Hələ admin yoxdur'
                              : 'Bu filtrə uyğun admin tapılmadı',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final d = list[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AdminListCard(
                            doc: d,
                            onTap: () => _openAdminSheet(d),
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _AdminFilter { all, active, blocked }

extension on _AdminFilter {
  String get label => switch (this) {
        _AdminFilter.all => 'Hamısı',
        _AdminFilter.active => 'Aktiv',
        _AdminFilter.blocked => 'Bloklu',
      };
}

bool _isBlocked(Map<String, dynamic> m) =>
    m['isBlocked'] == true || m['banned'] == true;

int _byCreatedAtDesc(
  QueryDocumentSnapshot<Map<String, dynamic>> a,
  QueryDocumentSnapshot<Map<String, dynamic>> b,
) {
  final ta = a.data()['createdAt'];
  final tb = b.data()['createdAt'];
  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
  if (ta is Timestamp) return -1;
  if (tb is Timestamp) return 1;
  return 0;
}

String _fullName(Map<String, dynamic> m) {
  final name = (m['name'] as String? ?? '').trim();
  final surname = (m['surname'] as String? ?? '').trim();
  final full = ('$name $surname').trim();
  if (full.isNotEmpty) return full;
  final email = (m['email'] as String? ?? '').trim();
  if (email.isNotEmpty) return email;
  return 'Naməlum';
}

String _initialsFromName(String fullName) {
  final parts = fullName
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

String _formatDate(dynamic ts) {
  if (ts is! Timestamp) return '—';
  final d = ts.toDate().toLocal();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

String _formatDateTime(dynamic ts) {
  if (ts is! Timestamp) return '—';
  final d = ts.toDate().toLocal();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.outline),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Admin axtar (ad, email, telefon)',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
      ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({
    required this.total,
    required this.active,
    required this.blocked,
  });

  final int total;
  final int active;
  final int blocked;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(label: 'Cəmi', value: '$total')),
          Container(width: 1, height: 40, color: AppColors.outline),
          Expanded(
            child: _SummaryItem(
              label: 'Aktiv',
              value: '$active',
              color: const Color(0xFF22C55E),
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.outline),
          Expanded(
            child: _SummaryItem(
              label: 'Bloklu',
              value: '$blocked',
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AdminListCard extends StatelessWidget {
  const _AdminListCard({required this.doc, required this.onTap});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final m = doc.data();
    final name = _fullName(m);
    final email = (m['email'] as String? ?? '').trim();
    final phone = (m['phone'] as String? ?? m['phoneKey'] as String? ?? '')
        .trim();
    final blocked = _isBlocked(m);
    final created = _formatDate(m['createdAt']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      const Color(0xFF7D76FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initialsFromName(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusPill(blocked: blocked),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          created,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final bg =
        blocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final fg =
        blocked ? const Color(0xFFB91C1C) : const Color(0xFF166534);
    final text = blocked ? 'Bloklu' : 'Aktiv';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _AdminDetailSheet extends StatefulWidget {
  const _AdminDetailSheet({required this.uid, required this.initialData});

  final String uid;
  final Map<String, dynamic> initialData;

  @override
  State<_AdminDetailSheet> createState() => _AdminDetailSheetState();
}

class _AdminDetailSheetState extends State<_AdminDetailSheet> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xəta: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snap) {
          final m = snap.data?.data() ?? widget.initialData;
          final name = _fullName(m);
          final email = (m['email'] as String? ?? '').trim();
          final phone = (m['phone'] as String? ?? m['phoneKey'] as String? ?? '')
              .trim();
          final role = (m['role'] as String? ?? '').trim();
          final blocked = _isBlocked(m);
          final created = _formatDateTime(m['createdAt']);

          return Padding(
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.9),
                              const Color(0xFF7D76FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initialsFromName(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    role.isEmpty ? 'admin' : role,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _StatusPill(blocked: blocked),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-poçt',
                          value: email.isEmpty ? '—' : email,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefon',
                          value: phone.isEmpty ? '—' : phone,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Qeydiyyat',
                          value: created,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'UID',
                          value: widget.uid,
                          mono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Əməliyyatlar',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                    label: blocked ? 'Blokdan çıxar' : 'Blok et',
                    color: blocked
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    busy: _busy,
                    onTap: () => _run(
                      () => SuperadminControlService.instance.toggleBlocked(
                        uid: widget.uid,
                        blocked: !blocked,
                      ),
                      successMessage:
                          blocked ? 'Admin aktivləşdirildi' : 'Admin bloklandı',
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.person_remove_alt_1_outlined,
                    label: 'Adminliyi ləğv et (user et)',
                    color: AppColors.primary,
                    busy: _busy,
                    onTap: () => _run(
                      () => SuperadminControlService.instance.changeRole(
                        uid: widget.uid,
                        fromRole: 'admin',
                        toRole: 'user',
                      ),
                      successMessage: 'Rol user-ə dəyişdirildi',
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.delete_forever_outlined,
                    label: 'Admini sil',
                    color: const Color(0xFFB91C1C),
                    busy: _busy,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Admini sil?'),
                          content: const Text(
                            'Bu admin hesab və əlaqəli məlumatlar tamamilə silinəcək. Davam edək?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Yox'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB91C1C),
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await _run(
                        () => SuperadminControlService.instance.deleteAdmin(
                          widget.uid,
                        ),
                        successMessage: 'Admin silindi',
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Son fəaliyyət',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AdminActivityList(uid: widget.uid),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.outline);
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.busy,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActivityList extends StatelessWidget {
  const _AdminActivityList({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .where('performedBy', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Hələ fəaliyyət qeydi yoxdur',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < docs.length; i++) ...[
                if (i > 0) const _Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (docs[i].data()['action'] as String? ??
                                      'action')
                                  .replaceAll('_', ' '),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _formatDateTime(docs[i].data()['timestamp']),
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
