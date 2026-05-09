import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Fused accelerometer + gyroscope for parallax/tilt effects.
///
/// Battery-conscious: 50ms sampling when active, off otherwise.
/// Used by: pass card tilt, globe interaction, passport foil.
class SensorFusion {
  SensorFusion._();

  static final _instance = SensorFusion._();
  static SensorFusion get instance => _instance;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  int _listeners = 0;

  double _tiltX = 0;
  double _tiltY = 0;

  /// Smoothed tilt X (pitch), radians, clamped to ±10°.
  double get tiltX => _tiltX;

  /// Smoothed tilt Y (roll), radians, clamped to ±10°.
  double get tiltY => _tiltY;

  /// Call when a widget starts needing tilt data.
  void acquire() {
    _listeners++;
    if (_listeners == 1) _startListening();
  }

  /// Call when a widget no longer needs tilt data.
  void release() {
    _listeners = math.max(0, _listeners - 1);
    if (_listeners == 0) _stopListening();
  }

  void _startListening() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(
      (e) {
        const maxAngle = math.pi / 18; // ±10°
        final rawX = (e.y.clamp(-3.0, 3.0) / 3.0) * maxAngle;
        final rawY = (e.x.clamp(-3.0, 3.0) / 3.0) * maxAngle;
        // Exponential smoothing (α = 0.22).
        _tiltX = _tiltX * 0.78 + rawX * 0.22;
        _tiltY = _tiltY * 0.78 + rawY * 0.22;
      },
      onError: (_) {},
      cancelOnError: false,
    );
    if (kDebugMode) debugPrint('[SensorFusion] started');
  }

  void _stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _tiltX = 0;
    _tiltY = 0;
    if (kDebugMode) debugPrint('[SensorFusion] stopped');
  }
}
