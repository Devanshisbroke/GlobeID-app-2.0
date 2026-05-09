import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Hyper-realistic document substrate rendering engine.
///
/// Paints government-grade security backgrounds: guilloché patterns,
/// paper grain texture, micro-text watermarks, and kinegram-style
/// optically variable patterns. Used as the background layer for
/// passport pages, ID cards, boarding passes, and certificates.
class DocumentSubstrate extends StatelessWidget {
  const DocumentSubstrate({
    super.key,
    required this.child,
    this.type = SubstrateType.passport,
    this.tint,
    this.showMicrotext = false,
    this.borderRadius,
  });

  final Widget child;
  final SubstrateType type;
  final Color? tint;
  final bool showMicrotext;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tint ?? Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppTokens.radius2xl),
      child: CustomPaint(
        painter: _SubstratePainter(
          type: type,
          tint: effectiveTint,
          showMicrotext: showMicrotext,
        ),
        child: child,
      ),
    );
  }
}

enum SubstrateType {
  passport,
  idCard,
  boardingPass,
  certificate,
  visa,
}

class _SubstratePainter extends CustomPainter {
  _SubstratePainter({
    required this.type,
    required this.tint,
    required this.showMicrotext,
  });

  final SubstrateType type;
  final Color tint;
  final bool showMicrotext;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base fill ──────────────────────────────────────────
    final baseColor = switch (type) {
      SubstrateType.passport => tint.withValues(alpha: 0.06),
      SubstrateType.idCard => tint.withValues(alpha: 0.04),
      SubstrateType.boardingPass => tint.withValues(alpha: 0.03),
      SubstrateType.certificate =>
        const Color(0xFFFFFBF0).withValues(alpha: 0.08),
      SubstrateType.visa => tint.withValues(alpha: 0.05),
    };
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    // ── Guilloché pattern ──────────────────────────────────
    _paintGuilloche(canvas, size);

    // ── Paper grain noise ──────────────────────────────────
    _paintGrain(canvas, size);

    // ── Microtext watermark ────────────────────────────────
    if (showMicrotext) {
      _paintMicrotext(canvas, size);
    }

    // ── Edge vignette ──────────────────────────────────────
    _paintVignette(canvas, size);
  }

  void _paintGuilloche(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint.withValues(alpha: 0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.sqrt(cx * cx + cy * cy);

    // Concentric rosette pattern — the security backbone
    for (var r = 20.0; r < maxR; r += 18) {
      final path = Path();
      for (var angle = 0.0; angle < math.pi * 2; angle += 0.02) {
        final wobble = math.sin(angle * 12) * 4 + math.cos(angle * 7) * 3;
        final x = cx + (r + wobble) * math.cos(angle);
        final y = cy + (r + wobble) * math.sin(angle);
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Cross-hatch diamond overlay
    final hatchPaint = Paint()
      ..color = tint.withValues(alpha: 0.04)
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    for (var x = -size.height; x < size.width + size.height; x += 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        hatchPaint,
      );
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        hatchPaint,
      );
    }
  }

  void _paintGrain(Canvas canvas, Size size) {
    final rng = math.Random(42); // deterministic seed
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 800; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = rng.nextDouble() * 0.06;
      paint.color = (rng.nextBool() ? Colors.white : Colors.black)
          .withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 0.5 + rng.nextDouble() * 0.5, paint);
    }
  }

  void _paintMicrotext(Canvas canvas, Size size) {
    const text = 'GLOBEID·VERIFIED·SECURE·AUTHENTIC·SOVEREIGN·';
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (var y = 0.0; y < size.height; y += 8) {
      tp.text = TextSpan(
        text: text * 4,
        style: TextStyle(
          color: tint.withValues(alpha: 0.06),
          fontSize: 4,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      );
      tp.layout(maxWidth: size.width * 3);
      tp.paint(canvas, Offset(-((y * 3) % 100), y));
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignette,
    );
  }

  @override
  bool shouldRepaint(covariant _SubstratePainter old) =>
      old.type != type ||
      old.tint != tint ||
      old.showMicrotext != showMicrotext;
}

/// Animated page-curl physics for passport book pages.
///
/// Uses spring-physics to simulate realistic paper bend.
class PageCurlTransition extends StatelessWidget {
  const PageCurlTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final t = animation.value;
        // Simulate page curl with perspective + rotation
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(-math.pi * t * 0.85)
            ..translate(0.0, 0.0, -20.0 * math.sin(math.pi * t)),
          alignment: Alignment.centerLeft,
          child: Opacity(
            opacity: (1 - t * 0.7).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
