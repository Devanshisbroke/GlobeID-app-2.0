import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/security/session_lock_provider.dart';
import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_text.dart';

/// OS 2.0 — Lock screen.
///
/// A cinematic OLED-first lock with a breathing identity shield, a
/// status ribbon (system / encryption / sync / location), an unlock
/// keypad, and a "passport sync" eyebrow.
class Os2LockScreen extends ConsumerStatefulWidget {
  const Os2LockScreen({super.key});

  @override
  ConsumerState<Os2LockScreen> createState() => _Os2LockScreenState();
}

class _Os2LockScreenState extends ConsumerState<Os2LockScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: Os2.mBreathSlow,
  )..repeat(reverse: true);

  String _input = '';

  @override
  void dispose() {
    _ring.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _press(String key) {
    if (key == 'del') {
      if (_input.isEmpty) return;
      setState(() => _input = _input.substring(0, _input.length - 1));
      HapticFeedback.selectionClick();
      return;
    }
    if (_input.length >= 6) return;
    setState(() => _input = '$_input$key');
    HapticFeedback.selectionClick();
    if (_input.length == 6) {
      _attempt();
    }
  }

  Future<void> _attempt() async {
    // Demo: any 6-digit string unlocks. Real impl would reach into
    // session lock provider.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    ref.read(sessionLockProvider.notifier).unlock();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ring,
                builder: (_, __) => CustomPaint(
                  painter: _LockHaloPainter(progress: _ring.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Os2.space5),
                  Row(
                    children: [
                      Os2Beacon(label: 'LOCKED', tone: Os2.signalCritical),
                      const Spacer(),
                      Os2Text.monoCap(
                        DateTime.now()
                            .toIso8601String()
                            .substring(11, 16),
                        color: Os2.inkMid,
                        size: 11,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Os2Breathing(
                    minScale: 0.99,
                    maxScale: 1.01,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _ring,
                            builder: (_, __) => CustomPaint(
                              size: const Size(220, 220),
                              painter: _ShieldPainter(progress: _ring.value),
                            ),
                          ),
                          Os2GlyphHalo(
                            icon: Icons.fingerprint_rounded,
                            tone: Os2.identityTone,
                            size: 116,
                            iconSize: 58,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Os2.space4),
                  Os2Text.display(
                    'GlobeID',
                    color: Os2.inkBright,
                    size: 36,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: Os2.space1),
                  Os2Text.caption(
                    'Sovereign session \u00b7 awaiting your seal',
                    color: Os2.inkMid,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: Os2.space4),
                  _Dots(input: _input),
                  const SizedBox(height: Os2.space4),
                  _Keypad(onPress: _press),
                  const SizedBox(height: Os2.space4),
                  Os2DividerRule(
                    eyebrow: 'SYSTEM',
                    tone: Os2.identityTone,
                    dense: true,
                  ),
                  const SizedBox(height: Os2.space2),
                  Row(
                    children: [
                      Expanded(
                        child: Os2Ribbon(
                          label: 'VAULT',
                          value: 'ENCRYPTED',
                          tone: Os2.signalSettled,
                          dense: true,
                        ),
                      ),
                      const SizedBox(width: Os2.space2),
                      Expanded(
                        child: Os2Ribbon(
                          label: 'SYNC',
                          value: 'IDLE',
                          tone: Os2.inkMid,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Os2.space2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Os2Magnetic(
                        onTap: () {},
                        child: const Os2Chip(
                          label: 'EMERGENCY',
                          icon: Icons.health_and_safety_rounded,
                          tone: Os2.signalCritical,
                        ),
                      ),
                      const SizedBox(width: Os2.space2),
                      Os2Magnetic(
                        onTap: () {},
                        child: const Os2Chip(
                          label: 'PASSCODE LOST',
                          icon: Icons.help_outline_rounded,
                          tone: Os2.inkMid,
                          intensity: Os2ChipIntensity.subtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Os2.space4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.input});
  final String input;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 6; i++) ...[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < input.length ? Os2.identityTone : Colors.transparent,
              border: Border.all(
                color: i < input.length
                    ? Os2.identityTone
                    : Os2.hairlineSoft,
                width: 1.4,
              ),
              boxShadow: i < input.length
                  ? [
                      BoxShadow(
                        color: Os2.identityTone.withValues(alpha: 0.40),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
          ),
          if (i < 5) const SizedBox(width: Os2.space2),
        ],
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onPress});
  final void Function(String key) onPress;

  static const _layout = <List<String?>>[
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    [null, '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _layout) ...[
          Row(
            children: [
              for (final key in row) ...[
                Expanded(child: _Key(label: key, onTap: () {
                  if (key != null) onPress(key);
                })),
              ],
            ],
          ),
          const SizedBox(height: Os2.space2),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const SizedBox(height: 56);
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Os2Magnetic(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: Os2.floor2,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(Os2.rCard),
              side: BorderSide(
                color: Os2.hairline,
                width: Os2.strokeFine,
              ),
            ),
          ),
          child: label == 'del'
              ? Icon(Icons.backspace_outlined,
                  color: Os2.inkHigh, size: 18)
              : Os2Text.display(
                  label!,
                  color: Os2.inkBright,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final base = Paint()
      ..color = Os2.identityTone.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 4, base);

    // Rotating arc.
    final sweep = math.pi * 1.4;
    final start = progress * math.pi * 2;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          Os2.identityTone.withValues(alpha: 0),
          Os2.identityTone,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      start,
      sweep,
      false,
      arc,
    );

    // Tick marks.
    final tick = Paint()
      ..color = Os2.hairline
      ..strokeWidth = 1;
    for (var i = 0; i < 36; i++) {
      final a = (i / 36) * math.pi * 2;
      final p0 = center +
          Offset(math.cos(a) * (radius - 8), math.sin(a) * (radius - 8));
      final p1 = center +
          Offset(math.cos(a) * (radius - 14), math.sin(a) * (radius - 14));
      canvas.drawLine(p0, p1, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter old) =>
      old.progress != progress;
}

class _LockHaloPainter extends CustomPainter {
  _LockHaloPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dy = size.height * 0.35 + math.sin(progress * math.pi * 2) * 8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Os2.identityTone.withValues(alpha: 0.16),
          Os2.identityTone.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, dy), radius: size.width * 0.8));
    canvas.drawCircle(
        Offset(size.width / 2, dy), size.width * 0.8, paint);
  }

  @override
  bool shouldRepaint(covariant _LockHaloPainter old) =>
      old.progress != progress;
}
