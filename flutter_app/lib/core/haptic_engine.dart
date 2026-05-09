import 'package:flutter/services.dart';

/// Typed haptic feedback vocabulary.
///
/// Every interactive surface in the app routes through this instead of
/// calling [HapticFeedback] directly. This lets us:
///  1. Define semantic patterns (tap ≠ select ≠ success ≠ warning).
///  2. Respect a user-level "reduce haptics" preference.
///  3. Swap the underlying engine for richer platform-specific APIs later
///     (e.g. Core Haptics on iOS 13+) without touching 50 call sites.
class Haptics {
  Haptics._();

  static bool enabled = true;

  /// Lightest feedback — icon toggles, chip taps, minor selections.
  static void tap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Tab bar selection, list item highlight, radio/checkbox.
  static void select() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Card press, FAB tap, primary button.
  static void press() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Confirmation, payment complete, scan success, identity verified.
  static void success() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Approaching a limit, expiry warning, low balance.
  static void warning() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Error, declined, scan failure, auth rejection.
  static void error() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Mode lock, biometric gate, session lock engaged.
  static void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Smooth ratchet tick — used for scrubbers, value pickers,
  /// slider detents.
  static void tick() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }
}
