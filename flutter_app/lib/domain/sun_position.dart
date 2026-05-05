import 'dart:math' as math;

/// Dart port of `src/lib/sunPosition.ts`. Approximates sub-solar lat/lng
/// for a given UTC time (NOAA solar-position algorithm, simplified).
class SunPosition {
  const SunPosition(this.lat, this.lng);
  final double lat;
  final double lng;
}

SunPosition subSolarPoint(DateTime utc) {
  final julianDay = utc.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  final n = julianDay - 2451545.0;
  final l = (280.460 + 0.9856474 * n) % 360;
  final g = ((357.528 + 0.9856003 * n) % 360) * math.pi / 180;
  final lambda =
      (l + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) * math.pi / 180;
  final epsilon = (23.439 - 0.0000004 * n) * math.pi / 180;
  final declination =
      math.asin(math.sin(epsilon) * math.sin(lambda)) * 180 / math.pi;
  final hourFraction =
      (utc.toUtc().hour * 3600 + utc.toUtc().minute * 60 + utc.toUtc().second) /
          86400.0;
  final lng = -180.0 + 360.0 * hourFraction;
  return SunPosition(declination, lng);
}
