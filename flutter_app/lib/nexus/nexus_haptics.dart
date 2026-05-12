import 'package:flutter/services.dart';

/// Nexus haptic vocabulary — small, deliberate, never spammy.
class NHaptics {
  NHaptics._();

  /// A light tap — for normal taps on chips / cards.
  static void tap() => HapticFeedback.selectionClick();

  /// A medium pulse — confirming an action (authorize, transfer).
  static void confirm() => HapticFeedback.mediumImpact();

  /// A warning pulse — for status changes (gate change, banner).
  static void warn() => HapticFeedback.lightImpact();

  /// Heavy — only for authentication success.
  static void unlock() => HapticFeedback.heavyImpact();
}
