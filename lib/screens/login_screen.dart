import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../services/auth_service.dart' show AuthService;
import '../services/role_router_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_primary_button.dart';
import '../widgets/outlined_auth_button.dart';
import '../widgets/password_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await AuthService.instance.signIn(
        _idController.text.trim(),
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loginErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş zamanı xəta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final profile = AuthService.instance.profile;
    if (profile == null) return;
    context.go(RoleRouterService.homeDashboardLocation(profile));
  }

  String _loginErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Düzgün e-poçt daxil edin';
      case 'user-disabled':
        return 'Bu hesab deaktiv edilib';
      case 'too-many-requests':
        return 'Çox sayda cəhd. Bir az sonra yenidən yoxlayın';
      case 'invalid-phone':
      case 'missing-profile':
      case 'phone-account-not-found':
      case 'phone-email-missing':
        return e.message ?? 'Giriş alınmadı';
      case 'user-blocked':
        return 'Hesab bloklanıb';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-poçt / telefon və ya şifrə yanlışdır';
      default:
        final m = e.message?.trim();
        if (m != null && m.isNotEmpty) return m;
        return 'Giriş alınmadı (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Qonşudan Xidmət',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Xidmətləri tapın və ya təklif edin',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Daxil ol',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _idController,
                        label: 'Telefon və ya e-poçt',
                        hint: '+99450••••••• və ya email',
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        focusNode: _idFocus,
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.telephoneNumber,
                        ],
                        validator: Validators.phoneOrEmail,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                      ),
                      const SizedBox(height: 16),
                      PasswordFormField(
                        controller: _passwordController,
                        label: 'Şifrə',
                        textInputAction: TextInputAction.done,
                        focusNode: _passwordFocus,
                        validator: (v) => Validators.password(v),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      GradientPrimaryButton(
                        label: 'Daxil ol',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedAuthButton(
                  label: 'Qeydiyyatdan keç',
                  onPressed: () => context.push(AppRoutes.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
