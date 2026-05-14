import 'package:flutter/material.dart';

/// Phase 13d — Reduced motion / brand motion policy.
///
/// When the operating system requests reduced motion (`MediaQuery
/// .disableAnimations`), GlobeID does NOT strip every cinematic
/// moment — it *adapts* them. The brand DNA depends on the
/// ceremonial layer (foil press, seal commit, ink bleed) for its
/// identity; without it, the app is just another credential
/// wallet. So:
///
///   * **STRUCTURAL** transitions (page slide, modal slide-up,
///     drawer reveal) → collapse to a 100 ms crossfade.
///   * **AMBIENT** ornaments (breathing halo, particle drift,
///     foil shimmer loops, parallax tilt) → frozen at frame 0.
///   * **SIGNATURE** moments (seal commit, stamp drop, ink
///     bleed) → preserved at 50% duration so the ceremony still
///     happens, but the motion finishes faster.
///   * **HAPTIC** signatures → always preserved; haptics don't
///     count as motion.
///
/// This file ships the resolver primitives. Future surfaces wrap
/// their animation durations + curves through
/// `BrandMotionPolicy.adapt(...)` so the policy applies uniformly.
class BrandMotionPolicy {
  BrandMotionPolicy._();

  /// True when the user has requested reduced motion at the OS
  /// level (iOS: Settings → Accessibility → Motion → Reduce Motion).
  static bool isReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Adapt a duration through the policy for the given role.
  static Duration adaptDuration(
    BuildContext context,
    Duration full, {
    required BrandMotionRole role,
  }) {
    if (!isReduced(context)) return full;
    switch (role) {
      case BrandMotionRole.structural:
        return const Duration(milliseconds: 100);
      case BrandMotionRole.ambient:
        return Duration.zero;
      case BrandMotionRole.signature:
        // Half the original duration so the ceremony still
        // happens but completes faster.
        return Duration(microseconds: (full.inMicroseconds / 2).round());
    }
  }

  /// Adapt a curve through the policy.
  ///
  /// Reduced motion strips bouncy curves (overshoot, elastic) and
  /// substitutes a clean `Curves.easeOutCubic` — the curve still
  /// communicates direction but never returns past its end value.
  static Curve adaptCurve(BuildContext context, Curve full) {
    if (!isReduced(context)) return full;
    return Curves.easeOutCubic;
  }

  /// Whether an ambient ornament should render at all.
  ///
  /// Returns false under reduced motion. Use this to skip
  /// breathing-halo / particle-drift / foil-shimmer widgets.
  static bool shouldRenderAmbient(BuildContext context) =>
      !isReduced(context);
}

/// Role of an animation with respect to the GlobeID motion policy.
enum BrandMotionRole {
  /// Page transitions, modal slide-up, drawer reveal. Reduced
  /// motion collapses to a 100 ms crossfade.
  structural,

  /// Breathing halo, particle drift, foil shimmer, parallax tilt.
  /// Reduced motion removes entirely.
  ambient,

  /// Seal commit, stamp drop, ink bleed, ceremony animations.
  /// Reduced motion runs at 50% duration so the moment still
  /// happens but the dwell is shorter.
  signature,
}

/// Wrap a subtree to opt it out of ambient ornaments when
/// reduced motion is active.
///
/// ```dart
/// ReducedMotionGate(
///   role: BrandMotionRole.ambient,
///   placeholder: SizedBox.shrink(),
///   child: BreathingHalo(...),
/// )
/// ```
class ReducedMotionGate extends StatelessWidget {
  const ReducedMotionGate({
    super.key,
    required this.role,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
  });

  final BrandMotionRole role;
  final Widget child;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final reduced = BrandMotionPolicy.isReduced(context);
    if (!reduced) return child;
    switch (role) {
      case BrandMotionRole.ambient:
        return placeholder;
      case BrandMotionRole.structural:
      case BrandMotionRole.signature:
        return child;
    }
  }
}
