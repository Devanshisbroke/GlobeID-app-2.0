import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// EMOTIONAL COLOR SYSTEM
//
// Colors shift based on context — time of day, trip lifecycle,
// user state. Not jarring theme changes, but subtle temperature
// adjustments of 5-10% hue/saturation that make the app feel alive.
// ═══════════════════════════════════════════════════════════════════════

/// The emotional context driving palette adjustments.
enum EmotionalContext {
  /// Default neutral state — balanced, calm.
  neutral,

  /// Pre-trip excitement — warm amber/coral undertones.
  excitement,

  /// In-flight calm — deep indigo/navy.
  inflight,

  /// Arrival discovery — teal/emerald freshness.
  discovery,

  /// Airport stress — cooled blues, reduced saturation.
  stress,

  /// Night rest — ultra-dark, warm grays.
  night,

  /// Celebration — gold accents bloom.
  celebration,

  /// Financial alert — subtle red temperature shift.
  financialAlert,

  /// Morning routine — warm, gentle, inviting.
  morning,

  /// Focus mode — minimal, high contrast.
  focus,
}

/// Palette temperature adjustments for each emotional context.
class EmotionalPalette {
  EmotionalPalette._();

  /// Get the color adjustment for an emotional context.
  static EmotionalShift shiftFor(EmotionalContext context) {
    switch (context) {
      case EmotionalContext.neutral:
        return const EmotionalShift();
      case EmotionalContext.excitement:
        return const EmotionalShift(
          hueShift: 15,
          saturationMultiplier: 1.12,
          warmthShift: 0.08,
          glowIntensity: 0.15,
          accentOverride: Color(0xFFF59E0B),
        );
      case EmotionalContext.inflight:
        return const EmotionalShift(
          hueShift: -20,
          saturationMultiplier: 0.85,
          warmthShift: -0.05,
          glowIntensity: 0.08,
          accentOverride: Color(0xFF3B82F6),
        );
      case EmotionalContext.discovery:
        return const EmotionalShift(
          hueShift: -40,
          saturationMultiplier: 1.08,
          warmthShift: -0.03,
          glowIntensity: 0.12,
          accentOverride: Color(0xFF14B8A6),
        );
      case EmotionalContext.stress:
        return const EmotionalShift(
          hueShift: -10,
          saturationMultiplier: 0.75,
          warmthShift: -0.08,
          glowIntensity: 0.04,
        );
      case EmotionalContext.night:
        return const EmotionalShift(
          hueShift: 5,
          saturationMultiplier: 0.7,
          warmthShift: 0.04,
          brightnessShift: -0.1,
          glowIntensity: 0.06,
        );
      case EmotionalContext.celebration:
        return const EmotionalShift(
          hueShift: 25,
          saturationMultiplier: 1.2,
          warmthShift: 0.12,
          glowIntensity: 0.25,
          accentOverride: Color(0xFFD4AF37),
        );
      case EmotionalContext.financialAlert:
        return const EmotionalShift(
          hueShift: 0,
          saturationMultiplier: 0.9,
          warmthShift: 0.15,
          glowIntensity: 0.1,
          accentOverride: Color(0xFFEF4444),
        );
      case EmotionalContext.morning:
        return const EmotionalShift(
          hueShift: 10,
          saturationMultiplier: 0.95,
          warmthShift: 0.06,
          brightnessShift: 0.02,
          glowIntensity: 0.08,
          accentOverride: Color(0xFFFB923C),
        );
      case EmotionalContext.focus:
        return const EmotionalShift(
          saturationMultiplier: 0.8,
          glowIntensity: 0.02,
          brightnessShift: 0.05,
        );
    }
  }

  /// Detect the emotional context from time + trip state.
  static EmotionalContext detect({
    DateTime? now,
    TripPhase tripPhase = TripPhase.none,
    bool hasFinancialAlert = false,
    bool isCelebrating = false,
  }) {
    if (isCelebrating) return EmotionalContext.celebration;
    if (hasFinancialAlert) return EmotionalContext.financialAlert;

    switch (tripPhase) {
      case TripPhase.preDeparture:
        return EmotionalContext.excitement;
      case TripPhase.inflight:
        return EmotionalContext.inflight;
      case TripPhase.arrived:
        return EmotionalContext.discovery;
      case TripPhase.atAirport:
        return EmotionalContext.stress;
      case TripPhase.none:
        break;
    }

    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 6 && hour < 10) return EmotionalContext.morning;
    if (hour >= 22 || hour < 6) return EmotionalContext.night;

    return EmotionalContext.neutral;
  }
}

