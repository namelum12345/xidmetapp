import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_primary_button.dart';
import '../../widgets/phone_form_field.dart';
import '../map_picker_screen.dart';

/// Ad, soyad, telefon, avatar, məkan — Firestore + Storage.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.viewerRole});

  final UserRole viewerRole;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _surname;
  late final TextEditingController _phoneBody;
  GeoPoint? _location;
  String? _locationLabel;
  bool _saving = false;
  bool _geoBusy = false;

  static String _nineFromPhoneKey(String key) {
    final d = key.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('994')) {
      return d.substring(3);
    }
    if (d.length == 9) return d;
    return '';
  }

  @override
  void initState() {
    super.initState();
    final p = AuthService.instance.profile;
    _name = TextEditingController(text: p?.name ?? '');
    _surname = TextEditingController(text: p?.surname ?? '');
    _phoneBody = TextEditingController(
      text: p != null ? _nineFromPhoneKey(p.phoneKey) : '',
    );
    _location = p?.location;
    if (_location != null) {
      _refreshLocationLabel(_location!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phoneBody.dispose();
    super.dispose();
  }

  Future<void> _refreshLocationLabel(GeoPoint g) async {
    setState(() => _geoBusy = true);
    try {
      final marks = await geo.placemarkFromCoordinates(g.latitude, g.longitude);
      if (!mounted) return;
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).toList();
        setState(() {
          _locationLabel = parts.isEmpty
              ? '${g.latitude.toStringAsFixed(4)}, ${g.longitude.toStringAsFixed(4)}'
              : parts.join(', ');
        });
      } else {
        setState(() {
          _locationLabel =
              '${g.latitude.toStringAsFixed(4)}, ${g.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLabel =
              '${g.latitude.toStringAsFixed(4)}, ${g.longitude.toStringAsFixed(4)}';
        });
      }
    } finally {
      if (mounted) setState(() => _geoBusy = false);
    }
  }

  Future<void> _useGps() async {
    setState(() => _saving = true);
    try {
      final ll = await const LocationService().currentLatLng();
      if (ll == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS mövqesi alınmadı')),
          );
        }
        return;
      }
      if (!mounted) return;
      final g = GeoPoint(ll.latitude, ll.longitude);
      setState(() => _location = g);
      await _refreshLocationLabel(g);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickMap() async {
    final start = _location != null
        ? LatLng(_location!.latitude, _location!.longitude)
        : const LatLng(40.4093, 49.8671);
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => MapPickerScreen(initial: start)),
    );
    if (picked == null || !mounted) return;
    final g = GeoPoint(picked.latitude, picked.longitude);
    setState(() {
      _location = g;
    });
    await _refreshLocationLabel(g);
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (x == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final url = await UserService.instance.uploadProfilePhoto(x);
      await UserService.instance.updateMyUserFields({'photoUrl': url});
      await AuthService.instance.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil şəkli yeniləndi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şəkil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Məkan seçin')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final rawPhone = '${PhoneFormField.dialCode}${_phoneBody.text.trim()}';
      await UserService.instance.updatePhoneKeyFromRawInput(rawPhone);

      await UserService.instance.updateMyUserFields({
        'name': _name.text.trim(),
        'surname': _surname.text.trim(),
        'location': _location,
      });

      if (widget.viewerRole == UserRole.worker) {
        final dn = '${_name.text.trim()} ${_surname.text.trim()}'.trim();
        await UserService.instance.updateMyWorkerFields({
          'displayName': dn.isEmpty ? 'İcraçı' : dn,
        });
      }

      await AuthService.instance.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil saxlanıldı')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthService.instance.profile;
    final photo = p?.photoUrl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hesabı redaktə et'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: photo != null && photo.isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo == null || photo.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.primary)
                          : null,
                    ),
                    title: const Text('Profil şəkli'),
                    subtitle: const Text('Qalereyadan yüklə'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _saving ? null : _pickPhoto,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _name,
                    label: 'Ad',
                    validator: (v) => Validators.required(v),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _surname,
                    label: 'Soyad',
                    validator: (v) => Validators.required(v),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  PhoneFormField(controller: _phoneBody),
                  const SizedBox(height: 20),
                  Text(
                    'Məkan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _geoBusy
                        ? 'Ünvan axtarılır…'
                        : (_locationLabel ??
                            (_location != null
                                ? '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}'
                                : 'Seçilməyib')),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _useGps,
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Text('GPS'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _pickMap,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Xəritə'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientPrimaryButton(
            label: _saving ? 'Saxlanılır…' : 'Yadda saxla',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
