import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// GLOBEID SPRING PHYSICS ENGINE
//
// Every motion in GlobeID obeys physical law. This file is the single
// source of truth for all spring descriptions, simulation helpers,
// and physics-driven animation controllers used across the app.
//
// Zero Duration constants for interactive motion — springs define feel.
// ═══════════════════════════════════════════════════════════════════════

/// Canonical spring descriptions for every interaction class.
///
/// Usage:
/// ```dart
/// final ctrl = AnimationController(vsync: this);
/// ctrl.animateWith(GlobeSpring.card.toSimulation(from: 0, to: 1));
/// ```
class GlobeSpring {
  GlobeSpring._();

  // ── Interactive surfaces ──────────────────────────────────────────
  /// Cards, tiles, expandable panels — responsive but not jarring.
  static const card = SpringDescription(mass: 0.8, stiffness: 320, damping: 28);

  /// Bottom sheets, modals — heavier feel, controlled settle.
  static const sheet = SpringDescription(mass: 0.5, stiffness: 400, damping: 34);

  /// Micro-feedback: toggles, chips, icon pops — snappy.
  static const micro = SpringDescription(mass: 0.3, stiffness: 500, damping: 22);

  /// Page transitions — weighty, cinematic.
  static const page = SpringDescription(mass: 1.0, stiffness: 260, damping: 30);

  /// Settle after fling — heavy deceleration.
  static const settle = SpringDescription(mass: 1.2, stiffness: 180, damping: 36);

  /// Bouncy celebration — tier upgrades, achievements.
  static const bounce = SpringDescription(mass: 0.6, stiffness: 280, damping: 16);

  /// Gentle float — ambient particles, breathing elements.
  static const gentle = SpringDescription(mass: 1.5, stiffness: 80, damping: 14);

  /// Magnetic snap — card dock, nav indicator.
  static const magnetic = SpringDescription(mass: 0.4, stiffness: 600, damping: 30);

  /// Quick dismiss — swipe away, close.
  static const dismiss = SpringDescription(mass: 0.3, stiffness: 450, damping: 26);

  /// Elastic — pull-to-refresh, overscroll.
  static const elastic = SpringDescription(mass: 0.7, stiffness: 220, damping: 12);
}

/// Extension to create a [SpringSimulation] from a [SpringDescription].
extension SpringDescriptionX on SpringDescription {
  /// Create a simulation from [from] to [to] with optional initial [velocity].
  SpringSimulation toSimulation({
    double from = 0.0,
    double to = 1.0,
    double velocity = 0.0,
  }) {
    return SpringSimulation(this, from, to, velocity);
  }

  /// Estimated duration for this spring to settle within [tolerance].
  /// Useful for scheduling follow-up work after a spring completes.
  Duration estimatedDuration({double tolerance = 0.001}) {
    // Approximation using damping ratio
    final omega = stiffness / mass;
    final zeta = damping / (2 * mass * omega);
    final settleTime = zeta > 0 ? (-1 / (zeta * omega)) * (tolerance).abs() : 1.0;
    final ms = (settleTime.abs() * 1000).clamp(100, 2000).toInt();
    return Duration(milliseconds: ms);
  }
}

/// A controller that drives animations with spring physics.
///
/// Drop-in upgrade for [AnimationController] when you want physics-based
/// motion instead of duration-based tweening.
///
/// ```dart
/// final spring = SpringAnimationController(
///   spring: GlobeSpring.card,
///   vsync: this,
/// );
/// spring.forward(); // Animates 0→1 with spring physics
/// spring.reverse(); // Animates 1→0 with spring physics
/// ```
class SpringAnimationController extends AnimationController {
  SpringAnimationController({
    required this.spring,
    required super.vsync,
    super.value,
    super.lowerBound,
    super.upperBound,
  }) : super(duration: const Duration(milliseconds: 600));

  final SpringDescription spring;

  /// Animate forward using spring physics.
  @override
  TickerFuture forward({double? from}) {
    if (from != null) value = from;
    return animateWith(spring.toSimulation(
      from: value,
      to: upperBound,
      velocity: 0,
    ));
  }

  /// Animate in reverse using spring physics.
  @override
  TickerFuture reverse({double? from}) {
    if (from != null) value = from;
    return animateWith(spring.toSimulation(
      from: value,
      to: lowerBound,
      velocity: 0,
    ));
  }

  /// Animate to a specific [target] with optional initial [velocity].
  TickerFuture springTo(double target, {double velocity = 0.0}) {
    return animateWith(spring.toSimulation(
      from: value,
      to: target,
      velocity: velocity,
    ));
  }

  /// Fling with the given [velocity], settling at nearest bound.
  TickerFuture fling({double velocity = 1.0}) {
    final target = velocity > 0 ? upperBound : lowerBound;
    return animateWith(spring.toSimulation(
      from: value,
      to: target,
      velocity: velocity,
    ));
  }
}

/// A widget that applies spring-driven entrance animation to its child.
///
/// Replaces manual AnimationController + CurvedAnimation boilerplate.
/// The child slides up, fades in, and slightly scales — all with spring physics.
class SpringEntrance extends StatefulWidget {
  const SpringEntrance({
    super.key,
    required this.child,
    this.spring = GlobeSpring.card,
    this.delay = Duration.zero,
    this.slideOffset = 16.0,
    this.scaleFrom = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final SpringDescription spring;
  final Duration delay;
  final double slideOffset;
  final double scaleFrom;
  final bool enabled;

  @override
  State<SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<SpringEntrance>
    with SingleTickerProviderStateMixin {
  late final SpringAnimationController _ctrl;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = SpringAnimationController(
      spring: widget.spring,
      vsync: this,
      value: widget.enabled ? 0.0 : 1.0,
    );
    if (widget.enabled) {
      if (widget.delay == Duration.zero) {
        _start();
      } else {
        Future.delayed(widget.delay, _start);
      }
    }
  }

  void _start() {
    if (!mounted || _started) return;
    _started = true;
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = _ctrl.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.slideOffset),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A widget that applies spring physics to a value change.
///
/// When [value] changes, the animation springs from old → new.
class SpringValue extends StatefulWidget {
  const SpringValue({
    super.key,
    required this.value,
    required this.builder,
    this.spring = GlobeSpring.micro,
  });

  final double value;
  final Widget Function(BuildContext context, double animatedValue) builder;
  final SpringDescription spring;

  @override
  State<SpringValue> createState() => _SpringValueState();
}

class _SpringValueState extends State<SpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
    _ctrl = AnimationController.unbounded(
      vsync: this,
      value: widget.value,
    );
  }

  @override
  void didUpdateWidget(SpringValue old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.animateWith(widget.spring.toSimulation(
        from: _ctrl.value,
        to: widget.value,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => widget.builder(ctx, _ctrl.value),
    );
  }
}

/// Staggered spring entrance for a list of children.
///
/// Each child animates in with a delay offset, creating a cascade effect.
class SpringStagger extends StatelessWidget {
  const SpringStagger({
    super.key,
    required this.children,
    this.spring = GlobeSpring.card,
    this.staggerDelay = const Duration(milliseconds: 40),
    this.slideOffset = 16.0,
  });

  final List<Widget> children;
  final SpringDescription spring;
  final Duration staggerDelay;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          SpringEntrance(
            spring: spring,
            delay: staggerDelay * i,
            slideOffset: slideOffset,
            child: children[i],
          ),
      ],
    );
  }
}
