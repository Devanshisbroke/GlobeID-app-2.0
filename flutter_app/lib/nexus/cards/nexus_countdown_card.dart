import 'dart:async';

import 'package:flutter/material.dart';

import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Giant countdown readout — "Departs in 02:14:45". The digits are
/// monospace tabular figures so they don't jitter as they tick.
class NCountdownCard extends StatefulWidget {
  const NCountdownCard({
    super.key,
    required this.target,
    this.eyebrow = 'departs in',
    this.flight,
    this.route,
  });

  final DateTime target;
  final String eyebrow;
  final String? flight;
  final String? route;

  @override
  State<NCountdownCard> createState() => _NCountdownCardState();
}

class _NCountdownCardState extends State<NCountdownCard> {
  Timer? _t;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final diff = widget.target.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return NPanel(
      padding: N.cardPadLoose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NText.eyebrow11(widget.eyebrow, color: N.inkLow),
          const SizedBox(height: N.s2),
          Text(
            _fmt(_remaining),
            style: NType.display56(color: N.inkHi).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (widget.flight != null || widget.route != null) ...[
            const SizedBox(height: N.s4),
            const NHairline(),
            const SizedBox(height: N.s3),
            Wrap(
              spacing: N.s3,
              runSpacing: N.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.flight != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NText.eyebrow10('flight', color: N.inkLow),
                      const SizedBox(width: N.s2),
                      NText.mono14(widget.flight!, color: N.ink),
                    ],
                  ),
                ],
                if (widget.route != null)
                  NText.mono12(widget.route!, color: N.inkMid),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
