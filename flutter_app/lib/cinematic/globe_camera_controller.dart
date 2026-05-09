import 'dart:math' as math;

import 'package:flutter/material.dart';


/// Cinematic camera controller for the globe renderer.
///
/// Manages smooth transitions between orbital camera states:
///  • Auto-rotate (slow Cassini-style orbit on idle)
///  • Tap-to-focus (smooth arc to target city)
///  • User drag with momentum & spring snapback
///  • Idle detection (returns to auto-rotate after [idleTimeout])
class GlobeCameraController extends ChangeNotifier {
  GlobeCameraController({
    this.idleTimeout = const Duration(seconds: 8),
    double initialYaw = 0.0,
    double initialPitch = -0.18,
  })  : _yaw = initialYaw,
        _pitch = initialPitch,
        _targetYaw = initialYaw,
        _targetPitch = initialPitch;

  final Duration idleTimeout;

  // ── Current state ──────────────────────────────────────────────
  double _yaw;
  double _pitch;
  double _zoom = 1.0;

  // ── Animation targets ──────────────────────────────────────────
  double _targetYaw;
  double _targetPitch;
  double _targetZoom = 1.0;

  // ── Momentum from drag ─────────────────────────────────────────
  double _velocityYaw = 0;
  double _velocityPitch = 0;

  // ── Idle tracking ──────────────────────────────────────────────
  DateTime _lastInteraction = DateTime.now();
  bool _isAutoRotating = true;

  // ── Accessors ──────────────────────────────────────────────────
  double get yaw => _yaw;
  double get pitch => _pitch;
  double get zoom => _zoom;
  bool get isAutoRotating => _isAutoRotating;

  /// Smooth interpolation constant (0..1, higher = faster convergence).
  static const _smoothing = 0.08;
  static const _momentumDecay = 0.92;
  static const _autoRotateSpeed = 0.003; // radians per tick

  /// Called by the drag gesture handler. Records velocity for momentum.
  void onPanUpdate(double dx, double dy) {
    _velocityYaw = dx * 0.005;
    _velocityPitch = -dy * 0.005;
    _targetYaw += _velocityYaw;
    _targetPitch = (_targetPitch + _velocityPitch).clamp(-1.1, 1.1);
    _lastInteraction = DateTime.now();
    _isAutoRotating = false;
    notifyListeners();
  }

  /// Called when the user lifts their finger — momentum continues.
  void onPanEnd() {
    _lastInteraction = DateTime.now();
  }

  /// Smoothly fly the camera to look at a specific lat/lng.
  void flyTo({required double lat, required double lng, double? zoom}) {
    // Convert lat/lng to yaw/pitch
    _targetYaw = -lng * math.pi / 180;
    _targetPitch = (lat * math.pi / 180).clamp(-1.1, 1.1);
    if (zoom != null) _targetZoom = zoom.clamp(0.5, 3.0);
    _velocityYaw = 0;
    _velocityPitch = 0;
    _lastInteraction = DateTime.now();
    _isAutoRotating = false;
    notifyListeners();
  }

  /// Pinch-zoom handler.
  void onScaleUpdate(double scale) {
    _targetZoom = (_targetZoom * scale).clamp(0.5, 3.0);
    _lastInteraction = DateTime.now();
    _isAutoRotating = false;
    notifyListeners();
  }

  /// Reset to default orbital view.
  void resetView() {
    _targetYaw = 0;
    _targetPitch = -0.18;
    _targetZoom = 1.0;
    _velocityYaw = 0;
    _velocityPitch = 0;
    _isAutoRotating = true;
    notifyListeners();
  }

  /// Called every animation frame. Applies momentum, smoothing, and
  /// auto-rotate when idle.
  void tick() {
    // Idle detection
    final idleDuration = DateTime.now().difference(_lastInteraction);
    if (!_isAutoRotating && idleDuration > idleTimeout) {
      _isAutoRotating = true;
    }

    // Auto-rotate
    if (_isAutoRotating) {
      _targetYaw += _autoRotateSpeed;
      // Gentle cinematic pitch oscillation
      final t = DateTime.now().millisecondsSinceEpoch / 15000.0;
      _targetPitch = -0.18 + math.sin(t) * 0.045;
    }

    // Apply momentum decay
    _velocityYaw *= _momentumDecay;
    _velocityPitch *= _momentumDecay;

    // Apply residual momentum to target
    if (!_isAutoRotating) {
      _targetYaw += _velocityYaw * 0.5;
      _targetPitch =
          (_targetPitch + _velocityPitch * 0.5).clamp(-1.1, 1.1);
    }

    // Smooth interpolation toward target
    _yaw += (_targetYaw - _yaw) * _smoothing;
    _pitch += (_targetPitch - _pitch) * _smoothing;
    _zoom += (_targetZoom - _zoom) * _smoothing;

    notifyListeners();
  }
}
