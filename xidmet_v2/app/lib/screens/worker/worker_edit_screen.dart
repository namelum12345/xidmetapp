import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/workers_service.dart';
import '../../theme/app_theme.dart';

class WorkerEditScreen extends StatefulWidget {
  const WorkerEditScreen({super.key});

  @override
  State<WorkerEditScreen> createState() => _WorkerEditScreenState();
}

class _WorkerEditScreenState extends State<WorkerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bio = TextEditingController();
  final _rate = TextEditingController();
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final w = await WorkersService.instance.getMyProfile();
      _bio.text = w.bio ?? '';
      _rate.text = w.hourlyRate?.toStringAsFixed(0) ?? '';
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  @override
  void dispose() {
    _bio.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await WorkersService.instance.updateMyProfile({
        'bio': _bio.text.trim(),
        if (_rate.text.trim().isNotEmpty) 'hourly_rate': double.tryParse(_rate.text.trim()),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil yeniləndi')));
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
        title: const Text('Profili düzənlə'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio (özünüz haqqında)', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Saatlıq qiymət (₼)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text('Saxla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
