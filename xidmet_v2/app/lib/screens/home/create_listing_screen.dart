import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/models.dart';
import '../../services/listings_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _workHoursCtrl = TextEditingController(text: '09:00-18:00');

  String _category = kCategories.first;
  bool _isUrgent = false;
  bool _homeService = false;
  bool _saving = false;
  List<String> _uploadedImages = [];
  bool _uploadingImage = false;
  bool _locating = false;
  double _lat = 40.4093;
  double _lng = 49.8671;
  String _locationLabel = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _workHoursCtrl.dispose();
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
        if (_addressCtrl.text.isEmpty && result.address.isNotEmpty && result.address != 'Bakı') {
          _addressCtrl.text = result.address;
        }
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1080);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final token = ApiService.instance.token;
      final req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload'));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.files.add(await http.MultipartFile.fromPath('file', picked.path));
      final resp = await req.send();
      final body = jsonDecode(await resp.stream.bytesToString());
      if (resp.statusCode == 200) {
        setState(() => _uploadedImages.add(body['url'] as String));
      } else {
        _snack('Şəkil yüklənmədi: ${body['detail'] ?? ''}');
      }
    } catch (e) {
      _snack('Şəkil xətası: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ListingsService.instance.create(
        title: _titleCtrl.text.trim(),
        category: _category,
        description: _descCtrl.text.trim(),
        images: _uploadedImages,
        minPrice: double.tryParse(_minPriceCtrl.text) ?? 0,
        maxPrice: double.tryParse(_maxPriceCtrl.text) ?? 0,
        address: _addressCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        workHours: _workHoursCtrl.text.trim(),
        isUrgent: _isUrgent,
        homeService: _homeService,
        contactPhone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elan yerləşdirildi!')));
        context.pop();
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elan yerləşdir'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Dərc et', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images
            _SectionTitle(title: 'Şəkillər'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._uploadedImages.map((url) => _UploadedImage(
                    url: '${ApiService.baseUrl}$url',
                    onRemove: () => setState(() => _uploadedImages.remove(url)),
                  )),
                  if (_uploadedImages.length < 5)
                    GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: kPrimary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                          color: kPrimary.withOpacity(0.05),
                        ),
                        child: _uploadingImage
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: kPrimary, size: 28),
                                  const SizedBox(height: 4),
                                  Text('Şəkil əlavə et', style: TextStyle(color: kPrimary, fontSize: 10), textAlign: TextAlign.center),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _SectionTitle(title: 'Kateqoriya *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : kPrimary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${kCategoryIcons[cat] ?? ''} $cat',
                      style: TextStyle(color: sel ? Colors.white : kPrimary, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Title
            _SectionTitle(title: 'Başlıq *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Məs: Elektrik işləri - sürətli və keyfiyyətli'),
              validator: (v) => v == null || v.trim().length < 5 ? 'Ən az 5 hərf daxil edin' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _SectionTitle(title: 'Ətraflı məlumat'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(hintText: 'Təcrübəniz, xidmət növləri, şərtlər...'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Price
            _SectionTitle(title: 'Qiymət aralığı (₼)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPriceCtrl,
                    decoration: const InputDecoration(hintText: 'Min', prefixText: '₼ '),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('—')),
                Expanded(
                  child: TextFormField(
                    controller: _maxPriceCtrl,
                    decoration: const InputDecoration(hintText: 'Max', prefixText: '₼ '),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Work hours
            _SectionTitle(title: 'İş saatları'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _workHoursCtrl,
              decoration: const InputDecoration(hintText: '09:00-18:00', prefixIcon: Icon(Icons.schedule_rounded)),
            ),
            const SizedBox(height: 16),

            // Location
            _SectionTitle(title: 'Məkan'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _locating ? null : _getLocation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _locationLabel.isNotEmpty ? kPrimary.withOpacity(0.07) : Colors.transparent,
                  border: Border.all(
                    color: _locationLabel.isNotEmpty ? kPrimary : Colors.grey.shade300,
                    width: _locationLabel.isNotEmpty ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationLabel.isNotEmpty ? Icons.location_on_rounded : Icons.my_location_rounded,
                      color: _locationLabel.isNotEmpty ? kPrimary : kTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationLabel.isNotEmpty ? '📍 GPS məkan müəyyən edildi' : 'GPS ilə məkanı müəyyən et',
                        style: TextStyle(
                          color: _locationLabel.isNotEmpty ? kPrimary : kTextSecondary,
                          fontWeight: _locationLabel.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_locating)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(
                        _locationLabel.isNotEmpty ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                        color: _locationLabel.isNotEmpty ? kPrimary : kTextSecondary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Address
            _SectionTitle(title: 'Ünvan (mətn)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(hintText: 'Şəhər, rayon...', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 16),

            // Phone
            _SectionTitle(title: 'Əlaqə nömrəsi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(hintText: '+994 XX XXX XX XX', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Toggles
            _ToggleRow(
              label: '⚡ Təcili xidmət',
              subtitle: 'Müştərinin fövqəladə ehtiyaclarına hazırsınız',
              value: _isUrgent,
              onChanged: (v) => setState(() => _isUrgent = v),
            ),
            const SizedBox(height: 8),
            _ToggleRow(
              label: '🏠 Evə gəlmə xidməti',
              subtitle: 'Müştərinin ünvanına gedə bilərsiniz',
              value: _homeService,
              onChanged: (v) => setState(() => _homeService = v),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Elanı dərc et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextSecondary));
  }
}

class _UploadedImage extends StatelessWidget {
  const _UploadedImage({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.subtitle, required this.value, required this.onChanged});
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? kPrimary.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? kPrimary.withOpacity(0.3) : Colors.transparent),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: kPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}
