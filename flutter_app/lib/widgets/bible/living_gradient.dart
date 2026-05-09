// Living-gradient background.
//
// The bible (§4.1): "Backgrounds are never flat. Every surface uses
// a 4-stop gradient with one slowly-animated stop, so the screen
// breathes. The animation period is 30–90 seconds — too slow to be
// noticed consciously, but fast enough that a returning glance feels
// different."
//
// LivingGradient runs a single 60 s sine-modulated drift on the
// gradient's center alignment. It honors disableAnimations.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme/ux_bible.dart';

class LivingGradient extends StatefulWidget {
  /// The four colors that compose the gradient — bible recommends
  /// substrate → tone-lit substrate → substrate → tone-lit substrate.
  final List<Color> colors;

  /// Period of the slow drift. Default 60 s (in the bible's 30–90 s
  /// range).
  final Duration period;

  /// Optional child rendered on top of the gradient.
  final Widget? child;

  const LivingGradient({
    super.key,
    required this.colors,
    this.period = const Duration(seconds: 60),
    this.child,
  });

  /// Convenience: a globe-flavored substrate gradient — midnight
  /// indigo with a polar-blue tone bloom.
  factory LivingGradient.globe({Widget? child}) => LivingGradient(
        colors: const [
          BibleSubstrate.midnightIndigo,
          Color(0xFF0A1A2E),
          BibleSubstrate.midnightIndigo,
          Color(0xFF0F2340),
        ],
        child: child,
      );

  /// Identity-flavored substrate — vellum bone with foil-gold bloom.
  factory LivingGradient.identity({Widget? child}) => LivingGradient(
        colors: [
          BibleSubstrate.vellumBone,
          BibleTone.foilGold.withValues(alpha: 0.18),
          BibleSubstrate.vellumBone,
          BibleTone.diplomaticGarnet.withValues(alpha: 0.10),
        ],
        child: child,
      );

  /// Wallet-flavored substrate — cabin charcoal with treasury-green
  /// bloom.
  factory LivingGradient.wallet({Widget? child}) => LivingGradient(
        colors: [
          BibleSubstrate.cabinCharcoal,
          BibleTone.treasuryGreen.withValues(alpha: 0.18),
          BibleSubstrate.cabinCharcoal,
          BibleTone.mintGlass.withValues(alpha: 0.12),
        ],
        child: child,
      );

  /// Travel-flavored substrate — tarmac slate with jet-cyan +
  /// runway-amber double-bloom. Designed to *underlay* a screen,
  /// not dominate it: each tone is held under 12 % alpha and the
  /// substrate dominates the gradient stops.
  factory LivingGradient.travel({Widget? child}) => LivingGradient(
        colors: [
          BibleTone.jetCyan.withValues(alpha: 0.08),
          BibleSubstrate.tarmacSlate.withValues(alpha: 0.0),
          BibleSubstrate.tarmacSlate.withValues(alpha: 0.0),
          BibleTone.runwayAmber.withValues(alpha: 0.04),
        ],
        child: child,
      );

  @override
  State<LivingGradient> createState() => _LivingGradientState();
}

class _LivingGradientState extends State<LivingGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = reduce ? 0.0 : _ctrl.value;
        final theta = t * 2 * math.pi;
        final cx = math.cos(theta) * 0.35;
        final cy = math.sin(theta) * 0.25;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(cx, cy),
              radius: 1.4,
              colors: widget.colors,
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
