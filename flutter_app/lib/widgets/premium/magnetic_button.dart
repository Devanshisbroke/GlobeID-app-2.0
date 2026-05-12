import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../nexus/nexus_tokens.dart';
import 'magnetic_pressable.dart';

/// Flagship CTA — **Nexus-aligned champagne pill.**
///
/// Was a multi-layer breathing gradient with a glow halo, sheen wash,
/// and white-on-white touch ripple. After the canonical Travel-OS /
/// Wallet migration this primitive renders the Lovable champagne CTA
/// language across all 6+ callers (boarding, lock, passport, wallet
/// hero, multi-currency pour, premium showcase):
///
///   - flat champagne fill (`N.tierGold`) with a 0.5pt `tierGoldHi`
///     hairline border
///   - inky black label (550 weight, +0.2 tracking)
///   - icon at high contrast (no white-on-white)
///   - subtle touch ripple still fires, but ink-coloured (not white)
///     so it reads naturally on the gold body
///   - magnetic touch follow + press scale 0.965 preserved
///   - **no breathing halo / no shadow / no sheen** — depth is
///     conveyed by contrast and the hairline alone (Nothing-OS
///     / Linear language)
///
/// The `gradient` parameter is still honoured for legacy callers that
/// pass a custom palette; in that case the label / icon falls back to
/// white. Public API preserved 1:1.
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
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Offset? _ripplePoint;

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _fireRipple(Offset point) {
    setState(() => _ripplePoint = point);
    _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(N.rPill);
    final padH = widget.compact ? AppTokens.space2 + 2 : AppTokens.space6;
    final padV = widget.compact ? AppTokens.space2 + 2 : 14.0;

    final hasGradient = widget.gradient != null;
    final fillDecoration = hasGradient
        ? BoxDecoration(
            gradient: widget.gradient,
            borderRadius: radius,
            border: Border.all(
              color: N.hairlineHi,
              width: N.strokeHair,
            ),
          )
        : BoxDecoration(
            color: N.tierGold,
            borderRadius: radius,
            border: Border.all(
              color: N.tierGoldHi.withValues(alpha: 0.72),
              width: N.strokeHair,
            ),
          );

    final iconColor = hasGradient ? Colors.white : N.bg;
    final textColor = hasGradient ? Colors.white : N.bg;

    final body = Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: fillDecoration,
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: iconColor, size: widget.compact ? 16 : 18),
            SizedBox(
                width:
                    widget.compact ? AppTokens.space1 + 2 : AppTokens.space2),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                fontSize: widget.compact ? 13 : 14,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.trailing != null) ...[
            SizedBox(
                width:
                    widget.compact ? AppTokens.space1 + 2 : AppTokens.space2),
            Icon(widget.trailing,
                color: iconColor, size: widget.compact ? 14 : 16),
          ],
        ],
      ),
    );

    final layered = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          body,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
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
                        tone: hasGradient ? Colors.white : N.bg,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
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
        magnetism: 4,
        tilt: 0.02,
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          child: layered,
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.origin,
    required this.progress,
    required this.tone,
  });
  final Offset origin;
  final double progress;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final r = math.sqrt(size.width * size.width + size.height * size.height);
    final radius = r * progress;
    final paint = Paint()
      ..color = tone.withValues(alpha: (1 - progress) * 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawCircle(origin, radius, paint);

    final fill = Paint()
      ..color = tone.withValues(alpha: (1 - progress) * 0.08);
    canvas.drawCircle(origin, radius * 0.6, fill);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.origin != origin || old.progress != progress;
}
