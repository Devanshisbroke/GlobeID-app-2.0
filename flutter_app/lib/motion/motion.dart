import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexus/nexus_tokens.dart';

/// `motion.dart` — the GlobeID motion language.
///
/// Centralises:
///   • Spring-style curves used across screens
///   • Premium page-transition pages (slide + scale + blur)
///   • Haptic vocabulary so every screen speaks the same touch language
///   • Sound-cue stub interface — a no-op today, but every gesture
///     in the app already calls into it, so wiring real audio later
///     is a single-file change.
class GlobeMotion {
  GlobeMotion._();

  // ── Curves ─────────────────────────────────────────────────────────

  /// Standard outward spring used for entrance + state changes.
  static const Curve spring = Cubic(0.16, 1.0, 0.30, 1.0); // ease-out-back-ish

  /// Soft pop used for taps / micro-feedback.
  static const Curve pop = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Settle used on state collapse (reverse animations).
  static const Curve settle = Cubic(0.45, 0.0, 0.55, 1.0);
}

// ─────────────────────────────────────────────────────────────────────
// HAPTIC VOCABULARY
// ─────────────────────────────────────────────────────────────────────

/// `Haptics` — the GlobeID haptic vocabulary.
///
/// Wraps `HapticFeedback` so every screen agrees on what each gesture
/// *feels* like. Light = navigation/selection, medium = state change,
/// heavy = consequential action, selection = list scrubbing.
class Haptics {
  Haptics._();

  /// User tapped a button or made a selection. Cheapest tap.
  static void tap() {
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.tap);
  }

  /// User opened a panel, drawer, modal, or expanded a card.
  static void open() {
    HapticFeedback.mediumImpact();
    SoundCues.instance.play(SoundCue.open);
  }

  /// User closed / dismissed something.
  static void close() {
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.close);
  }

  /// User triggered an irreversible / consequential action (purchase,
  /// confirm, scan-success).
  static void confirm() {
    HapticFeedback.heavyImpact();
    SoundCues.instance.play(SoundCue.confirm);
  }

  /// User got an error or hit a boundary.
  static void error() {
    HapticFeedback.heavyImpact();
    SoundCues.instance.play(SoundCue.error);
  }

  /// User scrubbed across a list (picker / slider / wheel).
  static void scrub() {
    HapticFeedback.selectionClick();
  }

  /// User navigated between tabs / pages.
  static void navigate() {
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.navigate);
  }
}

// ─────────────────────────────────────────────────────────────────────
// SOUND CUE STUB
// ─────────────────────────────────────────────────────────────────────

enum SoundCue { tap, open, close, confirm, error, navigate, success }

/// `SoundCues` — single-instance sound dispatcher.
///
/// Today this is a no-op (no audio package is wired into the app). The
/// API is shaped so a future PR can drop in `audioplayers` or `soloud`
/// without touching call sites — just replace the body of `play`.
class SoundCues {
  SoundCues._();
  static final SoundCues instance = SoundCues._();

  /// Master volume 0..1; default 0 so we never play anything by default.
  double volume = 0.0;

  /// Whether sound cues are enabled at all.
  bool enabled = false;

  /// Last cue played (exposed for tests / instrumentation).
  SoundCue? lastCue;

  /// Play the cue. Currently a no-op; records `lastCue` for tests.
  void play(SoundCue cue) {
    lastCue = cue;
    if (!enabled || volume <= 0) return;
    // Future: dispatch to audio package.
  }
}

// ─────────────────────────────────────────────────────────────────────
// PAGE TRANSITIONS
// ─────────────────────────────────────────────────────────────────────

/// Canonical Nexus page transition.
///
/// Pure fade + 16 px slide-up + 0.98→1.00 scale on push, eased with
/// [N.ease]. No backdrop blur, no shadow — depth comes from contrast
/// and the hairline-bordered substrate beneath. Cheap on the GPU,
/// indistinguishable from the previous blur-based transition for the
/// user, and consistent with the Travel-OS / Wallet reference.
Widget premiumSlideTransition(
  BuildContext _,
  Animation<double> anim,
  Animation<double> __,
  Widget child,
) {
  final t = CurvedAnimation(parent: anim, curve: N.ease);
  return AnimatedBuilder(
    animation: t,
    builder: (_, c) {
      final v = t.value;
      return Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: Transform.scale(
            scale: 0.98 + 0.02 * v,
            child: c,
          ),
        ),
      );
    },
    child: child,
  );
}

/// Fade-only transition for non-disruptive route changes (e.g. tab swap).
Widget premiumFadeTransition(
  BuildContext _,
  Animation<double> anim,
  Animation<double> __,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: anim, curve: GlobeMotion.spring),
    child: child,
  );
}
