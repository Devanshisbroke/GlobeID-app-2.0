import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';

/// Premium pulse strip — a horizontal row of live system pulse pills
/// used as a status banner ("Wallet · Identity · Globe · Boarding").
/// Each pill renders an animated dot + label + optional value.
///
/// Pure-Dart, deterministic — caller owns the data, the strip just
/// draws. Honors `disableAnimations`.
class PremiumPulseStrip extends StatelessWidget {
  const PremiumPulseStrip({
    super.key,
    required this.pulses,
    this.dense = false,
  });

  final List<PulseTile> pulses;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: dense ? 8 : AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(
          color: N.hairline,
          width: N.strokeHair,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < pulses.length; i++) ...[
            Expanded(child: _PulseTile(tile: pulses[i], dense: dense)),
            if (i != pulses.length - 1)
              Container(
                width: 0.5,
                height: dense ? 18 : 24,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppTokens.space2),
                color: N.hairline,
              ),
          ],
        ],
      ),
    );
  }
}

@immutable
class PulseTile {
  const PulseTile({
    required this.label,
    required this.value,
    required this.tone,
    this.icon,
  });
  final String label;
  final String value;
  final Color tone;
  final IconData? icon;
}

class _PulseTile extends StatefulWidget {
  const _PulseTile({required this.tile, required this.dense});
  final PulseTile tile;
  final bool dense;

  @override
  State<_PulseTile> createState() => _PulseTileState();
}

class _PulseTileState extends State<_PulseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = reduce ? 0.0 : _c.value;
        final opacity = (0.55 + (1 - t) * 0.45).clamp(0.0, 1.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.tile.tone.withValues(alpha: opacity),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tile.label.toUpperCase(),
                    style: TextStyle(
                      color: N.inkLow,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      fontSize: widget.dense ? 9 : 9.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.tile.value,
                    style: TextStyle(
                      color: N.inkHi,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.dense ? 12 : 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
