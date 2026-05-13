// GlobeID Refinement — physics-based press wrapper.
//
// Adds the iOS / SwiftUI press feel to any hero CTA: pressing the
// surface drives a SpringSimulation that scales it down, and on
// release the spring overshoots back to 1.0 with the configured
// damping. Unlike a fixed-duration tween (Os2Magnetic), a real
// spring responds to interruption gracefully — release mid-press
// and the simulation picks up the current scale + velocity and
// settles from there.
//
// Use this on the highest-stake interactive surfaces:
//   • Wallet treasury hero
//   • Identity passport hero
//   • Boarding pass primary action
//   • Lock screen unlock zone
//
// Less-stake surfaces (chips, list rows) continue to use the
// cheaper Os2Magnetic curve-driven press.

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'motion_tokens.dart';

/// Spring-driven press wrapper for hero CTAs.
///
/// Wraps [child] with a [GestureDetector] that drives a [Animation]
/// from a [SpringSimulation] based on [SpringSpec]. The scale moves
/// from 1.0 to `pressedScale` on tap-down and back to 1.0 on commit
/// or cancel — interruptible at any time.
class SpringPress extends StatefulWidget {
  const SpringPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.spec = Motion.sHero,
    this.haptic = true,
    this.disabled = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale the surface settles to on tap-down. iOS hero defaults to
  /// 0.96; smaller widgets can use 0.94 for a more decisive feel.
  final double pressedScale;

  /// Spring spec controlling how fast / bouncy the scale settles.
  /// Defaults to [Motion.sHero] (slower, more material).
  final SpringSpec spec;

  /// Whether to fire selection / commit haptics. On by default.
  final bool haptic;

  /// Whether the surface is interactive. When false, taps are
  /// ignored and the press animation is skipped.
  final bool disabled;

  /// Optional accessibility label exposed to screen readers.
  final String? semanticLabel;

  @override
  State<SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<SpringPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
    value: 1.0,
  );

  void _animateTo(double target) {
    final sim = SpringSimulation(
      widget.spec.description,
      _ctrl.value,
      target,
      _ctrl.velocity,
    );
    _ctrl.animateWith(sim);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.disabled) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    _animateTo(widget.pressedScale);
  }

  void _up(TapUpDetails _) {
    if (widget.disabled) return;
    _animateTo(1.0);
  }

  void _cancel() {
    if (widget.disabled) return;
    _animateTo(1.0);
  }

  void _commit() {
    if (widget.disabled) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _longPress() {
    if (widget.disabled) return;
    if (widget.haptic) HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tree = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: _commit,
      onLongPress: widget.onLongPress == null ? null : _longPress,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, c) => Transform.scale(
          scale: _ctrl.value,
          child: c,
        ),
        child: widget.child,
      ),
    );
    final label = widget.semanticLabel;
    if (label == null || label.isEmpty) return tree;
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: label,
      child: tree,
    );
  }
}
