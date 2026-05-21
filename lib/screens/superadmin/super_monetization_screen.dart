import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

class SuperMonetizationScreen extends StatefulWidget {
  const SuperMonetizationScreen({super.key});

  @override
  State<SuperMonetizationScreen> createState() =>
      _SuperMonetizationScreenState();
}

class _SuperMonetizationScreenState extends State<SuperMonetizationScreen> {
  late final TextEditingController _commission;

  @override
  void initState() {
    super.initState();
    _commission = TextEditingController(
      text: SuperAdminService.instance.commissionPercent
          .toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _commission.dispose();
    super.dispose();
  }

  void _syncCommission() {
    final v = double.tryParse(_commission.text.replaceAll(',', '.'));
    if (v != null) {
      SuperAdminService.instance.setCommission(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: SuperAdminService.instance,
        builder: (context, _) {
          final s = SuperAdminService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komissiya (%)',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commission,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,2}(\.\d{0,2})?$'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Məs. 12',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      onSubmitted: (_) => _syncCommission(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _syncCommission();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yadda saxlanıldı')),
                          );
                        },
                        child: const Text('Tətbiq et'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _switchRow(
                      context,
                      title: 'Premium elan',
                      subtitle: 'Ödənişli ön sıra',
                      value: s.premiumJobEnabled,
                      onChanged: SuperAdminService.instance.setPremiumJob,
                    ),
                    const Divider(height: 24),
                    _switchRow(
                      context,
                      title: 'İcraçı boost',
                      subtitle: 'Profil vurğulanması',
                      value: s.workerBoostEnabled,
                      onChanged: SuperAdminService.instance.setWorkerBoost,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
