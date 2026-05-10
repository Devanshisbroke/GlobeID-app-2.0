import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import 'magnetic_pressable.dart';

/// Flagship CTA — magnetic, layered, breathing.
///
/// Anatomy (back-to-front):
///   1. accent gradient body
///   2. radial halo glow that breathes (≤ 0.20 sigma)
///   3. top-down sheen wash
///   4. ripple-from-touch ring on tap
///   5. icon + label row (Inter / 700)
///
/// On tap fires [HapticPatterns.confirm]. Wraps the whole surface
/// in a [MagneticPressable] for touch-following motion.
class MagneticButton extends StatefulWidget {
  const MagneticButton({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.onPressed,
    this.gradient,
    this.expand = true,
    this.compact = false,
    this.haptic = HapticPatterns.confirm,
    this.glow = true,
  });

  final String label;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool expand;
  final bool compact;
  final bool glow;
  final HapticSequence haptic;

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton>
    with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Offset? _ripplePoint;

  @override
  void dispose() {
    _breathe.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _fireRipple(Offset point) {
    setState(() => _ripplePoint = point);
    _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final accent = theme.colorScheme.primary;
    final glow = theme.colorScheme.secondary;
    final g = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glow, accent],
        );
    final radius = BorderRadius.circular(AppTokens.radiusFull);
    // Compact CTAs (4-up rows on the wallet hero, etc.) need much
    // tighter horizontal padding so labels like "Convert" / "Receive"
    // don't ellipsis on Pixel-class viewports (≈360-412 dp wide).
    // Verified at 412×915 — was 16/10, now 10/10 = comfortable fit
    // with no truncation.
    final padH = widget.compact ? AppTokens.space2 + 2 : AppTokens.space6;
    final padV = widget.compact ? AppTokens.space2 + 2 : AppTokens.space3 + 2;

    final body = Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon,
                color: Colors.white, size: widget.compact ? 16 : 18),
            SizedBox(
                width:
                    widget.compact ? AppTokens.space1 + 2 : AppTokens.space2),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontSize: widget.compact ? 13 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.trailing != null) ...[
            SizedBox(
                width:
                    widget.compact ? AppTokens.space1 + 2 : AppTokens.space2),
            Icon(widget.trailing,
                color: Colors.white, size: widget.compact ? 14 : 16),
          ],
        ],
      ),
    );

    final layered = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          body,
          // Sheen
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Touch ripple
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ripple,
                builder: (_, __) {
                  if (_ripplePoint == null || _ripple.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _RipplePainter(
                      origin: _ripplePoint!,
                      progress: _ripple.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    final glowing = widget.glow && !reduce
        ? AnimatedBuilder(
            animation: _breathe,
            builder: (_, child) {
              final t = _breathe.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30 + 0.18 * t),
                      blurRadius: 24 + 16 * t,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: layered,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: AppTokens.shadowMd(tint: accent),
            ),
            child: layered,
          );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) _fireRipple(box.globalToLocal(e.position));
      },
      child: MagneticPressable(
        onTap: widget.onPressed == null
            ? null
            : () {
                widget.haptic.play();
                widget.onPressed!();
              },
        haptic: false,
        scale: 0.965,
        magnetism: 6,
        tilt: 0.03,
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          child: glowing,
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.origin, required this.progress});
  final Offset origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final r = math.sqrt(size.width * size.width + size.height * size.height);
    final radius = r * progress;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(origin, radius, paint);

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.10);
    canvas.drawCircle(origin, radius * 0.6, fill);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.origin != origin || old.progress != progress;
}
