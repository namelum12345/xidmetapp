import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametrlər'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme section
          _SectionLabel(label: 'Görünüş'),
          const SizedBox(height: 8),
          const _ThemeSelector(),
          const SizedBox(height: 20),

          // Notifications
          _SectionLabel(label: 'Bildirişlər'),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Push bildirişlər'),
              subtitle: const Text('Yeni müraciət və mesajlar üçün'),
              secondary: const Icon(Icons.notifications_outlined),
              value: true,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 20),

          // Language
          _SectionLabel(label: 'Dil'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Tətbiq dili'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Azərbaycan',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                ],
              ),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 20),

          // About
          _SectionLabel(label: 'Tətbiq'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Qonşudan Xidmət',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text('Versiya: 1.0.0',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13)),
                  Text('© 2025 Qonşudan Xidmət',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme selector ────────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.instance,
      builder: (context, current, _) {
        return Card(
          child: Column(
            children: [
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'Sistem',
                subtitle: 'Cihazın parametrlərinə uyğun',
                mode: ThemeMode.system,
                current: current,
                isFirst: true,
              ),
              Divider(height: 1, indent: 56,
                  color: Theme.of(context).colorScheme.outline),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Açıq rejim',
                subtitle: 'Həmişə açıq tema',
                mode: ThemeMode.light,
                current: current,
              ),
              Divider(height: 1, indent: 56,
                  color: Theme.of(context).colorScheme.outline),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Tünd rejim',
                subtitle: 'Həmişə tünd tema',
                mode: ThemeMode.dark,
                current: current,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.current,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode current;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final selected = current == mode;
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(kRadiusLg) : Radius.zero,
      bottom: isLast ? const Radius.circular(kRadiusLg) : Radius.zero,
    );

    return InkWell(
      onTap: () => ThemeProvider.instance.setMode(mode),
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? cs.primary.withOpacity(0.12) : cs.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? cs.primary : cs.onSurface.withOpacity(0.6),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? cs.primary : cs.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
