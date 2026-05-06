import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Curated motion tokens for cinematic feel — modeled after Apple's
/// system spring presets and Linear's signature motion. Use these
/// instead of hand-rolling Curves so timing stays consistent across
/// the entire app.
class Motion {
  Motion._();

  /// Fast, lossy. Great for tap rebound.
  static const Duration fast = Duration(milliseconds: 180);

  /// Default UI motion duration.
  static const Duration standard = Duration(milliseconds: 320);

  /// Cinematic, high-perceived-quality. Use for hero transitions.
  static const Duration cinematic = Duration(milliseconds: 520);

  /// Long, ambient drift (atmosphere orbs, parallax glides).
  static const Duration ambient = Duration(milliseconds: 1200);

  /// `prefers-reduced-motion` aware duration scaling.
  static Duration reduce(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
          ? Duration.zero
          : d;

  /// Apple "spring.default" — snappy with a touch of overshoot.
  static const Curve springDefault = Cubic(0.3, 1.4, 0.45, 1);

  /// Snap — rapid attack, no overshoot. Used for nav/tab swaps.
  static const Curve snap = Cubic(0.35, 1, 0.4, 1);

  /// Cinematic ease — long entrance, soft settle.
  static const Curve cinematicEase = Cubic(0.16, 1, 0.3, 1);

  /// Quick out, soft in. Used for floating chrome.
  static const Curve floatIn = Cubic(0.12, 0.85, 0.25, 1);

  /// Pre-tuned spring physics for damped overshoot.
  static SpringDescription get springSnappy =>
      const SpringDescription(mass: 1, stiffness: 380, damping: 26);

  /// Pre-tuned spring physics for soft, premium drift.
  static SpringDescription get springSoft =>
      const SpringDescription(mass: 1, stiffness: 220, damping: 28);

  /// Pre-tuned spring physics for fluid hero motion.
  static SpringDescription get springHero =>
      const SpringDescription(mass: 1, stiffness: 160, damping: 22);
}

/// Run [child] through a `SpringSimulation`. Useful for letting a
/// rebounded element settle naturally instead of with a Curves.* exit.
class SpringTween extends StatefulWidget {
  const SpringTween({
    super.key,
    required this.value,
    required this.builder,
    this.spring,
  });

  final double value;
  final SpringDescription? spring;
  final Widget Function(BuildContext, double) builder;

  @override
  State<SpringTween> createState() => _SpringTweenState();
}

class _SpringTweenState extends State<SpringTween>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController.unbounded(vsync: this);
  late double _current = widget.value;

  @override
  void initState() {
    super.initState();
    _ctrl.value = _current;
    _ctrl.addListener(() {
      if (!mounted) return;
      setState(() => _current = _ctrl.value);
    });
  }

  @override
  void didUpdateWidget(covariant SpringTween old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _animateTo(widget.value);
  }

  void _animateTo(double target) {
    final sim = SpringSimulation(
      widget.spring ?? Motion.springSoft,
      _ctrl.value,
      target,
      0,
    );
    _ctrl.animateWith(sim);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _current);
}
