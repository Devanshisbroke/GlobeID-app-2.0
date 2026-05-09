import 'package:flutter/material.dart';

import '../../core/sensor_fusion.dart';

/// Wraps a child in a gyroscope-driven pendulum motion.
///
/// Uses the shared [SensorFusion] singleton (reference-counted, off
/// when unused). The child translates and rotates by a small amount
/// proportional to phone tilt, with an idle parallax that lazily
/// settles when the user is still. Used by passport hero, identity
/// score badge, trophy stamps, and any other surface that benefits
/// from a "weighted" feel.
class SensorPendulum extends StatefulWidget {
  const SensorPendulum({
    super.key,
    required this.child,
    this.translation = 6.0,
    this.rotation = 0.025,
    this.weight = 1.0,
  });

  final Widget child;

  /// Maximum px the child translates in either axis.
  final double translation;

  /// Maximum radians the child rotates (Z).
  final double rotation;

  /// Weight multiplier — heavier objects swing less.
  final double weight;

  @override
  State<SensorPendulum> createState() => _SensorPendulumState();
}

class _SensorPendulumState extends State<SensorPendulum>
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
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) return widget.child;
    return AnimatedBuilder(
      animation: _ticker,
      builder: (_, child) {
        final sf = SensorFusion.instance;
        final w = widget.weight.clamp(0.1, 4.0);
        final tx = (sf.tiltY / 0.18).clamp(-1.0, 1.0) * widget.translation / w;
        final ty = (sf.tiltX / 0.18).clamp(-1.0, 1.0) * widget.translation / w;
        final rot = (sf.tiltY / 0.18).clamp(-1.0, 1.0) * widget.rotation / w;
        return Transform.translate(
          offset: Offset(tx, ty),
          child: Transform.rotate(
            angle: rot,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
