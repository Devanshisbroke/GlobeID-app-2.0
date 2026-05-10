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

  /// Globe-flavored backdrop — polar-blue + equator-teal bloom.
  /// Designed to *underlay*, never dominate. Each tone is held
  /// under 9 % alpha so map content stays fully readable.
  factory LivingGradient.globe({Widget? child}) => LivingGradient(
        colors: [
          BibleTone.polarBlue.withValues(alpha: 0.09),
          BibleSubstrate.midnightIndigo.withValues(alpha: 0.0),
          BibleSubstrate.midnightIndigo.withValues(alpha: 0.0),
          BibleTone.equatorTeal.withValues(alpha: 0.05),
        ],
        child: child,
      );

  /// Identity-flavored backdrop — foil-gold + diplomatic-garnet
  /// double-bloom. Subtle museum-case warmth on top of the
  /// existing scaffold substrate.
  factory LivingGradient.identity({Widget? child}) => LivingGradient(
        colors: [
          BibleTone.foilGold.withValues(alpha: 0.08),
          BibleSubstrate.vellumBone.withValues(alpha: 0.0),
          BibleSubstrate.vellumBone.withValues(alpha: 0.0),
          BibleTone.diplomaticGarnet.withValues(alpha: 0.04),
        ],
        child: child,
      );

  /// Wallet-flavored backdrop — treasury-green + mint-glass
  /// double-bloom. Conveys vault-safe wealth without crowding
  /// numbers.
  factory LivingGradient.wallet({Widget? child}) => LivingGradient(
        colors: [
          BibleTone.treasuryGreen.withValues(alpha: 0.08),
          BibleSubstrate.cabinCharcoal.withValues(alpha: 0.0),
          BibleSubstrate.cabinCharcoal.withValues(alpha: 0.0),
          BibleTone.mintGlass.withValues(alpha: 0.04),
        ],
        child: child,
      );

  /// Travel-flavored backdrop — jet-cyan + runway-amber
  /// double-bloom. Designed to *underlay* a screen, not dominate
  /// it: each tone is held under 8 % alpha and the substrate
  /// dominates the gradient stops.
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
