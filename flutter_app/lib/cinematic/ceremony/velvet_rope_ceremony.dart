import 'package:flutter/material.dart';

import '../../motion/motion.dart' show Haptics;
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Lounge admission velvet rope ceremony phases. A gold velvet
/// rope (clipped between two brass stanchions) lifts off the
/// floor, the world behind dims to OLED black, the MEMBER pip
/// pulses, and the lounge interior reveals beneath.
enum VelvetRopePhase {
  closed,
  brassArm,
  ropeLift,
  worldDim,
  memberReveal,
  admitted,
}

extension VelvetRopePhaseX on VelvetRopePhase {
  String get handle => switch (this) {
        VelvetRopePhase.closed => 'CLOSED',
        VelvetRopePhase.brassArm => 'BRASS · ARM',
        VelvetRopePhase.ropeLift => 'ROPE · LIFT',
        VelvetRopePhase.worldDim => 'WORLD · DIM',
        VelvetRopePhase.memberReveal => 'MEMBER · REVEAL',
        VelvetRopePhase.admitted => 'ADMITTED',
      };
}

VelvetRopePhase velvetRopePhaseFor(double t) {
  if (t <= 0) return VelvetRopePhase.closed;
  if (t < 0.16) return VelvetRopePhase.brassArm;
  if (t < 0.55) return VelvetRopePhase.ropeLift;
  if (t < 0.75) return VelvetRopePhase.worldDim;
  if (t < 1.0) return VelvetRopePhase.memberReveal;
  return VelvetRopePhase.admitted;
}

/// Visible-for-test: how high the velvet rope has lifted (0 → 1).
/// 0 = on the floor, 1 = fully lifted and clearing the stanchion.
double computeRopeLift(double t) {
  if (t < 0.16) return 0;
  if (t >= 0.55) return 1;
  final local = (t - 0.16) / 0.39;
  return Curves.easeOutCubic.transform(local);
}

/// Visible-for-test: world dim opacity at progress [t]. Returns
/// 0 (no dim) → 0.78 (max dim) across [0.55, 0.75].
double computeWorldDim(double t) {
  if (t < 0.55) return 0;
  if (t >= 0.75) return 0.78;
  final local = (t - 0.55) / 0.20;
  return 0.78 * Curves.easeOutCubic.transform(local);
}

class VelvetRopeCeremony extends StatefulWidget {
  const VelvetRopeCeremony({
    super.key,
    required this.play,
    this.duration = const Duration(milliseconds: 2800),
    this.onAdmitted,
    this.tier = 'PLATINUM',
    this.member = 'BARAI · DEVANSH',
    this.lounge = 'STAR · ALLIANCE · LOUNGE · MUC',
  });

  final bool play;
  final Duration duration;
  final VoidCallback? onAdmitted;
  final String tier;
  final String member;
  final String lounge;

  @override
  State<VelvetRopeCeremony> createState() => _VelvetRopeCeremonyState();
}

