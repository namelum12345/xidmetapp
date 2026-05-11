import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_primary_button.dart';

/// Android/iOS üçün Google Maps; Web/Linux/Desktop üçün OSM ([FlutterMap]).
///
/// Mobil üçün **Google Cloud Console**-dan Maps SDK API açarı əlavə edin:
/// - Android: `AndroidManifest.xml` → `com.google.android.geo.API_KEY`
/// - iOS: `Info.plist` → `GMSApiKey`
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    required this.initial,
  });

  final LatLng initial;

  static bool get _useGoogleMaps =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _pin;
  final MapController _osmController = MapController();
  gmaps.GoogleMapController? _googleController;
  final _loc = const LocationService();
  var _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  void dispose() {
    _osmController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentGps() async {
    setState(() => _gpsLoading = true);
    try {
      final ll = await _loc.currentLatLng();
      if (!mounted) return;
      if (ll == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS mövqesi alınmadı — icazəni yoxlayın'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _pin = ll);
      if (MapPickerScreen._useGoogleMaps && _googleController != null) {
        await _googleController!.animateCamera(
          gmaps.CameraUpdate.newLatLng(
            gmaps.LatLng(ll.latitude, ll.longitude),
          ),
        );
      } else {
        _osmController.move(ll, 15);
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          MapPickerScreen._useGoogleMaps
              ? 'Google Xəritədə seç'
              : 'Xəritədə seç (OSM)',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Mövqeyim',
            onPressed: _gpsLoading ? null : _useCurrentGps,
            icon: _gpsLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapPickerScreen._useGoogleMaps
                ? _GooglePickerBody(
                    pin: _pin,
                    onMoved: (ll) => setState(() => _pin = ll),
                    onControllerReady: (c) => _googleController = c,
                  )
                : _OsmPickerBody(
                    pin: _pin,
                    controller: _osmController,
                    initialCenter: widget.initial,
                    onMoved: (ll) => setState(() => _pin = ll),
                  ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: GradientPrimaryButton(
              label: 'Bu nöqtəni təsdiqlə',
              onPressed: () => Navigator.of(context).pop<LatLng>(_pin),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmPickerBody extends StatelessWidget {
  const _OsmPickerBody({
    required this.pin,
    required this.controller,
    required this.initialCenter,
    required this.onMoved,
  });

  final LatLng pin;
  final MapController controller;
  final LatLng initialCenter;
  final ValueChanged<LatLng> onMoved;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14,
        onTap: (_, point) => onMoved(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'az.qonsudan.xidmet',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: pin,
              width: 44,
              height: 44,
              alignment: Alignment.bottomCenter,
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 44,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GooglePickerBody extends StatefulWidget {
  const _GooglePickerBody({
    required this.pin,
    required this.onMoved,
    required this.onControllerReady,
  });

  final LatLng pin;
  final ValueChanged<LatLng> onMoved;
  final ValueChanged<gmaps.GoogleMapController> onControllerReady;

  @override
  State<_GooglePickerBody> createState() => _GooglePickerBodyState();
}

class _GooglePickerBodyState extends State<_GooglePickerBody> {
  static const _markerId = gmaps.MarkerId('pick');

  @override
  Widget build(BuildContext context) {
    final target = gmaps.LatLng(widget.pin.latitude, widget.pin.longitude);
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(target: target, zoom: 14),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      markers: {
        gmaps.Marker(
          markerId: _markerId,
          position: target,
          draggable: true,
          onDragEnd: (p) => widget.onMoved(LatLng(p.latitude, p.longitude)),
        ),
      },
      onTap: (p) => widget.onMoved(LatLng(p.latitude, p.longitude)),
      onMapCreated: widget.onControllerReady,
    );
  }
}
