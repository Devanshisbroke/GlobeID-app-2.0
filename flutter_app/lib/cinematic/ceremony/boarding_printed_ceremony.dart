import 'package:flutter/material.dart';

import '../../motion/motion.dart' show Haptics;
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Cinematic phases of the boarding "PRINTED" reveal. The boarding
/// pass exits an animated printer slot one frame at a time, the
/// printer strikes a haptic with every advancement, and the pass
/// snaps into final position with one consolidated signature.
enum BoardingPrintedPhase {
  /// Idle: pass still inside the printer, slot lit.
  idle,

  /// 0 → 0.20 — printer slot lights up. SLOT · IDLE → SLOT · ARMED
  /// indicator, a thin gold underline ramps in across the slot.
  slotArm,

  /// 0.20 → 0.85 — pass extrudes from the slot. The visible portion
  /// grows from a thin sliver to the full pass height, while a
  /// printer-stripe band animates across the emerging edge. Five
  /// equally-spaced printer-strike haptics fire as the pass passes
  /// 0.30, 0.45, 0.60, 0.72, 0.82 to mimic a roller printer.
  extrude,

  /// 0.85 → 0.95 — pass settles. A 6 px overshoot bounces back to
  /// rest as the pass clears the slot. Signature haptic at 0.85.
  settle,

  /// 0.95 → 1.0 — `PRINTED · BARAI/D · LH1842` ribbon drops in
  /// below the pass.
  ribbon,

  /// 1.0 — fully presented.
  presented,
}

extension BoardingPrintedPhaseX on BoardingPrintedPhase {
  String get handle => switch (this) {
        BoardingPrintedPhase.idle => 'IDLE',
        BoardingPrintedPhase.slotArm => 'SLOT · ARM',
        BoardingPrintedPhase.extrude => 'EXTRUDE',
        BoardingPrintedPhase.settle => 'SETTLE',
        BoardingPrintedPhase.ribbon => 'RIBBON',
        BoardingPrintedPhase.presented => 'PRESENTED',
      };
}

/// Pure mapping from `0..1` progress to the current phase.
BoardingPrintedPhase boardingPrintedPhaseFor(double t) {
  if (t <= 0) return BoardingPrintedPhase.idle;
  if (t < 0.20) return BoardingPrintedPhase.slotArm;
  if (t < 0.85) return BoardingPrintedPhase.extrude;
  if (t < 0.95) return BoardingPrintedPhase.settle;
  if (t < 1.0) return BoardingPrintedPhase.ribbon;
  return BoardingPrintedPhase.presented;
}

/// Visible-for-test: how much of the pass is extruded at progress
/// [t]. Returns 0.0 (entirely in slot) → 1.0 (fully out of slot).
double computePassExtrusion(double t) {
  if (t < 0.20) return 0.0;
  if (t >= 0.85) return 1.0;
  final local = (t - 0.20) / 0.65;
  return Curves.easeInOutCubic.transform(local);
}

const _strikePoints = [0.30, 0.45, 0.60, 0.72, 0.82];

/// Boarding pass "PRINTED" cinematic — the pass exits a printer
/// slot with roller-strike haptics and a final signature haptic
/// on the settle frame.
class BoardingPrintedCeremony extends StatefulWidget {
  const BoardingPrintedCeremony({
    super.key,
    required this.play,
    this.duration = const Duration(milliseconds: 2400),
    this.onPresented,
    this.passenger = 'BARAI · DEVANSH',
    this.flight = 'LH · 1842',
    this.from = 'BLR · BENGALURU',
    this.to = 'MUC · MÜNCHEN',
    this.seat = '08A',
    this.gate = 'B · 27',
  });

  final bool play;
  final Duration duration;
  final VoidCallback? onPresented;
  final String passenger;
  final String flight;
  final String from;
  final String to;
  final String seat;
  final String gate;

  @override
  State<BoardingPrintedCeremony> createState() =>
      _BoardingPrintedCeremonyState();
}