class _VelvetRopeCeremonyState extends State<VelvetRopeCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _liftFired = false;
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
  void didUpdateWidget(covariant VelvetRopeCeremony old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) _c.duration = widget.duration;
    if (widget.play && !old.play) {
      _liftFired = false;
      _signatureFired = false;
      _c.forward(from: 0);
    } else if (!widget.play && old.play) {
      _c.value = 0;
      _liftFired = false;
      _signatureFired = false;
    }
  }

  void _onProgress() {
    final t = _c.value;
    if (!_liftFired && t >= 0.16) {
      _liftFired = true;
      Haptics.selection();
    }
    if (!_signatureFired && t >= 0.75) {
      _signatureFired = true;
      Haptics.signature();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onAdmitted?.call();
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
          final lift = computeRopeLift(t);
          final dim = computeWorldDim(t);
          final memberOpacity = t >= 0.78
              ? ((t - 0.78) / 0.22).clamp(0.0, 1.0)
              : 0.0;
          return SizedBox(
            width: 320,
            height: 380,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Os2.rCard),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A1A1F),
                        Color(0xFF050505),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 60),
                    child: Opacity(
                      opacity: (1 - dim / 0.78).clamp(0.0, 1.0),
                      child: _LoungeInterior(),
                    ),
                  ),
                ),
                if (dim > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Os2.rCard),
                        color: const Color(0xFF050505).withValues(alpha: dim),
                      ),
                    ),
                  ),
                Positioned(
                  left: 36,
                  bottom: 60,
                  child: _Stanchion(armed: t > 0.05),
                ),
                Positioned(
                  right: 36,
                  bottom: 60,
                  child: _Stanchion(armed: t > 0.05),
                ),
                Positioned(
                  left: 56,
                  right: 56,
                  bottom: 130 + 80 * lift,
                  child: Transform.rotate(
                    angle: -0.03 * (1 - lift),
                    child: _VelvetRope(catenary: 1 - lift),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: memberOpacity,
                      child: _MemberCard(
                        tier: widget.tier,
                        member: widget.member,
                        lounge: widget.lounge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stanchion extends StatelessWidget {
  const _Stanchion({required this.armed});
  final bool armed;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: armed
                ? Os2.foilGoldHero
                : const LinearGradient(
                    colors: [Color(0xFF333333), Color(0xFF222222)],
                  ),
            boxShadow: armed
                ? [
                    BoxShadow(
                      color: Os2.goldDeep.withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
        ),
        Container(
          width: 4,
          height: 80,
          color: armed ? Os2.goldDeep : const Color(0xFF333333),
        ),
        Container(
          width: 18,
          height: 6,
          decoration: BoxDecoration(
            color: armed ? Os2.goldDeep : const Color(0xFF333333),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _VelvetRope extends StatelessWidget {
  const _VelvetRope({required this.catenary});

  /// 0 = perfectly straight (lifted), 1 = full sag (closed).
  final double catenary;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 30),
      painter: _VelvetRopePainter(catenary: catenary),
    );
  }
}

class _VelvetRopePainter extends CustomPainter {
  _VelvetRopePainter({required this.catenary});
  final double catenary;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final sag = 22 * catenary;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(w / 2, sag, w, 0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF7B1A1A),
          const Color(0xFFB73E3E),
          const Color(0xFF7B1A1A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, 30));
    canvas.drawPath(path, paint);
    // Gold seam highlight.
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFE9C75D).withValues(alpha: 0.7);
    final highPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(w / 2, sag, w, 0);
    canvas.drawPath(highPath, highlight);
  }

  @override
  bool shouldRepaint(covariant _VelvetRopePainter old) =>
      old.catenary != catenary;
}

class _LoungeInterior extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(
          'LOUNGE · INTERIOR',
          color: Os2.goldDeep,
          size: Os2.textTiny,
        ),
        const SizedBox(height: 8),
        for (final row in const [
          'CHAMPAGNE · BAR · OPEN',
          'SPA · ROOM · 6 · AVAILABLE',
          'SHOWER · SUITES · 12 · 18 · OPEN',
          'BUFFET · CONCIERGE · ON',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Os2Text.monoCap(
              row,
              color: Os2.inkMid,
              size: Os2.textTiny,
            ),
          ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.tier,
    required this.member,
    required this.lounge,
  });
  final String tier;
  final String member;
  final String lounge;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.32),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: Os2.foilGoldHero,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Os2Text.monoCap(
                  tier,
                  color: Os2.canvas,
                  size: Os2.textTiny,
                ),
              ),
              const Spacer(),
              Os2Text.monoCap(
                'ADMITTED',
                color: const Color(0xFF2E5A2E),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Os2Text.display(
            member,
            color: Os2.inkBright,
            size: Os2.textLg,
          ),
          const SizedBox(height: 4),
          Os2Text.monoCap(
            lounge,
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}
