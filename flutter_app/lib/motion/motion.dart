import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion_tokens.dart';

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
  //
  // Kept for source-compat. New screens should source curves from
  // [Motion] (motion_tokens.dart). These names alias the canonical
  // values 1:1 — no behavior change.

  /// Standard outward spring used for entrance + state changes.
  /// Aliases [Motion.cStandard].
  static const Curve spring = Motion.cStandard;

  /// Soft pop used for taps / micro-feedback.
  /// Aliases [Motion.cSpring].
  static const Curve pop = Motion.cSpring;

  /// Settle used on state collapse (reverse animations).
  /// Aliases [Motion.cSettle].
  static const Curve settle = Motion.cSettle;
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

  /// Master gate — when false, every haptic in the vocabulary is a
  /// no-op. Wire to a "Reduce motion / haptics" accessibility setting
  /// when one is added. Default true; future setting flips it.
  static bool enabled = true;

  // ── Selection family ───────────────────────────────────────────────
  //
  // Cheapest, most frequent haptics. Used for hover/focus/scrub —
  // anything where the user is moving across choices.

  /// User scrubbed across a list (picker / slider / wheel), or focus
  /// moved between items. Identical to [scrub] but with a more
  /// descriptive name for new call sites.
  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Same as [selection]. Kept for source-compat.
  static void scrub() => selection();

  // ── Press / tap family ─────────────────────────────────────────────
  //
  // Light impacts for ordinary tappable surfaces.

  /// User tapped a button or made a selection. Cheapest tap.
  static void tap() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.tap);
  }

  /// User pressed down on a magnetic surface. Identical to
  /// [selection] today but separate so future tuning (a dedicated
  /// soft pulse on iOS' Taptic Engine, for instance) doesn't have
  /// to track down call sites.
  static void pressDown() => selection();

  /// User released a magnetic surface and committed the tap. Same
  /// energy as [tap] today; reserved for richer future tuning.
  static void pressUp() => tap();

  /// User navigated between tabs / pages.
  static void navigate() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.navigate);
  }

  // ── Open / close family ────────────────────────────────────────────

  /// User opened a panel, drawer, modal, or expanded a card.
  static void open() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    SoundCues.instance.play(SoundCue.open);
  }

  /// User closed / dismissed something.
  static void close() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    SoundCues.instance.play(SoundCue.close);
  }

  /// User snapped a sheet / panel to a detent.
  static void snapDetent() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  // ── Outcome family ─────────────────────────────────────────────────

  /// User triggered an irreversible / consequential action (purchase,
  /// confirm, scan-success).
  static void confirm() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    SoundCues.instance.play(SoundCue.confirm);
  }

  /// User completed something positive (payment received, identity
  /// verified, trip booked).
  static Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    SoundCues.instance.play(SoundCue.success);
  }

  /// User hit a soft warning (about to exceed budget, low balance,
  /// passport about to expire).
  static void warning() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// User got an error or hit a boundary.
  static void error() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    SoundCues.instance.play(SoundCue.error);
  }

  // ── Pull-to-refresh family ─────────────────────────────────────────

  /// User crossed the pull-to-refresh threshold (pull > armed
  /// distance). One soft tick — let the user know the gesture is
  /// armed.
  static void pullArmed() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// User released a pull-to-refresh while armed. The refresh
  /// actually began.
  static void pullCommitted() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  // ── Signature / cinematic family ───────────────────────────────────
  //
  // Reserved for hero moments — passport bearer reveal, boarding-pass
  // unlock, identity tier-up. Multi-pulse pattern that reads as
  // "something significant just happened".

  /// Cinematic signature haptic — a multi-pulse pattern. Use sparingly
  /// (≤ 1× per screen, ≤ 5× per session) to preserve the moment.
  static Future<void> signature() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.lightImpact();
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

