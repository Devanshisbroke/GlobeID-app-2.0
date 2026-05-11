import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Ribbon.
///
/// A status ribbon that runs the full width of a slab. Three slots:
///   • leading pulse dot (tone-tinted, breathing);
///   • caption + monoCap value (left-aligned);
///   • trailing monoCap value (right-aligned).
///
/// Used at the top of focal slabs to surface live status without taking
/// vertical space (e.g. "LIVE · GATE B14 · 18:32").
class Os2Ribbon extends StatefulWidget {
  const Os2Ribbon({
    super.key,
    required this.label,
    required this.value,
    this.tone = Os2.signalLive,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final String value;
  final Color tone;
  final String? trailing;
  final bool dense;

  @override
  State<Os2Ribbon> createState() => _Os2RibbonState();
}

class _Os2RibbonState extends State<Os2Ribbon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Os2.mBreathFast,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Os2.space3,
        vertical: widget.dense ? Os2.space1 : Os2.space2,
      ),
      decoration: ShapeDecoration(
        color: Os2.floor1,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(Os2.rChip),
          side: BorderSide(
            color: widget.tone.withValues(alpha: 0.32),
            width: Os2.strokeFine,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final t = Os2.cCruise.transform(_pulse.value);
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.tone,
                  boxShadow: [
                    BoxShadow(
                      color: widget.tone.withValues(alpha: 0.20 + t * 0.35),
                      blurRadius: 6 + t * 4,
                      spreadRadius: t,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: Os2.space2),
          Os2Text.monoCap(
            widget.label,
            color: widget.tone,
            size: widget.dense ? 9 : 10,
          ),
          const SizedBox(width: Os2.space2),
          Os2Text.monoCap(
            widget.value,
            color: Os2.inkBright,
            size: widget.dense ? 10 : 11,
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: Os2.space2),
            Container(
              width: 1,
              height: 10,
              color: Os2.hairline,
            ),
            const SizedBox(width: Os2.space2),
            Os2Text.monoCap(
              widget.trailing!,
              color: Os2.inkMid,
              size: widget.dense ? 9 : 10,
            ),
          ],
        ],
      ),
    );
  }
}
