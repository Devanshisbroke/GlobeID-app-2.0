import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Status pill.
///
/// Compact tone-tinted pill with a leading breathing dot, optional
/// icon, monoCap label, and optional monoCap value on the right.
/// Used as a status-only indicator (no tap target). For tappable
/// pills, use [Os2Chip] wrapped in [Os2Magnetic].
class Os2StatusPill extends StatefulWidget {
  const Os2StatusPill({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.tone = Os2.signalLive,
    this.dense = false,
    this.breathing = true,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Color tone;
  final bool dense;
  final bool breathing;

  @override
  State<Os2StatusPill> createState() => _Os2StatusPillState();
}

class _Os2StatusPillState extends State<Os2StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: Os2.mBreathFast,
    );
    if (widget.breathing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Os2StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.breathing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.breathing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.dense ? 22.0 : 26.0;
    return Container(
      height: h,
      padding: EdgeInsets.symmetric(
        horizontal: widget.dense ? Os2.space2 : Os2.space3,
      ),
      decoration: ShapeDecoration(
        color: widget.tone.withValues(alpha: 0.10),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(h / 2),
          side: BorderSide(
            color: widget.tone.withValues(alpha: 0.40),
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
              final t = widget.breathing
                  ? Curves.easeInOut.transform(_pulse.value)
                  : 0.6;
              return Container(
                width: widget.dense ? 6 : 7,
                height: widget.dense ? 6 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.tone,
                  boxShadow: [
                    BoxShadow(
                      color: widget.tone.withValues(alpha: 0.5 * t + 0.2),
                      blurRadius: 6 + t * 4,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: widget.dense ? 4 : 6),
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.tone, size: widget.dense ? 10 : 12),
            SizedBox(width: widget.dense ? 3 : 5),
          ],
          Os2Text.monoCap(
            widget.label,
            color: widget.tone,
            size: widget.dense ? 9 : 10,
          ),
          if (widget.value != null) ...[
            SizedBox(width: widget.dense ? 4 : 6),
            Container(
              width: 1,
              height: widget.dense ? 8 : 10,
              color: widget.tone.withValues(alpha: 0.30),
            ),
            SizedBox(width: widget.dense ? 4 : 6),
            Os2Text.monoCap(
              widget.value!,
              color: Os2.inkBright,
              size: widget.dense ? 9 : 10,
            ),
          ],
        ],
      ),
    );
  }
}
