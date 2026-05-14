import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// `HomeWidgetPreview` — design previews for GlobeID home-screen
/// widgets (iOS WidgetKit / Android AppWidget).
///
/// Three variants, each rendered in its iOS small / medium tile
/// dimensions so the design reads at the size it'll ship at:
///   • TripCountdownWidget — small (158×158)
///   • FxHeartbeatWidget   — small (158×158)
///   • VisaExpiryWidget    — medium (338×158)
///
/// All three compose from existing Os2 primitives (gold gradient,
/// mono-cap, OLED, hairline, watermark). The widget tile dimensions
/// match Apple's small (`systemSmall`) and medium (`systemMedium`)
/// stencils so previews are 1:1 with shipping native code.
enum WidgetSize { small, medium }

class WidgetTileFrame extends StatelessWidget {
  const WidgetTileFrame({
    super.key,
    required this.child,
    this.size = WidgetSize.small,
  });
  final Widget child;
  final WidgetSize size;

  Size get _dims => size == WidgetSize.small
      ? const Size(158, 158)
      : const Size(338, 158);

  @override
  Widget build(BuildContext context) {
    final dims = _dims;
    return Container(
      width: dims.width,
      height: dims.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }
}

class TripCountdownWidget extends StatelessWidget {
  const TripCountdownWidget({
    super.key,
    required this.destination,
    required this.countryFlag,
    required this.daysAway,
    required this.dateLabel,
  });

  /// `Tokyo`
  final String destination;

  /// `🇯🇵` — flag emoji
  final String countryFlag;

  /// `12`
  final int daysAway;

  /// `Nov 24`
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: Os2.foilGoldHero),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Os2Text.monoCap(
                  'GLOBE·ID · TRIP',
                  color: Os2.canvas,
                  size: Os2.textTiny,
                  maxLines: 1,
                ),
              ),
              Text(countryFlag, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const Spacer(),
          Os2Text.credential(
            '$daysAway',
            color: Os2.canvas,
            size: 52,
          ),
          Os2Text.monoCap(
            daysAway == 1 ? 'DAY · UNTIL DEPARTURE' : 'DAYS · UNTIL DEPARTURE',
            color: Os2.canvas,
            size: Os2.textTiny,
          ),
          const SizedBox(height: 6),
          Os2Text.title(
            destination,
            color: Os2.canvas,
            size: Os2.textRg,
            maxLines: 1,
          ),
          Os2Text.monoCap(
            dateLabel.toUpperCase(),
            color: Os2.canvas,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class FxHeartbeatWidget extends StatelessWidget {
  const FxHeartbeatWidget({
    super.key,
    required this.pair,
    required this.rate,
    required this.deltaPct,
    required this.spark,
  });

  /// `EUR/USD`
  final String pair;

  /// `1.0934`
  final double rate;

  /// `+0.72` (percent)
  final double deltaPct;

  /// 0..1 normalized samples for the sparkline.
  final List<double> spark;

  Color get _deltaTone =>
      deltaPct >= 0 ? const Color(0xFF10B981) : const Color(0xFFE05A52);

  String get _deltaText {
    final sign = deltaPct >= 0 ? '+' : '';
    return '$sign${deltaPct.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Os2.canvas,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Os2Text.monoCap(
                  pair.toUpperCase(),
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                  maxLines: 1,
                ),
              ),
              Os2Text.monoCap(
                _deltaText,
                color: _deltaTone,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Os2Text.credential(
            rate.toStringAsFixed(4),
            color: Os2.inkBright,
            size: 26,
          ),
          const Spacer(),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(
                samples: spark,
                stroke: _deltaTone,
              ),
            ),
          ),
          Os2Text.monoCap(
            'FX · LIVE · 5M',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.samples, required this.stroke});
  final List<double> samples;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final paint = Paint()
      ..color = stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    final dx = size.width / (samples.length - 1);
    for (var i = 0; i < samples.length; i++) {
      final x = i * dx;
      final y = size.height - samples[i].clamp(0.0, 1.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Gold dot on the last point for the "live tick" feel.
    final lastX = (samples.length - 1) * dx;
    final lastY = size.height - samples.last.clamp(0.0, 1.0) * size.height;
    final dot = Paint()..color = Os2.goldDeep;
    canvas.drawCircle(Offset(lastX, lastY), 2.4, dot);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.samples != samples || old.stroke != stroke;
}

class VisaExpiryWidget extends StatelessWidget {
  const VisaExpiryWidget({
    super.key,
    required this.country,
    required this.countryFlag,
    required this.expiryLabel,
    required this.daysToExpiry,
  });
  final String country;
  final String countryFlag;
  final String expiryLabel;
  final int daysToExpiry;

  Color get _tone {
    if (daysToExpiry <= 0) return const Color(0xFFE05A52);
    if (daysToExpiry <= 14) return const Color(0xFFE05A52);
    if (daysToExpiry <= 30) return Os2.goldDeep;
    return const Color(0xFF6B8FB8);
  }

  String get _handle {
    if (daysToExpiry < 0) return 'EXPIRED ${-daysToExpiry}D AGO';
    if (daysToExpiry == 0) return 'EXPIRES TODAY';
    if (daysToExpiry <= 14) return 'CRITICAL · ${daysToExpiry}D';
    if (daysToExpiry <= 30) return 'WARNING · ${daysToExpiry}D';
    return 'NOTICE · ${daysToExpiry}D';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Os2.canvas,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 88,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _tone.withValues(alpha: 0.62)),
            ),
            child: Center(
              child: Text(
                countryFlag,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Os2Text.monoCap(
                  'VISA · ${country.toUpperCase()}',
                  color: _tone,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: 6),
                Os2Text.title(
                  daysToExpiry >= 0
                      ? '${daysToExpiry}d remaining'
                      : 'Expired',
                  color: Os2.inkBright,
                  size: Os2.textLg,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Os2Text.monoCap(
                  _handle,
                  color: _tone,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: 4),
                Os2Text.monoCap(
                  'EXPIRES · ${expiryLabel.toUpperCase()}',
                  color: Os2.inkLow,
                  size: Os2.textTiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Deterministic sample sparkline samples used by the preview.
/// Real bindings will replace this with a 30-tick rolling buffer.
List<double> sparklineSamples({int count = 16, int seed = 7}) {
  final rng = math.Random(seed);
  return List<double>.generate(count, (_) => 0.18 + rng.nextDouble() * 0.78);
}
