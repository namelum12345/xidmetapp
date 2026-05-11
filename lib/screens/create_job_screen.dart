import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/job_category.dart';
import '../services/job_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/ui_feedback.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_primary_button.dart';
import '../widgets/location_pick_sheet.dart';
import '../widgets/location_picker_field.dart';
import 'map_picker_screen.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  final _loc = const LocationService();
  String? _address;
  LatLng? _lastMapPoint;
  JobCategoryId _category = JobCategoryId.cleaning;

  static final LatLng _bakuDefault = LatLng(40.4093, 49.8671);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kateqoriya',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...JobCategoryId.values.map((c) {
                  final sel = c == _category;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _category = c);
                          Navigator.pop(ctx);
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.outline,
                              width: sel ? 2 : 1,
                            ),
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : AppColors.background,
                          ),
                          child: Row(
                            children: [
                              Icon(c.icon, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.labelAz,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (sel)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLocation() async {
    final choice = await showLocationOptionsSheet(context);
    if (!mounted || choice == null) return;

    if (choice == 'current') {
      showBlockingLoader(context);
      try {
        final ll = await _loc.currentLatLng();
        if (!mounted) return;
        if (ll == null) {
          hideBlockingLoader(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Məkan icazəsi verilmədi və ya mövqe tapılmadı',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final addr = await _loc.addressFromLatLng(ll);
        if (!mounted) return;
        hideBlockingLoader(context);
        setState(() {
          _address = addr;
          _lastMapPoint = ll;
        });
      } catch (_) {
        if (mounted) hideBlockingLoader(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Məkan alınarkən xəta baş verdi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    if (choice == 'map') {
      final initial = _lastMapPoint ?? _bakuDefault;
      final picked = await Navigator.of(context, rootNavigator: true)
          .push<LatLng>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MapPickerScreen(initial: initial),
        ),
      );
      if (!mounted || picked == null) return;

      showBlockingLoader(context);
      try {
        final addr = await _loc.addressFromLatLng(picked);
        if (!mounted) return;
        hideBlockingLoader(context);
        setState(() {
          _address = addr;
          _lastMapPoint = picked;
        });
      } catch (_) {
        if (mounted) hideBlockingLoader(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ünvan təyin olunarkən xəta baş verdi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String? _optionalPrice(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Düzgün məbləğ daxil edin';
    return null;
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_address == null ||
        _address!.trim().isEmpty ||
        _lastMapPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ünvanı seçin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final priceText = _price.text.trim();
    final price =
        priceText.isEmpty ? null : double.tryParse(priceText.replaceAll(',', '.'));

    final desc = _description.text.trim();

    showBlockingLoader(context);
    try {
      await JobService.instance.createJob(
        title: _title.text.trim(),
        description: desc,
        category: _category,
        priceAzn: price,
        location: GeoPoint(_lastMapPoint!.latitude, _lastMapPoint!.longitude),
        locationLabel: _address!.trim(),
      );
      if (!mounted) return;
      hideBlockingLoader(context);
      context.pop(true);
    } catch (e) {
      if (mounted) hideBlockingLoader(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Elan yaradılmadı: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Yeni elan'),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _title,
                        label: 'Elanın başlığı',
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, message: 'Başlıq daxil edin'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _description,
                        label: 'Təsvir',
                        maxLines: 4,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, message: 'Təsvir yazın'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kateqoriya',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickCategory,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(_category.icon, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _category.labelAz,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _price,
                        label: 'Qiymət (₼) — istəyə bağlı',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]'),
                          ),
                        ],
                        textInputAction: TextInputAction.done,
                        validator: _optionalPrice,
                      ),
                      const SizedBox(height: 16),
                      LocationPickerField(
                        address: _address,
                        placeholder: 'Xidmət göstəriləcək ünvanı seçin',
                        onTap: _openLocation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientPrimaryButton(
                  label: 'Elanı paylaş',
                  onPressed: _publish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
