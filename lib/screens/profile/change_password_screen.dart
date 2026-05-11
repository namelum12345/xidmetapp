import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';
import '../../widgets/password_form_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmMatch(String? v) {
    final e = Validators.password(v);
    if (e != null) return e;
    if (v != _next.text) return 'Şifrələr uyğun gəlmir';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-poçt ilə giriş tələb olunur')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _current.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifrə yeniləndi')),
      );
      context.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Şifrəni dəyiş'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  PasswordFormField(
                    controller: _current,
                    label: 'Cari şifrə',
                    validator: (v) => Validators.password(v),
                  ),
                  const SizedBox(height: 12),
                  PasswordFormField(
                    controller: _next,
                    label: 'Yeni şifrə',
                    validator: (v) => Validators.password(v),
                  ),
                  const SizedBox(height: 12),
                  PasswordFormField(
                    controller: _confirm,
                    label: 'Yeni şifrə (təkrar)',
                    validator: _confirmMatch,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientPrimaryButton(
            label: _busy ? 'Yenilənir…' : 'Şifrəni yenilə',
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
