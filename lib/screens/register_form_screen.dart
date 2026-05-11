import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/job_category.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/role_router_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_primary_button.dart';
import '../widgets/location_pick_sheet.dart';
import '../widgets/location_picker_field.dart';
import '../widgets/password_form_field.dart';
import '../widgets/phone_form_field.dart';
import 'map_picker_screen.dart';

class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  final _fnFocus = FocusNode();
  final _lnFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _location = const LocationService();

  String? _address;
  LatLng? _lastMapPoint;

  final Set<JobCategoryId> _workerSkills = {
    JobCategoryId.repair,
    JobCategoryId.electric,
    JobCategoryId.plumbing,
  };

  static final LatLng _bakuDefault = LatLng(40.4093, 49.8671);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _fnFocus.dispose();
    _lnFocus.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _showBlockingLoader() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  void _hideLoader() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _openLocationPicker() async {
    final choice = await showLocationOptionsSheet(context);
    if (!mounted || choice == null) return;

    if (choice == 'current') {
      await _showBlockingLoader();
      try {
        final ll = await _location.currentLatLng();
        if (!mounted) return;
        if (ll == null) {
          _hideLoader();
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
        final addr = await _location.addressFromLatLng(ll);
        if (!mounted) return;
        _hideLoader();
        setState(() {
          _address = addr;
          _lastMapPoint = ll;
        });
      } catch (_) {
        if (mounted) _hideLoader();
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
      final picked = await Navigator.of(context, rootNavigator: true).push<LatLng>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MapPickerScreen(initial: initial),
        ),
      );
      if (!mounted || picked == null) return;

      await _showBlockingLoader();
      try {
        final addr = await _location.addressFromLatLng(picked);
        if (!mounted) return;
        _hideLoader();
        setState(() {
          _address = addr;
          _lastMapPoint = picked;
        });
      } catch (_) {
        if (mounted) _hideLoader();
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

  String? _validateName(String? v, String emptyMsg) {
    final err = Validators.required(v, message: emptyMsg);
    if (err != null) return err;
    if (v!.trim().length < 2) return 'Ən azı 2 simvol';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-poçt boş ola bilməz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifrə ən azı 6 simvol olmalıdır'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon nömrəsi məcburidir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    if (widget.role == UserRole.worker && _workerSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ən azı bir bacarıq seçin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phoneKey = AuthService.normalizePhoneKey(
      PhoneFormField.dialCode,
      _phone.text.trim(),
    );

    await _showBlockingLoader();
    try {
      await AuthService.instance.signUp(
        email: _email.text.trim(),
        password: _password.text,
        name: _firstName.text.trim(),
        surname: _lastName.text.trim(),
        phoneKey: phoneKey,
        role: widget.role,
        location: GeoPoint(_lastMapPoint!.latitude, _lastMapPoint!.longitude),
        workerSkillIds: widget.role == UserRole.worker
            ? _workerSkills.map((e) => e.name).toList()
            : const [],
      );
      if (!mounted) return;
      _hideLoader();
      final p = AuthService.instance.profile;
      if (p != null) {
        context.go(RoleRouterService.homeDashboardLocation(p));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _hideLoader();
      if (!mounted) return;
      final msg = switch (e.code) {
        'email-already-in-use' => 'Bu e-poçt artıq qeydiyyatdan keçib',
        'phone-already-in-use' => 'Bu telefon nömrəsi artıq qeydiyyatdan keçib',
        'weak-password' => 'Şifrə çox zəifdir',
        _ => e.message ?? e.code,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) _hideLoader();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is FirebaseException
                ? (e.message ?? 'Qeydiyyat zamanı xəta baş verdi')
                : 'Qeydiyyat zamanı xəta baş verdi',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Qeydiyyat'),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Məlumatlarınızı daxil edin',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(text: 'Şəxsi məlumat'),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _firstName,
                        label: 'Ad',
                        textInputAction: TextInputAction.next,
                        focusNode: _fnFocus,
                        validator: (v) => _validateName(v, 'Ad daxil edin'),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_lnFocus),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _lastName,
                        label: 'Soyad',
                        textInputAction: TextInputAction.next,
                        focusNode: _lnFocus,
                        validator: (v) =>
                            _validateName(v, 'Soyad daxil edin'),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailFocus),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _email,
                        label: 'E-poçt',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        focusNode: _emailFocus,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_pwFocus),
                      ),
                      const SizedBox(height: 16),
                      PasswordFormField(
                        controller: _password,
                        label: 'Şifrə',
                        textInputAction: TextInputAction.next,
                        focusNode: _pwFocus,
                        validator: Validators.password,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_phoneFocus),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(text: 'Əlaqə'),
                      const SizedBox(height: 12),
                      PhoneFormField(
                        controller: _phone,
                        focusNode: _phoneFocus,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (widget.role == UserRole.worker) ...[
                        const SizedBox(height: 20),
                        _SectionLabel(text: 'Bacarıqlar'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: JobCategoryId.values.map((c) {
                            final sel = _workerSkills.contains(c);
                            return FilterChip(
                              label: Text(c.labelAz),
                              selected: sel,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _workerSkills.add(c);
                                  } else {
                                    _workerSkills.remove(c);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionLabel(text: 'Ünvan'),
                      const SizedBox(height: 12),
                      LocationPickerField(
                        address: _address,
                        placeholder: 'Ünvanı seçmək üçün toxunun',
                        onTap: _openLocationPicker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientPrimaryButton(
                  label: 'Qeydiyyatdan keç',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