/// Trip lifecycle phases for emotional context detection.
enum TripPhase { none, preDeparture, atAirport, inflight, arrived }

/// A set of color adjustments to apply to the base theme.
@immutable
class EmotionalShift {
  const EmotionalShift({
    this.hueShift = 0,
    this.saturationMultiplier = 1.0,
    this.warmthShift = 0.0,
    this.brightnessShift = 0.0,
    this.glowIntensity = 0.0,
    this.accentOverride,
  });

  /// Hue rotation in degrees (-180 to 180).
  final double hueShift;

  /// Saturation multiplier (0.0 = grayscale, 1.0 = normal, 2.0 = vivid).
  final double saturationMultiplier;

  /// Warmth adjustment (-1.0 = cold blue, 0.0 = neutral, 1.0 = warm amber).
  final double warmthShift;

  /// Brightness adjustment (-1.0 = darker, 0.0 = normal, 1.0 = lighter).
  final double brightnessShift;

  /// Ambient glow intensity (0.0 = none, 1.0 = maximum).
  final double glowIntensity;

  /// Optional accent color override for this emotional state.
  final Color? accentOverride;

  /// Linearly interpolate between two shifts.
  static EmotionalShift lerp(EmotionalShift a, EmotionalShift b, double t) {
    return EmotionalShift(
      hueShift: a.hueShift + (b.hueShift - a.hueShift) * t,
      saturationMultiplier: a.saturationMultiplier +
          (b.saturationMultiplier - a.saturationMultiplier) * t,
      warmthShift: a.warmthShift + (b.warmthShift - a.warmthShift) * t,
      brightnessShift:
          a.brightnessShift + (b.brightnessShift - a.brightnessShift) * t,
      glowIntensity:
          a.glowIntensity + (b.glowIntensity - a.glowIntensity) * t,
      accentOverride: t < 0.5 ? a.accentOverride : b.accentOverride,
    );
  }

  /// Apply this shift to a [Color].
  Color apply(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withHue((hsl.hue + hueShift) % 360)
        .withSaturation(
            (hsl.saturation * saturationMultiplier).clamp(0.0, 1.0))
        .withLightness(
            (hsl.lightness + brightnessShift).clamp(0.0, 1.0))
        .toColor();
  }

  /// The ambient glow color for overlays.
  Color get glowColor {
    final base = accentOverride ?? const Color(0xFF0EA5E9);
    return base.withValues(alpha: glowIntensity);
  }
}

/// An [InheritedWidget] that provides the current emotional palette
/// down the widget tree, enabling all descendant widgets to adjust
/// their rendering based on the emotional context.
class EmotionalTheme extends InheritedWidget {
  const EmotionalTheme({
    super.key,
    required this.shift,
    required this.context,
    required super.child,
  });

  final EmotionalShift shift;
  final EmotionalContext context;

  static EmotionalShift of(BuildContext ctx) {
    final widget = ctx.dependOnInheritedWidgetOfExactType<EmotionalTheme>();
    return widget?.shift ?? const EmotionalShift();
  }

  static EmotionalContext contextOf(BuildContext ctx) {
    final widget = ctx.dependOnInheritedWidgetOfExactType<EmotionalTheme>();
    return widget?.context ?? EmotionalContext.neutral;
  }

  @override
  bool updateShouldNotify(EmotionalTheme old) =>
      shift != old.shift || context != old.context;
}

/// A widget that smoothly transitions between emotional contexts.
///
/// Wraps its subtree with [EmotionalTheme] and animates the shift
/// over 2 seconds when the context changes — ensuring the color
/// temperature change is felt, not seen.
class EmotionalThemeProvider extends StatefulWidget {
  const EmotionalThemeProvider({
    super.key,
    required this.context,
    required this.child,
  });

  final EmotionalContext context;
  final Widget child;

  @override
  State<EmotionalThemeProvider> createState() => _EmotionalThemeProviderState();
}

class _EmotionalThemeProviderState extends State<EmotionalThemeProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  EmotionalShift _from = const EmotionalShift();
  EmotionalShift _to = const EmotionalShift();

  @override
  void initState() {
    super.initState();
    _to = EmotionalPalette.shiftFor(widget.context);
    _from = _to;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(EmotionalThemeProvider old) {
    super.didUpdateWidget(old);
    if (old.context != widget.context) {
      _from = EmotionalShift.lerp(_from, _to, _ctrl.value);
      _to = EmotionalPalette.shiftFor(widget.context);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final shift = EmotionalShift.lerp(_from, _to, _ctrl.value);
        return EmotionalTheme(
          shift: shift,
          context: widget.context,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}