class _BoardingPrintedCeremonyState extends State<BoardingPrintedCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _firedStrikes = <double>{};
  bool _signatureFired = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addListener(_onProgress);
    _c.addStatusListener(_onStatus);
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant BoardingPrintedCeremony old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) _c.duration = widget.duration;
    if (widget.play && !old.play) {
      _firedStrikes.clear();
      _signatureFired = false;
      _c.forward(from: 0);
    } else if (!widget.play && old.play) {
      _c.value = 0;
      _firedStrikes.clear();
      _signatureFired = false;
    }
  }

  void _onProgress() {
    final t = _c.value;
    for (final p in _strikePoints) {
      if (!_firedStrikes.contains(p) && t >= p) {
        _firedStrikes.add(p);
        Haptics.selection();
      }
    }
    if (!_signatureFired && t >= 0.85) {
      _signatureFired = true;
      Haptics.signature();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onPresented?.call();
  }

  @override
  void dispose() {
    _c.removeListener(_onProgress);
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final extrusion = computePassExtrusion(t);
          final settleOvershoot =
              t >= 0.85 && t < 0.95
                  ? 6 * (1 - (t - 0.85) / 0.10)
                  : 0.0;
          final ribbonOpacity = ((t - 0.92) / 0.08).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PrinterSlot(armed: t > 0.05),
                  const SizedBox(height: 4),
                  ClipRect(
                    child: SizedBox(
                      height: 168 * extrusion,
                      child: Transform.translate(
                        offset: Offset(0, -168 * (1 - extrusion) + settleOvershoot),
                        child: _BoardingPass(
                          passenger: widget.passenger,
                          flight: widget.flight,
                          from: widget.from,
                          to: widget.to,
                          seat: widget.seat,
                          gate: widget.gate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: ribbonOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: Os2.foilGoldHero,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Os2Text.monoCap(
                        'PRINTED · ${widget.passenger.split(' · ').first} · ${widget.flight}',
                        color: Os2.canvas,
                        size: Os2.textTiny,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrinterSlot extends StatelessWidget {
  const _PrinterSlot({required this.armed});
  final bool armed;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Os2.hairline),
        boxShadow: armed
            ? [
                BoxShadow(
                  color: Os2.goldDeep.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 3,
          decoration: BoxDecoration(
            gradient: armed
                ? Os2.foilGoldHero
                : const LinearGradient(
                    colors: [Color(0xFF222226), Color(0xFF333338)],
                  ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _BoardingPass extends StatelessWidget {
  const _BoardingPass({
    required this.passenger,
    required this.flight,
    required this.from,
    required this.to,
    required this.seat,
    required this.gate,
  });
  final String passenger;
  final String flight;
  final String from;
  final String to;
  final String seat;
  final String gate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Os2Text.monoCap(
                    'BOARDING · PASS',
                    color: Os2.goldDeep,
                    size: Os2.textTiny,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Os2Text.monoCap(
                    flight,
                    color: Os2.inkBright,
                    size: Os2.textTiny,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Os2Text.display(
            passenger,
            color: Os2.inkBright,
            size: Os2.textLg,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap(
                      'FROM',
                      color: Os2.inkLow,
                      size: Os2.textTiny,
                    ),
                    Os2Text.monoCap(
                      from,
                      color: Os2.inkBright,
                      size: Os2.textTiny,
                    ),
                  ],
                ),
              ),
              Os2Text.monoCap(
                '→',
                color: Os2.goldDeep,
                size: Os2.textXs,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Os2Text.monoCap(
                      'TO',
                      color: Os2.inkLow,
                      size: Os2.textTiny,
                    ),
                    Os2Text.monoCap(
                      to,
                      color: Os2.inkBright,
                      size: Os2.textTiny,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap(
                      'SEAT',
                      color: Os2.inkLow,
                      size: Os2.textTiny,
                    ),
                    Os2Text.credential(seat, color: Os2.inkBright, size: 18),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Os2Text.monoCap(
                    'GATE',
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                  Os2Text.credential(gate, color: Os2.goldDeep, size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
