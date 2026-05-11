import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Magnetic press wrapper.
///
/// Any interactive surface in OS 2.0 wraps in this to inherit:
///   • a critically-damped scale-down on press (1.0 → 0.97, spring back);
///   • a soft selection haptic on press-in;
///   • a heavier light-impact haptic on commit;
///   • a hover lift on desktop / web for parity;
///   • a 220ms tap-flash that "lights up" the slab without obscuring it.
///
/// Wrap any tappable surface — slabs, chips, dock pills, hero CTAs.
class Os2Magnetic extends StatefulWidget {
  const Os2Magnetic({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.disabled = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool disabled;

  @override
  State<Os2Magnetic> createState() => _Os2MagneticState();
}

class _Os2MagneticState extends State<Os2Magnetic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
    duration: Os2.mFlick,
  );
  bool _hover = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.disabled) return;
    HapticFeedback.selectionClick();
    _c.forward();
  }

  void _up(_) {
    if (widget.disabled) return;
    _c.reverse();
  }

  void _cancel() {
    if (widget.disabled) return;
    _c.reverse();
  }

  void _commit() {
    if (widget.disabled) return;
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        onTap: _commit,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!.call();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Os2.cTakeoff.transform(_c.value);
            final scale = 1.0 - (1.0 - widget.pressedScale) * t;
            final lift = _hover ? -1.5 : 0.0;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(scale, scale, 1.0, 1.0)
                ..translateByDouble(0.0, lift, 0.0, 1.0),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
