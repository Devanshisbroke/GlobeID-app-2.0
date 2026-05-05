import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Kiosk simulator v2 — full-stage face capture preview with animated
/// scan ring, status messages, retry. Demo only — no real camera.
class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  String _status = 'Stand in frame';
  bool _scanning = false;
  bool _verified = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _scanning = true;
      _verified = false;
      _status = 'Aligning…';
    });
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _verified = true;
      _status = 'Verified';
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Kiosk simulator',
      subtitle: 'Practice biometric identity verification',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              child: SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => SizedBox(
                        width: 240,
                        height: 240,
                        child: CustomPaint(
                          painter: _FaceFrame(
                            progress: _ctrl.value,
                            scanning: _scanning,
                            verified: _verified,
                            color: theme.colorScheme.primary,
                          ),
                          child: Center(
                            child: Icon(
                              _verified
                                  ? Icons.verified_user_rounded
                                  : Icons.face_retouching_natural_rounded,
                              size: 96,
                              color: _verified
                                  ? const Color(0xFF10B981)
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Text(_status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
              child: Pressable(
                scale: 0.97,
                onTap: _scanning ? () {} : _start,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow:
                        AppTokens.shadowMd(tint: theme.colorScheme.primary),
                  ),
                  child: Text(
                    _verified
                        ? 'Verify again'
                        : (_scanning ? 'Scanning…' : 'Start verification'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How this works',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Stand 50–80cm from the camera, look straight ahead, and stay still while the kiosk captures a 3-D depth map of your face.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceFrame extends CustomPainter {
  _FaceFrame({
    required this.progress,
    required this.scanning,
    required this.verified,
    required this.color,
  });
  final double progress;
  final bool scanning;
  final bool verified;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 12;
    final c = Offset(size.width / 2, size.height / 2);
    // Outer dashed ring.
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const segments = 36;
    for (var i = 0; i < segments; i++) {
      if (i.isOdd) continue;
      final a1 = i / segments * 2 * math.pi;
      final a2 = (i + 0.6) / segments * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a1,
        a2 - a1,
        false,
        dashPaint,
      );
    }
    // Sweep arc when scanning.
    if (scanning) {
      final sweep = Paint()
        ..shader = SweepGradient(
          colors: [Colors.transparent, color],
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: GradientRotation(progress * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        progress * 2 * math.pi,
        math.pi * 0.7,
        false,
        sweep,
      );
    }
    // Verified ring.
    if (verified) {
      final ok = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(c, r, ok);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceFrame old) =>
      old.progress != progress ||
      old.scanning != scanning ||
      old.verified != verified;
}
