import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';

/// A press affordance with magnetic touch attraction.
///
/// While the finger is down on the child, the surface is pulled
/// toward the touch point on a spring (decay-bounded) and tilts
/// in 3D to follow the finger. Releasing the finger animates the
/// child back to rest with a soft overshoot. This is the founda-
/// tion for premium CTAs, hero cards, and any large interactive
/// surface that should feel "alive" under the finger.
///
/// Built on top of the existing [Pressable] semantics — same haptic
/// vocabulary (`HapticPatterns.tap` on tap, no haptic during drag).
/// All motion clamps to small values so it never feels exaggerated.
class MagneticPressable extends StatefulWidget {
  const MagneticPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.magnetism = 8.0,
    this.tilt = 0.04,
    this.scale = 0.985,
    this.duration = AppTokens.durationSm,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;

  /// Maximum offset (px) the surface drifts toward the touch.
  final double magnetism;

  /// Maximum 3D rotation (radians) toward the touch.
  final double tilt;

  /// Resting press-scale floor (1.0 = no scale).
  final double scale;

  /// Time the rest spring takes to settle on release.
  final Duration duration;

  final HitTestBehavior behavior;

  @override
  State<MagneticPressable> createState() => _MagneticPressableState();
}

class _MagneticPressableState extends State<MagneticPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: AppTokens.durationXs,
  );
  Offset? _local;
  Size _size = Size.zero;
  bool _down = false;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSize(Size s) {
    if (s != _size) _size = s;
  }

  void _onDown(Offset local) {
    setState(() {
      _down = true;
      _local = local;
    });
    _settle.forward();
  }

  void _onMove(Offset local) {
    if (!_down) return;
    setState(() => _local = local);
  }

  void _release({bool fired = false}) {
    if (!_down) return;
    setState(() {
      _down = false;
      _local = null;
    });
    _settle.reverse();
    if (fired && widget.haptic) {
      HapticPatterns.tap.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(
      builder: (_, c) {
        _onSize(Size(c.maxWidth, c.maxHeight));
        return Listener(
          behavior: widget.behavior,
          onPointerDown: (e) {
            if (widget.onTap == null && widget.onLongPress == null) return;
            _onDown(_localOf(e.position, context));
          },
          onPointerMove: (e) => _onMove(_localOf(e.position, context)),
          onPointerCancel: (_) => _release(),
          onPointerUp: (_) {
            final fired = _down;
            _release(fired: fired);
            if (fired) widget.onTap?.call();
          },
          child: GestureDetector(
            behavior: widget.behavior,
            onLongPress: widget.onLongPress == null
                ? null
                : () {
                    if (widget.haptic) HapticFeedback.mediumImpact();
                    widget.onLongPress!();
                  },
            child: AnimatedBuilder(
              animation: _settle,
              builder: (_, child) {
                if (reduce) return child!;
                final t = _settle.value;
                final cx = _size.width / 2;
                final cy = _size.height / 2;
                final dx = _local == null ? 0.0 : _local!.dx - cx;
                final dy = _local == null ? 0.0 : _local!.dy - cy;
                final nx = (dx / cx).clamp(-1.0, 1.0);
                final ny = (dy / cy).clamp(-1.0, 1.0);
                final translate = Offset(
                  nx * widget.magnetism * t,
                  ny * widget.magnetism * t,
                );
                final scale = 1.0 - (1.0 - widget.scale) * t;
                final m = Matrix4.identity()
                  ..setEntry(3, 2, 0.0009)
                  ..rotateX(-ny * widget.tilt * t)
                  ..rotateY(nx * widget.tilt * t)
                  ..translateByDouble(translate.dx, translate.dy, 0.0, 1.0)
                  ..scaleByDouble(scale, scale, 1.0, 1.0);
                return Transform(
                  transform: m,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  Offset _localOf(Offset global, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.globalToLocal(global);
  }
}
