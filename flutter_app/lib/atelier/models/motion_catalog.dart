import 'package:flutter/animation.dart';

import '../../motion/motion_tokens.dart';

/// Atelier — motion choreography catalog.
///
/// Every named duration + curve in the GlobeID motion vocabulary,
/// surfaced as a data row so the operator can preview the actual
/// timing on screen. Sourced from [Motion] so this catalog is the
/// canonical exposé of the bible's motion taxonomy.
class MotionCatalog {
  MotionCatalog._();

  static const List<MotionDurationEntry> durations = <MotionDurationEntry>[
    MotionDurationEntry(
      id: 'd-instant',
      name: 'dInstant',
      duration: Motion.dInstant,
      role: 'Status pill flips, haptic mirror, beacon switch — feels instant '
          'but still lerps so the eye does not miss the change.',
      usage: 'LiveStatusPill state changes · indicator dot flip',
    ),
    MotionDurationEntry(
      id: 'd-tap',
      name: 'dTap',
      duration: Motion.dTap,
      role: 'Pressable / MagneticPressable press → released scale settle.',
      usage: 'Tap feedback on every hot tappable',
    ),
    MotionDurationEntry(
      id: 'd-quick-reverse',
      name: 'dQuickReverse',
      duration: Motion.dQuickReverse,
      role: 'Outgoing element fades while incoming arrives. Front-loaded so '
          'the new content reads first.',
      usage: 'Route reverse · sheet dismiss · close transitions',
    ),
    MotionDurationEntry(
      id: 'd-modal',
      name: 'dModal',
      duration: Motion.dModal,
      role: 'Blur-fade route presentation — secondary screens, audit log, '
          'intelligence sheet.',
      usage: 'Modal-grade entrance for blur-fade routes',
    ),
    MotionDurationEntry(
      id: 'd-sheet',
      name: 'dSheet',
      duration: Motion.dSheet,
      role: 'AppleSheet slide-up + handle ready. Slightly longer than dModal '
          'so the eye registers the detent.',
      usage: 'Every showAppleSheet detent snap',
    ),
    MotionDurationEntry(
      id: 'd-page',
      name: 'dPage',
      duration: Motion.dPage,
      role: 'Standard navigation push. Slide + scale + blur lens. Apple-tuned '
          'so it feels like depth, not chrome.',
      usage: 'Every router push / pop · descent routes',
    ),
    MotionDurationEntry(
      id: 'd-cruise',
      name: 'dCruise',
      duration: Motion.dCruise,
      role: 'Neutral layout shifts — a card growing, a row settling, a chip '
          'sliding to a new home.',
      usage: 'Implicit layout animations · AnimatedContainer',
    ),
    MotionDurationEntry(
      id: 'd-portal',
      name: 'dPortal',
      duration: Motion.dPortal,
      role: 'Hero-grade reveals — lock screen → unlocked, onboarding stage, '
          'credential mint. Long enough to feel ceremonial.',
      usage: 'Cinematic ceremony entrance · onboarding stage commit',
    ),
    MotionDurationEntry(
      id: 'd-breath-fast',
      name: 'dBreathFast',
      duration: Motion.dBreathFast,
      role: 'Ambient pulse — live ribbon, status beacon. Sinus loop so the '
          'surface reads as alive without commanding attention.',
      usage: 'BreathingHalo fast cadence · status beacon',
    ),
    MotionDurationEntry(
      id: 'd-breath-slow',
      name: 'dBreathSlow',
      duration: Motion.dBreathSlow,
      role: 'Slow ambient sinus — background substrate breathing, world '
          'atmosphere. Calmer pace.',
      usage: 'World atmosphere · ambient substrate halo',
    ),
  ];

  static const List<MotionCurveEntry> curves = <MotionCurveEntry>[
    MotionCurveEntry(
      id: 'c-standard',
      name: 'cStandard',
      curve: Motion.cStandard,
      role: 'Apple ease-out-back-soft. The default. 99 % of incoming '
          'elements should use this curve.',
      formula: 'Cubic(0.16, 1.00, 0.30, 1.00)',
    ),
    MotionCurveEntry(
      id: 'c-emphasized',
      name: 'cEmphasized',
      curve: Motion.cEmphasized,
      role: 'Steeper start for decisive moments — commit, dismiss, '
          'submit. Reads as intentional.',
      formula: 'Cubic(0.65, 0.00, 0.35, 1.00)',
    ),
    MotionCurveEntry(
      id: 'c-spring',
      name: 'cSpring',
      curve: Motion.cSpring,
      role: 'Overshoots at end — chip taps, beacon flips, micro-interactions '
          'that need a "alive" bounce.',
      formula: 'Cubic(0.34, 1.56, 0.64, 1.00)',
    ),
    MotionCurveEntry(
      id: 'c-exit',
      name: 'cExit',
      curve: Motion.cExit,
      role: 'Front-loaded ease-in for outgoing pages during a push. The '
          'old content yields quickly so the new content reads.',
      formula: 'Cubic(0.55, 0.00, 1.00, 0.45)',
    ),
    MotionCurveEntry(
      id: 'c-settle',
      name: 'cSettle',
      curve: Motion.cSettle,
      role: 'Layout collapse — drawer close, content recede, panel fold. '
          'Calm exhale, no overshoot.',
      formula: 'Cubic(0.33, 1.00, 0.68, 1.00)',
    ),
    MotionCurveEntry(
      id: 'c-linear',
      name: 'cLinear',
      curve: Motion.cLinear,
      role: 'Only for measured progress — CircularProgressIndicator, '
          'scroll-driven offsets. Never for state changes.',
      formula: 'Curves.linear',
    ),
  ];

  /// Returns the duration entry by id (null if not found).
  static MotionDurationEntry? durationById(String id) {
    for (final e in durations) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Returns the curve entry by id (null if not found).
  static MotionCurveEntry? curveById(String id) {
    for (final e in curves) {
      if (e.id == id) return e;
    }
    return null;
  }
}

class MotionDurationEntry {
  const MotionDurationEntry({
    required this.id,
    required this.name,
    required this.duration,
    required this.role,
    required this.usage,
  });

  final String id;
  final String name;
  final Duration duration;
  final String role;
  final String usage;

  String get readable {
    if (duration.inMilliseconds >= 1000) {
      final s = duration.inMilliseconds / 1000.0;
      return '${s.toStringAsFixed(s.truncateToDouble() == s ? 0 : 1)} s';
    }
    return '${duration.inMilliseconds} ms';
  }
}

class MotionCurveEntry {
  const MotionCurveEntry({
    required this.id,
    required this.name,
    required this.curve,
    required this.role,
    required this.formula,
  });

  final String id;
  final String name;
  final Curve curve;
  final String role;
  final String formula;
}
