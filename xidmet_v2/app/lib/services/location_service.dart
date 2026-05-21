import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String address;

  const LocationResult({required this.lat, required this.lng, this.address = ''});
}

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// İcazə alıb cari mövqeyi qaytarır.
  /// Xəta olsa default Bakı koordinatlarını qaytarır.
  Future<LocationResult> getCurrentLocation() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) {
        return const LocationResult(lat: 40.4093, lng: 49.8671, address: 'Bakı');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return const LocationResult(lat: 40.4093, lng: 49.8671, address: 'Bakı');
    }
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Koordinat fərqindən km məsafəsi hesabla
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}
