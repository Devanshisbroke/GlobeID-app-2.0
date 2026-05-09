import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Premium page transition library.
///
/// Each builder returns a [Widget Function(context, anim, secondaryAnim, child)]
/// suitable for [CustomTransitionPage.transitionsBuilder].

// ── Rise transition ──────────────────────────────────────────────
/// Card rises from the bottom with scale, blur, and opacity.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get riseTransition {
  return (context, primary, secondary, child) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: primary,
      curve: AppTokens.easeOutSoft,
    ));
    final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: primary, curve: AppTokens.easeOutSoft),
    );
    final opacity = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      ),
    );
  };
}

// ── Scale-from-anchor ────────────────────────────────────────────
/// Expands from a specific screen position (e.g. a tapped card).
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    scaleFromAnchor(Alignment anchor) {
  return (context, primary, secondary, child) {
    final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: primary, curve: AppTokens.easeOutBack),
    );
    final opacity = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: scale,
        alignment: anchor,
        child: child,
      ),
    );
  };
}

// ── Morph transition ─────────────────────────────────────────────
/// Cross-fade with concurrent scale down of exiting page.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get morphTransition {
  return (context, primary, secondary, child) {
    final fadeIn = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    final scaleIn = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(parent: primary, curve: AppTokens.easeOutSoft),
    );
    return FadeTransition(
      opacity: fadeIn,
      child: ScaleTransition(
        scale: scaleIn,
        child: child,
      ),
    );
  };
}

// ── Drop transition ──────────────────────────────────────────────
/// Page drops in from above with slight bounce.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get dropTransition {
  return (context, primary, secondary, child) {
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: primary,
      curve: AppTokens.easeOutBack,
    ));
    final opacity = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  };
}

// ── Blur-fade transition ─────────────────────────────────────────
/// Incoming page fades in while background blurs. Ultra-premium feel
/// for modal-style presentations.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get blurFadeTransition {
  return (context, primary, secondary, child) {
    final opacity = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );
    final blur = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: primary, curve: AppTokens.easeOutSoft),
    );
    return AnimatedBuilder(
      animation: blur,
      builder: (_, __) => ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: math.max(0.01, blur.value),
          sigmaY: math.max(0.01, blur.value),
        ),
        child: FadeTransition(
          opacity: opacity,
          child: child,
        ),
      ),
    );
  };
}

// ── Slide-lateral transition ─────────────────────────────────────
/// iOS-style push from right with subtle depth parallax on the
/// exiting page.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get slideLateralTransition {
  return (context, primary, secondary, child) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: primary,
      curve: AppTokens.easeOutSoft,
    ));
    return SlideTransition(
      position: slideIn,
      child: child,
    );
  };
}

// ── Reduced-motion fallback ──────────────────────────────────────
/// Simple opacity crossfade for users who prefer reduced motion.
Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get reducedMotionTransition {
  return (context, primary, secondary, child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: primary, curve: Curves.easeOut),
      child: child,
    );
  };
}
