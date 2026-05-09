import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════
// HAPTIC CHOREOGRAPHY ENGINE
//
// Upgrades raw HapticFeedback calls into sequenced, meaningful patterns.
// Every gesture in GlobeID has a specific haptic "word" — a timed
// sequence of impulses that communicates state through touch.
// ═══════════════════════════════════════════════════════════════════════

/// A single impulse in a haptic sequence.
class HapticImpulse {
  const HapticImpulse(this.type, {this.delayAfter = Duration.zero});
  final HapticType type;
  final Duration delayAfter;
}

/// Types of haptic feedback available.
enum HapticType { light, medium, heavy, selection, none }

/// A sequence of haptic impulses that plays in order.
class HapticSequence {
  const HapticSequence(this.impulses);
  final List<HapticImpulse> impulses;

  /// Play the sequence asynchronously.
  Future<void> play() async {
    for (final impulse in impulses) {
      _fire(impulse.type);
      if (impulse.delayAfter > Duration.zero) {
        await Future.delayed(impulse.delayAfter);
      }
    }
  }

  static void _fire(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
      case HapticType.medium:
        HapticFeedback.mediumImpact();
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
      case HapticType.selection:
        HapticFeedback.selectionClick();
      case HapticType.none:
        break;
    }
  }
}

/// Canonical haptic patterns — the GlobeID touch vocabulary.
///
/// Every interactive surface uses these patterns to communicate
/// consistently. No raw [HapticFeedback] calls outside this file.
class HapticPatterns {
  HapticPatterns._();

  /// Crisp click — button tap, chip select, nav icon.
  static const tap = HapticSequence([
    HapticImpulse(HapticType.light),
  ]);

  /// Door opening — sheet reveal, modal open, card expand.
  static const open = HapticSequence([
    HapticImpulse(HapticType.medium, delayAfter: Duration(milliseconds: 40)),
    HapticImpulse(HapticType.light),
  ]);

  /// Soft close — dismiss, collapse, sheet close.
  static const close = HapticSequence([
    HapticImpulse(HapticType.light),
  ]);

  /// Satisfying lock — confirm action, payment success, biometric verify.
  static const confirm = HapticSequence([
    HapticImpulse(HapticType.heavy, delayAfter: Duration(milliseconds: 60)),
    HapticImpulse(HapticType.medium, delayAfter: Duration(milliseconds: 40)),
    HapticImpulse(HapticType.light),
  ]);

  /// Double knock — error, boundary hit, invalid action.
  static const error = HapticSequence([
    HapticImpulse(HapticType.heavy, delayAfter: Duration(milliseconds: 30)),
    HapticImpulse(HapticType.heavy),
  ]);

  /// Ratchet click — scroll snap, picker detent, slider tick.
  static const scrub = HapticSequence([
    HapticImpulse(HapticType.selection),
  ]);

  /// Subtle page change — tab switch, nav transition.
  static const navigate = HapticSequence([
    HapticImpulse(HapticType.light),
  ]);

  /// Pressure build — long press begin, hold gesture.
  static const pressureBegin = HapticSequence([
    HapticImpulse(HapticType.light, delayAfter: Duration(milliseconds: 100)),
    HapticImpulse(HapticType.medium),
  ]);

  /// Release — long press end, drop gesture.
  static const pressureRelease = HapticSequence([
    HapticImpulse(HapticType.light),
  ]);

  /// Achievement unlock — celebration, tier upgrade.
  static const celebrate = HapticSequence([
    HapticImpulse(HapticType.heavy, delayAfter: Duration(milliseconds: 80)),
    HapticImpulse(HapticType.medium, delayAfter: Duration(milliseconds: 60)),
    HapticImpulse(HapticType.light, delayAfter: Duration(milliseconds: 40)),
    HapticImpulse(HapticType.selection),
  ]);

  /// Warning pulse — budget near limit, document expiring.
  static const warning = HapticSequence([
    HapticImpulse(HapticType.medium, delayAfter: Duration(milliseconds: 200)),
    HapticImpulse(HapticType.medium),
  ]);

  /// Magnetic snap — card docking, element snapping to grid.
  static const snap = HapticSequence([
    HapticImpulse(HapticType.medium),
  ]);

  /// Document reveal — seal break, credential unfold.
  static const reveal = HapticSequence([
    HapticImpulse(HapticType.light, delayAfter: Duration(milliseconds: 120)),
    HapticImpulse(HapticType.medium, delayAfter: Duration(milliseconds: 80)),
    HapticImpulse(HapticType.heavy),
  ]);

  /// Boarding scan success — pass verified at gate.
  static const scanSuccess = HapticSequence([
    HapticImpulse(HapticType.heavy, delayAfter: Duration(milliseconds: 40)),
    HapticImpulse(HapticType.light, delayAfter: Duration(milliseconds: 40)),
    HapticImpulse(HapticType.light),
  ]);

  /// Currency pour — continuous during conversion.
  static const pourTick = HapticSequence([
    HapticImpulse(HapticType.selection),
  ]);
}

/// Convenience class wrapping [HapticPatterns] for easy call-site usage.
///
/// ```dart
/// Haptics.tap();
/// await Haptics.confirm();
/// ```
class HapticEngine {
  HapticEngine._();

  static Future<void> tap() => HapticPatterns.tap.play();
  static Future<void> open() => HapticPatterns.open.play();
  static Future<void> close() => HapticPatterns.close.play();
  static Future<void> confirm() => HapticPatterns.confirm.play();
  static Future<void> error() => HapticPatterns.error.play();
  static Future<void> scrub() => HapticPatterns.scrub.play();
  static Future<void> navigate() => HapticPatterns.navigate.play();
  static Future<void> celebrate() => HapticPatterns.celebrate.play();
  static Future<void> warning() => HapticPatterns.warning.play();
  static Future<void> snap() => HapticPatterns.snap.play();
  static Future<void> reveal() => HapticPatterns.reveal.play();
  static Future<void> scanSuccess() => HapticPatterns.scanSuccess.play();
  static Future<void> pressureBegin() => HapticPatterns.pressureBegin.play();
  static Future<void> pressureRelease() => HapticPatterns.pressureRelease.play();
}
