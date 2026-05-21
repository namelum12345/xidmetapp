import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'user';
  bool _obscure = true;
  bool _loading = false;
  bool _locating = false;
  final List<String> _selectedCategories = [];
  double _lat = 40.4093;
  double _lng = 49.8671;
  String _locationLabel = '';

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final result = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _locationLabel = '${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)}';
        _locating = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'worker' && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ən az bir kateqoriya seçin'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        name: _name.text.trim(),
        surname: _surname.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _pass.text,
        role: _role,
        categories: _selectedCategories,
        lat: _lat,
        lng: _lng,
        address: _locationLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Qeydiyyat',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('Yeni hesab yaradın', style: TextStyle(color: kTextSecondary)),
                const SizedBox(height: 28),

                // Ad / Soyad
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Ad'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Tələb olunur' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _surname,
                        decoration: const InputDecoration(labelText: 'Soyad'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Tələb olunur' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-poçt',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Düzgün e-poçt daxil edin' : null,
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (istəyə bağlı)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Şifrə
                TextFormField(
                  controller: _pass,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Şifrə',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Ən azı 6 simvol' : null,
                ),
                const SizedBox(height: 20),

                // Location
                _LocationPicker(
                  label: _locationLabel,
                  loading: _locating,
                  onTap: _getLocation,
                ),
                const SizedBox(height: 24),

                // Hesab növü
                Text('Hesab növü', style: TextStyle(fontWeight: FontWeight.w600, color: kTextSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoleChip(
                      label: 'Müştəri',
                      subtitle: 'Xidmət axtarıram',
                      icon: Icons.person_outline_rounded,
                      selected: _role == 'user',
                      onTap: () => setState(() { _role = 'user'; _selectedCategories.clear(); }),
                    ),
                    const SizedBox(width: 12),
                    _RoleChip(
                      label: 'İşçi / Usta',
                      subtitle: 'Xidmət göstərirəm',
                      icon: Icons.construction_rounded,
                      selected: _role == 'worker',
                      onTap: () => setState(() => _role = 'worker'),
                    ),
                  ],
                ),

                // İşçi kateqoriyaları
                if (_role == 'worker') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Hansı sahədə çalışırsınız? *',
                        style: TextStyle(fontWeight: FontWeight.w700, color: kTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      if (_selectedCategories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '${_selectedCategories.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategories.map((cat) {
                      final sel = _selectedCategories.contains(cat);
                      return GestureDetector(
                        onTap: () => setState(() {
                          sel ? _selectedCategories.remove(cat) : _selectedCategories.add(cat);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? kPrimary : kPrimary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? kPrimary : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(kCategoryIcons[cat] ?? '✨', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 5),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: sel ? Colors.white : kPrimary,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              if (sel) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: kPrimary),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Qeydiyyatdan keç',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hesabınız var? ', style: TextStyle(color: kTextSecondary)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('Daxil olun', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? kPrimary.withOpacity(0.08) : Colors.transparent,
            border: Border.all(color: selected ? kPrimary : kBorder, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? kPrimary : kTextSecondary, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: selected ? kPrimary : kTextSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: selected ? kPrimary.withOpacity(0.7) : kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({required this.label, required this.loading, required this.onTap});
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = label.isNotEmpty;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation ? kPrimary.withOpacity(0.07) : Colors.transparent,
          border: Border.all(color: hasLocation ? kPrimary : kBorder, width: hasLocation ? 2 : 1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on_rounded : Icons.location_on_outlined,
              color: hasLocation ? kPrimary : kTextSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasLocation ? '📍 Məkan müəyyən edildi' : 'Məkanı müəyyən et (GPS)',
                style: TextStyle(
                  color: hasLocation ? kPrimary : kTextSecondary,
                  fontWeight: hasLocation ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                hasLocation ? Icons.check_circle_rounded : Icons.my_location_rounded,
                color: hasLocation ? kPrimary : kTextSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
