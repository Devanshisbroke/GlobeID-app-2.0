import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../core/sensor_fusion.dart';

/// Holographic foil effect driven by device accelerometer.
///
/// Creates a spectral interference pattern that shifts based on
/// device tilt — used on passport book covers, premium badges,
/// boarding passes, and membership cards.
///
/// Battery-conscious: acquires sensor data via [SensorFusion],
/// which uses reference counting to auto-stop when unused.
class HolographicFoil extends StatefulWidget {
  const HolographicFoil({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.borderRadius,
  });

  final Widget child;
  final double intensity;
  final BorderRadius? borderRadius;

  @override
  State<HolographicFoil> createState() => _HolographicFoilState();
}

class _HolographicFoilState extends State<HolographicFoil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (_, child) {
        final sf = SensorFusion.instance;
        return ClipRRect(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppTokens.radiusLg),
          child: CustomPaint(
            foregroundPainter: _HolographicPainter(
              tiltX: sf.tiltX,
              tiltY: sf.tiltY,
              intensity: widget.intensity,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _HolographicPainter extends CustomPainter {
  _HolographicPainter({
    required this.tiltX,
    required this.tiltY,
    required this.intensity,
  });

  final double tiltX;
  final double tiltY;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    // Map tilt to gradient position
    final cx = 0.5 + (tiltY / (math.pi / 18)) * 0.5;
    final cy = 0.5 + (tiltX / (math.pi / 18)) * 0.5;

    // Spectral interference — rainbow gradient that shifts with tilt
    final shader = LinearGradient(
      begin: Alignment(cx * 2 - 1, cy * 2 - 1),
      end: Alignment(-(cx * 2 - 1), -(cy * 2 - 1)),
      colors: [
        Color.fromRGBO(255, 0, 128, 0.12 * intensity),
        Color.fromRGBO(255, 165, 0, 0.10 * intensity),
        Color.fromRGBO(255, 255, 0, 0.08 * intensity),
        Color.fromRGBO(0, 255, 128, 0.10 * intensity),
        Color.fromRGBO(0, 128, 255, 0.12 * intensity),
        Color.fromRGBO(128, 0, 255, 0.10 * intensity),
        Color.fromRGBO(255, 0, 128, 0.12 * intensity),
      ],
      stops: const [0.0, 0.17, 0.33, 0.50, 0.67, 0.83, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.screen;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Secondary hot-spot highlight that follows tilt
    final spotPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(cx * 2 - 1, cy * 2 - 1),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: 0.18 * intensity),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      spotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HolographicPainter old) =>
      old.tiltX != tiltX || old.tiltY != tiltY || old.intensity != intensity;
}

/// Shimmer effect for boarding passes — a sweeping white band
/// that moves across the surface based on device tilt.
class TiltShimmer extends StatefulWidget {
  const TiltShimmer({
    super.key,
    required this.child,
    this.intensity = 0.6,
    this.borderRadius,
  });

  final Widget child;
  final double intensity;
  final BorderRadius? borderRadius;

  @override
  State<TiltShimmer> createState() => _TiltShimmerState();
}

class _TiltShimmerState extends State<TiltShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (_, child) {
        final sf = SensorFusion.instance;
        final normalizedTilt =
            (sf.tiltY / (math.pi / 18)).clamp(-1.0, 1.0);
        return ClipRRect(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppTokens.radiusLg),
          child: CustomPaint(
            foregroundPainter: _ShimmerPainter(
              position: normalizedTilt,
              intensity: widget.intensity,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.position, required this.intensity});
  final double position;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final bandCenter = (position + 1) / 2; // 0..1
    final bandWidth = 0.15;
    final start = bandCenter - bandWidth;
    final end = bandCenter + bandWidth;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.22 * intensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: [
          start.clamp(0.0, 1.0),
          bandCenter.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.position != position || old.intensity != intensity;
}

/// Depth-reactive card — applies subtle 3D rotation based on device tilt.
/// Creates a "magnetic depth" effect for premium cards.
class DepthCard extends StatefulWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.maxRotation = 6.0, // degrees
    this.perspective = 0.003,
    this.borderRadius,
    this.elevation = 8.0,
  });

  final Widget child;
  final double maxRotation;
  final double perspective;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (_, child) {
        final sf = SensorFusion.instance;
        final maxRad = widget.maxRotation * math.pi / 180;
        final rotX = (sf.tiltX).clamp(-maxRad, maxRad);
        final rotY = (sf.tiltY).clamp(-maxRad, maxRad);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, widget.perspective)
            ..rotateX(-rotX)
            ..rotateY(rotY),
          alignment: FractionalOffset.center,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(AppTokens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: widget.elevation + (rotX.abs() + rotY.abs()) * 20,
                  offset: Offset(rotY * -10, rotX * 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
