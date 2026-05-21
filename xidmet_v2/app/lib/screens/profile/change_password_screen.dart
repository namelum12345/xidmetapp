import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.changePassword(_current.text, _newPass.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifrə dəyişdirildi')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kError));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifrəni dəyiş'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PassField(controller: _current, label: 'Cari şifrə', obscure: _obscure1,
                toggle: () => setState(() => _obscure1 = !_obscure1)),
            const SizedBox(height: 16),
            _PassField(controller: _newPass, label: 'Yeni şifrə', obscure: _obscure2,
                toggle: () => setState(() => _obscure2 = !_obscure2),
                validator: (v) => (v == null || v.length < 6) ? 'Ən azı 6 simvol' : null),
            const SizedBox(height: 16),
            _PassField(controller: _confirm, label: 'Yeni şifrəni təsdiqlə', obscure: _obscure3,
                toggle: () => setState(() => _obscure3 = !_obscure3),
                validator: (v) => v != _newPass.text ? 'Şifrələr uyğun deyil' : null),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Dəyiş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.toggle,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback toggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: toggle,
        ),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Tələb olunur' : null,
    );
  }
}
