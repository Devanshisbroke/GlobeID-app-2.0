import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Beacon.
///
/// Breathing status indicator. A small dot with a bloom shadow that
/// pulses on a 2.2s sine; an uppercase caption (e.g. "LIVE", "READY",
/// "ARMED", "OFFLINE") sits to the right. Used at the top-right of
/// Mission Control headers and at the corner of focal heroes to read
/// "the system is awake".
class Os2Beacon extends StatefulWidget {
  const Os2Beacon({
    super.key,
    required this.label,
    this.tone = Os2.signalLive,
    this.size = Os2BeaconSize.regular,
  });

  final String label;
  final Color tone;
  final Os2BeaconSize size;

  @override
  State<Os2Beacon> createState() => _Os2BeaconState();
}

enum Os2BeaconSize { compact, regular, large }

class _Os2BeaconState extends State<Os2Beacon>
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

  double get _dotSize {
    switch (widget.size) {
      case Os2BeaconSize.compact:
        return 4;
      case Os2BeaconSize.regular:
        return 6;
      case Os2BeaconSize.large:
        return 8;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case Os2BeaconSize.compact:
        return 9;
      case Os2BeaconSize.regular:
        return 10;
      case Os2BeaconSize.large:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: widget.tone,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.tone.withValues(alpha: 0.5 + 0.35 * t),
                    blurRadius: 5 + 6 * t,
                    spreadRadius: 0.4 + 0.4 * t,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Os2Text.caption(
              widget.label,
              color: widget.tone,
              size: _fontSize,
              weight: FontWeight.w800,
            ),
          ],
        );
      },
    );
  }
}
