import 'package:flutter/material.dart';

/// Stage of the day used to drive ambient app tinting.
enum DayStage { predawn, dawn, morning, midday, golden, dusk, evening, night }

extension DayStageX on DayStage {
  /// Returns a stage from the given local hour (0-23).
  static DayStage fromHour(int hour) {
    if (hour < 5) return DayStage.predawn;
    if (hour < 7) return DayStage.dawn;
    if (hour < 11) return DayStage.morning;
    if (hour < 14) return DayStage.midday;
    if (hour < 17) return DayStage.golden;
    if (hour < 19) return DayStage.dusk;
    if (hour < 22) return DayStage.evening;
    return DayStage.night;
  }
}

/// A pair of canopy / floor tints for a stage of the day.
class AmbientPalette {
  const AmbientPalette({
    required this.canopy,
    required this.horizon,
    required this.floor,
    required this.warmth,
  });
  final Color canopy;
  final Color horizon;
  final Color floor;
  final double warmth;

  static AmbientPalette of(DayStage stage) {
    switch (stage) {
      case DayStage.predawn:
        return const AmbientPalette(
          canopy: Color(0xFF0A0F1F),
          horizon: Color(0xFF1B2240),
          floor: Color(0xFF050610),
          warmth: -0.12,
        );
      case DayStage.dawn:
        return const AmbientPalette(
          canopy: Color(0xFF1B274A),
          horizon: Color(0xFFEAB179),
          floor: Color(0xFF0F142A),
          warmth: 0.18,
        );
      case DayStage.morning:
        return const AmbientPalette(
          canopy: Color(0xFF153061),
          horizon: Color(0xFF87C3F4),
          floor: Color(0xFF0B1530),
          warmth: 0.10,
        );
      case DayStage.midday:
        return const AmbientPalette(
          canopy: Color(0xFF0F2247),
          horizon: Color(0xFF6EA8E0),
          floor: Color(0xFF09102A),
          warmth: 0.0,
        );
      case DayStage.golden:
        return const AmbientPalette(
          canopy: Color(0xFF2A1A4E),
          horizon: Color(0xFFE6A24F),
          floor: Color(0xFF110A24),
          warmth: 0.30,
        );
      case DayStage.dusk:
        return const AmbientPalette(
          canopy: Color(0xFF1F1240),
          horizon: Color(0xFFD06A52),
          floor: Color(0xFF0A0518),
          warmth: 0.22,
        );
      case DayStage.evening:
        return const AmbientPalette(
          canopy: Color(0xFF0E1234),
          horizon: Color(0xFF3F2A78),
          floor: Color(0xFF050618),
          warmth: -0.05,
        );
      case DayStage.night:
        return const AmbientPalette(
          canopy: Color(0xFF050817),
          horizon: Color(0xFF1A1240),
          floor: Color(0xFF02030A),
          warmth: -0.20,
        );
    }
  }
}

/// A subtle vertical canopy → horizon → floor wash that sits over
/// the app shell. Updates roughly every minute (and on app resume)
/// so the canvas slowly warms with the user's local sun.
class AmbientLightingLayer extends StatefulWidget {
  const AmbientLightingLayer({
    super.key,
    this.stage,
    this.intensity = 0.55,
  });

  /// Override the stage (useful for trip-stage emotional palettes).
  final DayStage? stage;

  /// 0..1 — how strongly the wash overlays the canvas. 0.55 is the
  /// flagship default; lighter for content-heavy screens.
  final double intensity;

  @override
  State<AmbientLightingLayer> createState() => _AmbientLightingLayerState();
}

class _AmbientLightingLayerState extends State<AmbientLightingLayer> {
  DayStage _stage = DayStage.midday;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    if (widget.stage != null) {
      setState(() => _stage = widget.stage!);
      return;
    }
    final now = DateTime.now();
    setState(() => _stage = DayStageX.fromHour(now.hour));
    // Recompute every 5 minutes for smooth slow drift.
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) _refresh();
    });
  }

  @override
  void didUpdateWidget(AmbientLightingLayer old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final palette = AmbientPalette.of(_stage);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1800),
      child: IgnorePointer(
        key: ValueKey(_stage),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.canopy.withValues(
                  alpha: widget.intensity * (reduce ? 0.4 : 1.0),
                ),
                palette.horizon.withValues(
                  alpha: widget.intensity * 0.16 * (reduce ? 0.4 : 1.0),
                ),
                palette.floor.withValues(
                  alpha: widget.intensity * (reduce ? 0.4 : 1.0),
                ),
              ],
              stops: const [0.0, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
