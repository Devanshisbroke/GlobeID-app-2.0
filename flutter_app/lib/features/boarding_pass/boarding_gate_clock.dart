import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/premium/premium.dart';

/// Departure-board countdown clock to gate close.
///
/// Renders a HH:MM:SS Solari clock that flips down toward boarding
/// time. Fires `HapticPatterns.boardingPulse` when the countdown
/// crosses configurable boundaries (T-30, T-15, T-5, T-0).
class BoardingGateClock extends StatefulWidget {
  const BoardingGateClock({
    super.key,
    required this.gate,
    required this.boardingTime,
    this.tone,
  });

  final String gate;
  final DateTime boardingTime;
  final Color? tone;

  @override
  State<BoardingGateClock> createState() => _BoardingGateClockState();
}

class _BoardingGateClockState extends State<BoardingGateClock> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  final Set<int> _firedBoundaries = {};

  static const _boundaries = [30, 15, 5, 0];

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final r = widget.boardingTime.difference(now);
    setState(() => _remaining = r.isNegative ? Duration.zero : r);
    final mins = _remaining.inMinutes;
    for (final b in _boundaries) {
      if (mins == b && !_firedBoundaries.contains(b)) {
        _firedBoundaries.add(b);
        HapticPatterns.boardingPulse.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    final hh = _remaining.inHours.toString().padLeft(2, '0');
    final mm = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return ContextualSurface(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space4,
        AppTokens.space5,
        AppTokens.space4,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GATE',
                  style: AirportFontStack.gate(context, size: 11).copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55))),
              const SizedBox(height: 4),
              DepartureBoardText(
                text: widget.gate.toUpperCase(),
                charWidth: 32,
                style: AirportFontStack.board(context, size: 32)
                    .copyWith(color: tone),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('BOARDS IN',
                  style: AirportFontStack.gate(context, size: 11).copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55))),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DepartureBoardText(
                    text: '$hh:$mm:$ss',
                    charWidth: 22,
                    style: AirportFontStack.clock(context, size: 28),
                    tone: tone,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
