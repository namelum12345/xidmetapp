import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/super_admin_models.dart';
import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/permission_tile.dart';

class SuperPermissionsScreen extends StatefulWidget {
  const SuperPermissionsScreen({super.key});

  @override
  State<SuperPermissionsScreen> createState() => _SuperPermissionsScreenState();
}

class _SuperPermissionsScreenState extends State<SuperPermissionsScreen> {
  late PermissionSet _draft;

  @override
  void initState() {
    super.initState();
    _draft = SuperAdminService.instance.permissionTemplate.copy();
  }

  void _persist() {
    SuperAdminService.instance.updatePermissionTemplate(_draft);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İcazə şablonu yeniləndi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  'İcazələr',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni adminlər üçün defolt icazə şablonu.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          PermissionTile(
            title: 'İstifadəçiləri idarə et',
            subtitle: 'Siyahı, redaktə, silmə',
            value: _draft.manageUsers,
            onChanged: (v) => setState(() => _draft.manageUsers = v),
          ),
          PermissionTile(
            title: 'İcraçıları idarə et',
            subtitle: 'Doğrulama və profillər',
            value: _draft.manageWorkers,
            onChanged: (v) => setState(() => _draft.manageWorkers = v),
          ),
          PermissionTile(
            title: 'Elanları idarə et',
            subtitle: 'Moderasiya və silmə',
            value: _draft.manageJobs,
            onChanged: (v) => setState(() => _draft.manageJobs = v),
          ),
          PermissionTile(
            title: 'Söhbətlərə giriş',
            subtitle: 'Monitorinq və mesajlar',
            value: _draft.accessChats,
            onChanged: (v) => setState(() => _draft.accessChats = v),
          ),
          PermissionTile(
            title: 'İstifadəçiləri blokla',
            subtitle: 'Qlobal blok hüququ',
            value: _draft.banUsers,
            onChanged: (v) => setState(() => _draft.banUsers = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _persist,
            child: const Text('Yadda saxla'),
          ),
        ],
      ),
    );
  }
}
