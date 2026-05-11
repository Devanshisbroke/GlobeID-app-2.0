import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/sensor_fusion.dart';
import '../../motion/haptic_choreography.dart';

/// Premium credential gallery — a sensor-reactive 3D card stack that
/// shows the user's verifiable credentials (passport, license,
/// boarding pass, hotel key, lounge access, eSIM, payment).
///
/// Cards stack vertically with a depth offset, the active card sits
/// on top, and a horizontal swipe rotates the active card off and the
/// next card forward. Sensor pendulum tilts the whole stack subtly
/// based on accelerometer input. Reduce-motion kills sensor reaction.
class CredentialGallery extends StatefulWidget {
  const CredentialGallery({
    super.key,
    required this.cards,
    this.height = 220,
    this.onTap,
  });

  final List<CredentialCardData> cards;
  final double height;
  final void Function(int index)? onTap;

  @override
  State<CredentialGallery> createState() => _CredentialGalleryState();
}

class _CredentialGalleryState extends State<CredentialGallery>
    with TickerProviderStateMixin {
  late final AnimationController _swipe;
  late final AnimationController _ticker;
  int _index = 0;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _swipe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    SensorFusion.instance.acquire();
  }

  @override
  void dispose() {
    _swipe.dispose();
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  void _advance() {
    HapticPatterns.magneticSnap.play();
    _swipe.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.cards.length;
        _drag = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) {
          setState(() => _drag = (_drag + d.delta.dx).clamp(-180, 180));
        },
        onHorizontalDragEnd: (d) {
          if (_drag.abs() > 90 || d.primaryVelocity!.abs() > 800) {
            _advance();
          } else {
            setState(() => _drag = 0);
          }
        },
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call(_index);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_swipe, _ticker]),
          builder: (_, __) {
            final swipeT = _swipe.value;
            final tilt = reduce
                ? 0.0
                : (SensorFusion.instance.tiltY / 0.18).clamp(-1.0, 1.0) * 0.32;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var i = widget.cards.length - 1; i >= 0; i--)
                  _buildCard(
                    theme: theme,
                    relIdx: (i - _index + widget.cards.length) %
                        widget.cards.length,
                    data: widget.cards[i],
                    swipeT: swipeT,
                    drag: _drag,
                    tilt: tilt,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({
    required ThemeData theme,
    required int relIdx,
    required CredentialCardData data,
    required double swipeT,
    required double drag,
    required double tilt,
  }) {
    final z = relIdx.clamp(0, 4);
    final scale = 1.0 - z * 0.04;
    final dy = z * 10.0;
    final isActive = relIdx == 0;
    final dragNorm = drag / 180;
    final activeRotY = isActive ? dragNorm * 0.4 + tilt * 0.6 : tilt * 0.18;
    final activeDx = isActive ? drag : 0.0;
    final activeOpacity = isActive ? (1 - swipeT).clamp(0.0, 1.0) : 1.0;
    return Positioned.fill(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..translateByDouble(activeDx, dy, 0.0, 1.0)
          ..rotateY(activeRotY)
          ..scaleByDouble(scale, scale, 1.0, 1.0),
        child: Opacity(
          opacity: activeOpacity,
          child: _CardSurface(data: data, theme: theme),
        ),
      ),
    );
  }
}

@immutable
class CredentialCardData {
  const CredentialCardData({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.tone,
    required this.icon,
    this.gradient,
  });
  final String title;
  final String subtitle;
  final String code;
  final Color tone;
  final IconData icon;
  final List<Color>? gradient;
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.data, required this.theme});
  final CredentialCardData data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = data.gradient ??
        [
          data.tone.withValues(alpha: 0.95),
          data.tone.withValues(alpha: 0.55),
        ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        boxShadow: AppTokens.shadowCinematic(tint: data.tone),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FoilPainter(tone: data.tone),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(data.icon, color: Colors.white, size: 22),
                      const SizedBox(width: AppTokens.space2),
                      Text(
                        data.title.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.subtitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontFamily: 'monospace',
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter({required this.tone});
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (var i = 0; i < 5; i++) {
      p.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      final path = Path();
      final yOffset = size.height / 5 * i;
      path.moveTo(-20, yOffset);
      path.quadraticBezierTo(
        size.width * 0.5,
        yOffset + math.sin(i.toDouble()) * 16,
        size.width + 20,
        yOffset,
      );
      path.lineTo(size.width + 20, yOffset + 36);
      path.quadraticBezierTo(
        size.width * 0.5,
        yOffset + 36 + math.cos(i.toDouble()) * 18,
        -20,
        yOffset + 36,
      );
      path.close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) => old.tone != tone;
}
