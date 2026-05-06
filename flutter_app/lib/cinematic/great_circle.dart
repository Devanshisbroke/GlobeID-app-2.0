import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:vector_math/vector_math_64.dart';

/// Pure math helpers for great-circle interpolation, spherical
/// projection, and arc parametrisation. Re-used by the cinematic
/// globe renderer and the trip-glance polylines.
class GreatCircle {
  GreatCircle._();

  static const double earthRadiusKm = 6371.0;

  /// Convert (lat, lng) in degrees to a unit vector on the sphere.
  static Vector3 toCartesian(double latDeg, double lngDeg) {
    final lat = _deg2rad(latDeg);
    final lng = _deg2rad(lngDeg);
    return Vector3(
      math.cos(lat) * math.cos(lng),
      math.sin(lat),
      math.cos(lat) * math.sin(lng),
    );
  }

  /// Spherical linear interpolation between two unit vectors.
  static Vector3 slerp(Vector3 a, Vector3 b, double t) {
    final dot = a.dot(b).clamp(-1.0, 1.0);
    final omega = math.acos(dot);
    if (omega.abs() < 1e-6) return a.clone();
    final sinOmega = math.sin(omega);
    final s1 = math.sin((1 - t) * omega) / sinOmega;
    final s2 = math.sin(t * omega) / sinOmega;
    return (a * s1) + (b * s2);
  }

  /// Sample [count] points along the great-circle arc between (latA, lngA)
  /// and (latB, lngB).
  static List<Vector3> samplePoints({
    required double latA,
    required double lngA,
    required double latB,
    required double lngB,
    int count = 64,
    double altitudeBoost = 0.10,
  }) {
    final a = toCartesian(latA, lngA);
    final b = toCartesian(latB, lngB);
    final pts = <Vector3>[];
    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final p = slerp(a, b, t);
      // Inflate the midpoint outward to give the arc altitude.
      final lift = math.sin(t * math.pi) * altitudeBoost;
      p.scale(1 + lift);
      pts.add(p);
    }
    return pts;
  }

  /// Distance between two (lat, lng) points in km, via the
  /// haversine formula. Used for trip stat readouts.
  static double haversineKm({
    required double latA,
    required double lngA,
    required double latB,
    required double lngB,
  }) {
    final dLat = _deg2rad(latB - latA);
    final dLng = _deg2rad(lngB - lngA);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_deg2rad(latA)) *
            math.cos(_deg2rad(latB)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  /// Initial bearing in degrees (0..360) from A to B.
  static double bearingDegrees({
    required double latA,
    required double lngA,
    required double latB,
    required double lngB,
  }) {
    final aLat = _deg2rad(latA);
    final bLat = _deg2rad(latB);
    final dLng = _deg2rad(lngB - lngA);
    final y = math.sin(dLng) * math.cos(bLat);
    final x = math.cos(aLat) * math.sin(bLat) -
        math.sin(aLat) * math.cos(bLat) * math.cos(dLng);
    final brng = math.atan2(y, x);
    return ((brng * 180 / math.pi) + 360) % 360;
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
}

/// 3D camera + projection for the cinematic globe — small wrapper
/// around vector_math's Matrix4 to keep painter code readable.
class GlobeCamera {
  GlobeCamera({
    required this.size,
    required this.rotationY,
    required this.rotationX,
    this.tiltZ = 0.0,
    this.fov = 1.4,
  });

  final double size;
  final double rotationY;
  final double rotationX;
  final double tiltZ;
  final double fov;

  /// Apply the camera rotation to a unit-sphere point.
  Vector3 apply(Vector3 p) {
    final m = Matrix4.identity()
      ..rotateY(rotationY)
      ..rotateX(rotationX)
      ..rotateZ(tiltZ);
    return m.transformed3(p);
  }

  /// Project a rotated point onto the canvas using a simple
  /// perspective divide. Returns the (offset, depth, visible).
  (Offset, double, bool) project(Vector3 rotated) {
    // z<0 means behind the sphere from the viewer (looking down -Z).
    final visible = rotated.z >= -0.01;
    final x = rotated.x * size * 0.5;
    final y = -rotated.y * size * 0.5;
    return (Offset(x, y), rotated.z, visible);
  }
}
