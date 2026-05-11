import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Wrap [child] with a touch-driven 3D tilt — used by hero cards
/// (boarding pass, identity card). Pure GestureDetector + Matrix4
/// transform; no platform channels.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxAngle = 0.10,
    this.scaleOnPress = 0.985,
  });

  final Widget child;

  /// Max tilt in radians. ~0.10 reads as "premium". Anything above
  /// 0.18 starts to feel arcade.
  final double maxAngle;
  final double scaleOnPress;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _delta = Offset.zero;
  bool _pressed = false;

  void _update(Offset local, Size size) {
    final dx = (local.dx / size.width).clamp(0.0, 1.0) * 2 - 1;
    final dy = (local.dy / size.height).clamp(0.0, 1.0) * 2 - 1;
    setState(() => _delta = Offset(dx, dy));
  }

  void _reset() => setState(() => _delta = Offset.zero);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final angleY = _delta.dx * widget.maxAngle;
      final angleX = -_delta.dy * widget.maxAngle;

      final s = _pressed ? widget.scaleOnPress : 1.0;
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0009)
        ..rotateX(angleX)
        ..rotateY(angleY)
        ..scaleByDouble(s, s, s, 1.0);

      return GestureDetector(
        onPanStart: (d) {
          setState(() => _pressed = true);
          _update(d.localPosition, size);
        },
        onPanUpdate: (d) => _update(d.localPosition, size),
        onPanEnd: (_) {
          setState(() => _pressed = false);
          _reset();
        },
        onPanCancel: () {
          setState(() => _pressed = false);
          _reset();
        },
        child: AnimatedContainer(
          duration: AppTokens.durationSm,
          curve: AppTokens.easeOutSoft,
          transform: m,
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      );
    });
  }
}

/// 3D tilt that *also* responds to a small parallax drift even when
/// idle — used in hero panels to keep them alive.
class IdleDriftTilt extends StatefulWidget {
  const IdleDriftTilt({
    super.key,
    required this.child,
    this.amplitude = 0.04,
  });
  final Widget child;
  final double amplitude;

  @override
  State<IdleDriftTilt> createState() => _IdleDriftTiltState();
}

class _IdleDriftTiltState extends State<IdleDriftTilt>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (reduce) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, c) {
        final t = _ctrl.value * 2 * math.pi;
        final dx = math.cos(t) * widget.amplitude;
        final dy = math.sin(t) * widget.amplitude * 0.6;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0009)
          ..rotateY(dx)
          ..rotateX(-dy);
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: c,
        );
      },
      child: widget.child,
    );
  }
}
