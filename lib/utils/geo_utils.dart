import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Haversine distance in kilometers.
double distanceKmBetween(GeoPoint a, GeoPoint b) {
  const earthKm = 6371.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthKm * (2 * math.atan2(math.sqrt(h), math.sqrt(1 - h)));
}

double _rad(double d) => d * math.pi / 180.0;
