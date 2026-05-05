import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Google-Lens / Adobe-Scan style viewfinder. Renders:
///   - a dimmed background with a clear-cut window
///   - 4 animated corners that pulse gently
///   - a sweeping scanline that travels top→bottom
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({
    super.key,
    this.aspectRatio = 1.0,
    this.tone,
    this.label,
    this.scanlineEnabled = true,
  });

  /// Width / height of the cut-out window. 1.0 = square (QR),
  /// 1.5 ≈ document landscape.
  final double aspectRatio;
  final Color? tone;
  final String? label;
  final bool scanlineEnabled;

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with TickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;

    return LayoutBuilder(builder: (_, c) {
      final size = c.biggest.shortestSide * 0.78;
      final w = size;
      final h = size / widget.aspectRatio;

      return Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _DimMaskPainter(windowSize: Size(w, h)),
          ),
          SizedBox(
            width: w,
            height: h,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                return CustomPaint(
                  painter: _CornersPainter(
                    color: Color.lerp(tone, Colors.white, _pulse.value * 0.3)!,
                    pulse: _pulse.value,
                  ),
                );
              },
            ),
          ),
          if (widget.scanlineEnabled)
            SizedBox(
              width: w,
              height: h,
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ScanlinePainter(
                      progress: _sweep.value,
                      color: tone,
                    ),
                  );
                },
              ),
            ),
          if (widget.label != null)
            Positioned(
              bottom: c.maxHeight * 0.2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4, vertical: AppTokens.space2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text(
                  widget.label!,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: Colors.white, letterSpacing: 0.6),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _DimMaskPainter extends CustomPainter {
  _DimMaskPainter({required this.windowSize});
  final Size windowSize;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final w = windowSize.width;
    final h = windowSize.height;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    final rrect = RRect.fromRectAndRadius(
        rect, const Radius.circular(AppTokens.radius2xl));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);
  }

  @override
  bool shouldRepaint(covariant _DimMaskPainter old) =>
      old.windowSize != windowSize;
}

class _CornersPainter extends CustomPainter {
  _CornersPainter({required this.color, required this.pulse});
  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final len = 28.0 + pulse * 6;
    final r = AppTokens.radius2xl;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: const Radius.circular(20))
        ..lineTo(len, 0),
      p,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(20))
        ..lineTo(size.width, len),
      p,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height - r)
        ..arcToPoint(Offset(size.width - r, size.height),
            radius: const Radius.circular(20))
        ..lineTo(size.width - len, size.height),
      p,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(r, size.height)
        ..arcToPoint(Offset(0, size.height - r),
            radius: const Radius.circular(20))
        ..lineTo(0, size.height - len),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) =>
      old.color != color || old.pulse != pulse;
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.85),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 24, size.width, 48));
    canvas.drawRect(Rect.fromLTWH(0, y - 24, size.width, 48), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter old) =>
      old.progress != progress || old.color != color;
}
