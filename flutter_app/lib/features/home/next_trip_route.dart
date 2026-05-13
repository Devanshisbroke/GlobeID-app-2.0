import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/airports.dart';
import '../../widgets/bible/bible.dart';
import '../../widgets/pressable.dart';

/// Lightweight, typographic-only "next trip" hero card.
///
/// The heavy 3D globe (and any 2D map / great-circle arc) has been
/// removed from the codebase. This widget replaces the old
/// `HomeMiniGlobe` with a pure cinematic typographic ribbon:
///
///   ┌────────────────────────────────────────────────────────────┐
///   │  Next departure                                            │
///   │                                                            │
///   │   SFO   ▸ ▸ ▸ ▸ ▸ ▸ ▸ ▸ ▸ ▸   LHR                          │
///   │   San Francisco                London                      │
///   │                                                            │
///   │   ~ 5,367 km · 11 h 02 m                                   │
///   └────────────────────────────────────────────────────────────┘
///
/// There is no map, no globe, no arc, no continent outline. Pure
/// glass + Solari flap + animated chevron ribbon. Tapping the card
/// jumps into the live trip.
class NextTripRoute extends StatefulWidget {
  const NextTripRoute({
    super.key,
    this.height = 180,
    this.fromCode,
    this.toCode,
    this.label = 'Next departure',
    this.onTap,
  });

  final double height;

  /// IATA code of origin (e.g. `SFO`). When null the card renders an
  /// empty-state placeholder so it never appears blank.
  final String? fromCode;

  /// IATA code of destination (e.g. `LHR`). See [fromCode].
  final String? toCode;

  final String label;
  final VoidCallback? onTap;

  @override
  State<NextTripRoute> createState() => _NextTripRouteState();
}

class _NextTripRouteState extends State<NextTripRoute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = getAirport(widget.fromCode);
    final to = getAirport(widget.toCode);
    final hasRoute = from != null && to != null;
    final distanceKm = hasRoute
        ? haversineKm(from.lat, from.lng, to.lat, to.lng).round()
        : null;
    // Flight time estimate: ~840 km/h cruise + 30 min taxi/climb.
    final durationMin = distanceKm == null
        ? null
        : (distanceKm / 840 * 60 + 30).round();

    final accent = BibleTone.jetCyan;
    final body = SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          AppTokens.space4,
          AppTokens.space5,
          AppTokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Text(
                  widget.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            // Origin + chevron ribbon + destination — all typographic.
            // FittedBox prevents overflow on Pixel-class viewports.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SolariFlap(
                      text: hasRoute ? from.iata : '— —',
                      cellWidth: 22,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Departure Mono',
                        fontWeight: FontWeight.w800,
                        color: BibleTone.foilGold,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    SizedBox(
                      width: 84,
                      height: 18,
                      child: _ChevronRibbon(
                        controller: _ticker,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    SolariFlap(
                      text: hasRoute ? to.iata : '— —',
                      cellWidth: 22,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Departure Mono',
                        fontWeight: FontWeight.w800,
                        color: BibleTone.foilGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasRoute ? from.city : 'No upcoming flight',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.86),
                        ),
                      ),
                      Text(
                        hasRoute ? from.country : 'Tap plan to begin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasRoute ? to.city : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.86),
                        ),
                      ),
                      Text(
                        hasRoute ? to.country : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (distanceKm != null && durationMin != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space2),
                child: Row(
                  children: [
                    Icon(Icons.straighten_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatKm(distanceKm)} km',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Icon(Icons.schedule_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(durationMin),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Pressable(
      semanticLabel: hasRoute ? 'Next trip route' : 'Plan a trip',
      semanticHint: hasRoute ? 'opens travel screen' : 'opens trip planner',
      onTap: widget.onTap ??
          () {
            if (hasRoute) {
              context.push('/travel');
            } else {
              context.push('/planner');
            }
          },
      child: LiquidGlass(
        thickness: LiquidGlassThickness.regular,
        radius: AppTokens.radius2xl,
        tint: accent,
        shadow: LiquidGlassShadow.cinematic,
        stroke: true,
        specular: true,
        child: body,
      ),
    );
  }

  static String _formatKm(int km) {
    if (km < 1000) return '$km';
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final tailLen = s.length - i - 1;
      if (tailLen > 0 && tailLen % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  static String _formatDuration(int totalMin) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final mm = m.toString().padLeft(2, '0');
    return '${h}h ${mm}m';
  }
}

/// Animated chevron ribbon — a row of fading `▸` glyphs that drift
/// left-to-right. Replaces any geographic arc with pure typography.
class _ChevronRibbon extends StatelessWidget {
  const _ChevronRibbon({required this.controller, required this.color});

  final Animation<double> controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        const count = 7;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < count; i++)
              _ChevronGlyph(
                progress: controller.value,
                index: i,
                count: count,
                color: color,
              ),
          ],
        );
      },
    );
  }
}

class _ChevronGlyph extends StatelessWidget {
  const _ChevronGlyph({
    required this.progress,
    required this.index,
    required this.count,
    required this.color,
  });

  final double progress;
  final int index;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Each chevron's phase is offset around the loop. We compute a
    // 0..1 local progress per glyph, used both for x-offset and
    // opacity so the ribbon fades in/out smoothly at the edges.
    final phase = (progress + index / count) % 1.0;
    const spread = 76.0;
    final dx = -spread / 2 + spread * phase;
    final fadeIn = math.min(1.0, phase / 0.15);
    final fadeOut = math.min(1.0, (1.0 - phase) / 0.15);
    final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Opacity(
        opacity: alpha,
        child: Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: color,
        ),
      ),
    );
  }
}
