// GlobeID Refinement — canonical motion tokens.
//
// Single source of truth for every duration, curve, spring response,
// and damping value used across the app. Replaces (without removing
// — backwards compatible) the parallel taxonomies in:
//
//   • `os2/os2_tokens.dart`         (Os2.m* / Os2.c*)
//   • `nexus/nexus_tokens.dart`     (N.d* / N.ease / N.easeIn / …)
//   • `app/theme/ux_bible.dart`     (BibleCurves / BibleChoreography)
//   • `motion/motion.dart`          (GlobeMotion.spring / pop / settle)
//
// Those four sets are kept for source-compat but are now thin aliases
// over [Motion]. Any new screen MUST source motion timings + curves
// from [Motion] only — the bible's rule, restated.
//
// The values here are Apple-tuned. The 80 / 160 / 220 / 280 / 320 /
// 360 / 420 / 620 ms ladder mirrors iOS' standard sheet / push / hero
// timing. Spring `response` + `damping` model the physical feel of
// CASpringAnimation (UIKit / SwiftUI's underlying spring), so a
// hero card press / release behaves like a real spring instead of a
// fixed-duration ease.

import 'package:flutter/animation.dart';

/// The canonical motion vocabulary.
///
/// Every transition, animation, and choreography in the app routes
/// through one of the values here. Anything else is, by the bible, a
/// regression.
class Motion {
  Motion._();

  // ── Durations ─────────────────────────────────────────────────────
  //
  // Each one corresponds to a specific *kind* of moment. Mixing them
  // is a smell; e.g. a sheet should always be `dSheet`, never `dPage`.

  /// Instant — for visual state syncs that should feel instantaneous
  /// (haptic mirror, status pill flip).
  static const Duration dInstant = Duration(milliseconds: 80);

  /// Tap / press feedback. The amount of time a magnetic press takes
  /// to settle to its pressed-state scale.
  static const Duration dTap = Duration(milliseconds: 160);

  /// Quick reverse — what an outgoing element does as a new one
  /// arrives. Front-loaded fade. Apple's default reverse timing.
  static const Duration dQuickReverse = Duration(milliseconds: 220);

  /// Modal in — used for blur-fade route presentations.
  static const Duration dModal = Duration(milliseconds: 280);

  /// Sheet present — slide-up modal, bottom sheet, drag handle ready.
  static const Duration dSheet = Duration(milliseconds: 320);

  /// Page push — the standard navigation transition.
  static const Duration dPage = Duration(milliseconds: 360);

  /// Cruise — neutral layout shifts (a card growing, a row settling).
  static const Duration dCruise = Duration(milliseconds: 420);

  /// Portal — long, hero-grade reveals (lock → unlocked, onboarding).
  static const Duration dPortal = Duration(milliseconds: 620);

  /// Breath slow — long sinus pulse for ambient halos.
  static const Duration dBreathSlow = Duration(milliseconds: 7400);

  /// Breath fast — short ambient pulse (status beacon, live ribbon).
  static const Duration dBreathFast = Duration(milliseconds: 2200);

  // ── Curves ────────────────────────────────────────────────────────
  //
  // Named after aircraft maneuvers, after the bible's metaphor. Use
  // [Motion.cStandard] as the default — it is Apple's ease-out-back-
  // soft, the curve that feels "right" at the end of 99 % of moments.

  /// Standard entrance — ease-out-back-soft. The default. Use this
  /// for any incoming element unless you have a specific reason to
  /// reach for [cEmphasized] / [cSpring] / etc.
  static const Curve cStandard = Cubic(0.16, 1.0, 0.30, 1.0);

  /// Emphasized — same family as cStandard but with a steeper start
  /// for moments that need to feel decisive (commit, dismiss).
  static const Curve cEmphasized = Cubic(0.65, 0.0, 0.35, 1.0);

  /// Spring — overshoots at end. Use for chip taps, beacon flips,
  /// micro-interactions where a little bounce reads as "alive".
  static const Curve cSpring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Exit — front-loaded ease-in. Used by the *outgoing* page during
  /// a push transition.
  static const Curve cExit = Cubic(0.55, 0.0, 1.0, 0.45);

  /// Settle — for layout collapse, drawer close, content recede.
  static const Curve cSettle = Cubic(0.33, 1.0, 0.68, 1.0);

  /// Linear — only for measured progress (CircularProgressIndicator,
  /// scroll-driven offsets). Never for state changes.
  static const Curve cLinear = Curves.linear;

  // ── Spring responses ──────────────────────────────────────────────
  //
  // For physics-driven animations (Cupertino-style hero card press,
  // sheet detent settle, drag-release). Pair `response` (in seconds)
  // and `damping` (0..1) with [SpringDescription.withDampingRatio].

  /// Crisp press / release. Used on chip + magnetic surfaces.
  static const SpringSpec sCrisp = SpringSpec(response: 0.22, damping: 0.86);

  /// Hero card press — slower, more material weight.
  static const SpringSpec sHero = SpringSpec(response: 0.38, damping: 0.88);

  /// Sheet drag — slower still, with overshoot to suggest mass.
  static const SpringSpec sSheet = SpringSpec(response: 0.46, damping: 0.78);

  /// Drag-release for cards / panels — perceptibly bouncy.
  static const SpringSpec sBouncy = SpringSpec(response: 0.34, damping: 0.62);
}

/// A spring spec in `(response, damping)` form (iOS / SwiftUI style).
///
/// `response` is the perceptual settle time in seconds — i.e. how
/// long a critically-damped spring would take to feel "done". The
/// stiffness derived from `response` is `(2π / response)²`.
///
/// `damping` is the damping ratio: 1.0 is critically damped (no
/// overshoot, fastest possible settle), <1.0 underdamped (bouncy),
/// >1.0 overdamped (slow / mushy). Apple's defaults sit at ~0.825.
class SpringSpec {
  const SpringSpec({required this.response, required this.damping});
  final double response;
  final double damping;

  /// Builds a `SpringDescription` ready to feed into `SpringSimulation`.
  /// The unit mass is 1 — all our springs assume mass=1, which means
  /// stiffness and damping read cleanly from `(response, damping)`.
  SpringDescription get description {
    final stiffness = (2 * 3.141592653589793 / response);
    return SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: stiffness * stiffness,
      ratio: damping,
    );
  }
}
