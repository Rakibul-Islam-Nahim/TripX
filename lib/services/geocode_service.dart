import 'dart:math' as math;

import '../core/district_coords.dart';

class Coordinate {
  final double latitude;
  final double longitude;

  const Coordinate({required this.latitude, required this.longitude});

  Map<String, double> toJson() => {'lat': latitude, 'lon': longitude};

  static Coordinate? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final lat = json['lat'];
    final lon = json['lon'];
    if (lat is num && lon is num) {
      return Coordinate(latitude: lat.toDouble(), longitude: lon.toDouble());
    }
    return null;
  }
}

class GeocodeService {
  GeocodeService();

  final Map<String, Coordinate> _memoryCache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    for (final entry in kDistrictCoords.entries) {
      final coord = Coordinate.fromJson(entry.value);
      if (coord != null) {
        _memoryCache[_normalizeKey(entry.key)] = coord;
      }
    }
    _loaded = true;
  }

  Future<Coordinate?> getCoordinatesForDistrict(String district) async {
    await _ensureLoaded();
    final key = _normalizeKey(district);
    return _memoryCache[key];
  }

  double distanceInKm(Coordinate a, Coordinate b) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h =
        _haversin(dLat) + _haversin(dLon) * (math.cos(lat1) * math.cos(lat2));
    final double clamped = h.clamp(0.0, 1.0).toDouble();
    final double centralAngle = 2 * _asinSafe(math.sqrt(clamped));
    return earthRadiusKm * centralAngle;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  double _haversin(double rad) {
    final sinHalf = math.sin(rad / 2);
    return sinHalf * sinHalf;
  }

  double _asinSafe(double value) =>
      value >= 1 ? 1.5707963267948966 : math.asin(value);

  String _normalizeKey(String value) => value.trim().toLowerCase();
}