/// Canonical Nexus page transition — Apple-grade smoothness.
///
/// Cross-fades the incoming and outgoing screens simultaneously while
/// applying a 12 px slide-up + 0.985 → 1.00 scale to the new screen
/// and a 1.00 → 0.985 scale + soft fade to 0.0 on the outgoing screen.
/// No BackdropFilter, no ImageFiltered — those are GPU killers that
/// cause the lingering "ghost" effect.
///
/// Both layers are wrapped in [RepaintBoundary] so they composite as
/// independent surfaces, eliminating ghost frames on push/pop.
Widget premiumSlideTransition(
  BuildContext _,
  Animation<double> anim,
  Animation<double> secondary,
  Widget child,
) {
  // Incoming uses the canonical [Motion.cStandard] (ease-out-back-soft);
  // outgoing uses [Motion.cExit] so the previous route accelerates
  // *out* as the new one decelerates *in*. This asymmetry is what
  // gives Apple's push transitions their "decisive" feel — without it
  // you get the lingering ghost effect.
  final inCurve = CurvedAnimation(parent: anim, curve: Motion.cStandard);
  final outCurve = CurvedAnimation(parent: secondary, curve: Motion.cExit);
  return AnimatedBuilder(
    animation: Listenable.merge([inCurve, outCurve]),
    builder: (_, c) {
      final i = inCurve.value;
      final o = outCurve.value;
      // Outgoing: subtle scale down + fade. Quick + decisive.
      final outOpacity = (1.0 - o * 0.85).clamp(0.0, 1.0);
      final outScale = 1.0 - o * 0.02;
      // Incoming: fade in fast (front-loaded), slide up 12 px, scale 0.985→1.0
      final inOpacity = i.clamp(0.0, 1.0);
      final inScale = 0.985 + 0.015 * i;
      final inOffsetY = (1 - i) * 12;
      return RepaintBoundary(
        child: Opacity(
          opacity: inOpacity * outOpacity,
          child: Transform.translate(
            offset: Offset(0, inOffsetY),
            child: Transform.scale(
              scale: inScale * outScale,
              child: c,
            ),
          ),
        ),
      );
    },
    child: RepaintBoundary(child: child),
  );
}

/// Apple-grade sheet presentation transition.
///
/// Mirrors UIKit's `.sheet` / SwiftUI's `.sheet` motion: the incoming
/// route slides up from the bottom on a soft spring curve, scales the
/// previous content down very slightly (0.98) to suggest layered
/// depth without dimming it. Use for `/wallet/scheduled`, statements,
/// modal flows where the user expects "this is a temporary surface I
/// can swipe down to dismiss".
///
/// Pairs with [Motion.dSheet] (320 ms in, 220 ms out).
Widget premiumSheetTransition(
  BuildContext _,
  Animation<double> anim,
  Animation<double> secondary,
  Widget child,
) {
  final inCurve = CurvedAnimation(parent: anim, curve: Motion.cStandard);
  final outCurve = CurvedAnimation(parent: secondary, curve: Motion.cExit);
  return AnimatedBuilder(
    animation: Listenable.merge([inCurve, outCurve]),
    builder: (_, c) {
      final i = inCurve.value;
      final o = outCurve.value;
      // Incoming: slide up from the bottom (24 % of its height) and
      // fade in. No scale on the new sheet — sheets present at 100 %.
      final inOpacity = i.clamp(0.0, 1.0);
      final inOffsetY = (1 - i) * 0.24;
      // Outgoing: subtle scale down (0.98) without fade — the dimmed
      // background depth is provided by the sheet's own backdrop.
      final outScale = 1.0 - o * 0.02;
      return RepaintBoundary(
        child: Transform.scale(
          scale: outScale,
          child: FractionalTranslation(
            translation: Offset(0, inOffsetY),
            child: Opacity(opacity: inOpacity, child: c),
          ),
        ),
      );
    },
    child: RepaintBoundary(child: child),
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
    opacity: CurvedAnimation(parent: anim, curve: Motion.cStandard),
    child: child,
  );
}
