import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Live-screen object substrates.
///
/// Each painter renders a hyper-real surface (paper, polymer banknote,
/// PETG transit card, dossier vellum, navigation strip) so the Live
/// objects on top read as physical artefacts rather than UI panels.
///
/// All painters are deterministic (seeded `Random(42)`), so each
/// surface looks identical across builds and `flutter test` runs.

// ─────────────────────────────────────────────────────────────────────
// VISA — gov-grade paper with rosette guilloché, intaglio crest watermark
// ─────────────────────────────────────────────────────────────────────

class VisaSubstrate extends StatelessWidget {
  const VisaSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.crestGlyph = '✦',
    this.cornerCode = 'GBL · VISA',
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });
  final Color tone;
  final Widget child;
  final String crestGlyph;
  final String cornerCode;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _VisaPainter(
          tone: tone,
          crestGlyph: crestGlyph,
          cornerCode: cornerCode,
        ),
        child: child,
      ),
    );
  }
}

class _VisaPainter extends CustomPainter {
  _VisaPainter({
    required this.tone,
    required this.crestGlyph,
    required this.cornerCode,
  });
  final Color tone;
  final String crestGlyph;
  final String cornerCode;

  @override
  void paint(Canvas canvas, Size size) {
    // Base — warm off-white paper, tinted very subtly toward tone.
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF5EFD8),
          Color.lerp(const Color(0xFFEFE6C8), tone, 0.04)!,
          const Color(0xFFE7DDBE),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, base);

    // Concentric guilloché rosette — paint behind everything.
    final rosette = Paint()
      ..color = tone.withValues(alpha: 0.08)
      ..strokeWidth = 0.45
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.sqrt(cx * cx + cy * cy);
    for (var r = 18.0; r < maxR; r += 14) {
      final path = Path();
      for (var a = 0.0; a < math.pi * 2; a += 0.02) {
        final wobble = math.sin(a * 9) * 3.2 + math.cos(a * 13) * 2.1;
        final x = cx + (r + wobble) * math.cos(a);
        final y = cy + (r + wobble) * math.sin(a);
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, rosette);
    }

    // Cross-hatch + dot-grid for paper feel.
    final hatch = Paint()
      ..color = tone.withValues(alpha: 0.04)
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;
    for (var x = -size.height; x < size.width + size.height; x += 10) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        hatch,
      );
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        hatch,
      );
    }

    // Watermark crest — large faded glyph centered.
    final crestTp = TextPainter(
      text: TextSpan(
        text: crestGlyph,
        style: TextStyle(
          color: tone.withValues(alpha: 0.10),
          fontSize: size.width * 0.65,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    crestTp.paint(
      canvas,
      Offset(
        (size.width - crestTp.width) / 2,
        (size.height - crestTp.height) / 2,
      ),
    );

    // Microprint borders — visible on close inspection.
    final micro = TextPainter(textDirection: TextDirection.ltr);
    const microText = 'GLOBEID·VISA·AUTHENTIC·SOVEREIGN·SECURE·';
    micro.text = TextSpan(
      text: microText * 6,
      style: TextStyle(
        color: tone.withValues(alpha: 0.18),
        fontSize: 4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
    micro.layout(maxWidth: size.width * 4);
    micro.paint(canvas, const Offset(6, 6));
    micro.paint(canvas, Offset(6, size.height - 10));

    // Corner code — discreet provenance mark, top-right.
    final corner = TextPainter(
      text: TextSpan(
        text: cornerCode,
        style: TextStyle(
          color: tone.withValues(alpha: 0.55),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    corner.paint(canvas, Offset(size.width - corner.width - 12, 10));

    // Edge vignette.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.12)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _VisaPainter old) =>
      old.tone != tone ||
      old.crestGlyph != crestGlyph ||
      old.cornerCode != cornerCode;
}

// ─────────────────────────────────────────────────────────────────────
// BANKNOTE — polymer note with intaglio engraving, optically variable ink
// ─────────────────────────────────────────────────────────────────────

class BanknoteSubstrate extends StatelessWidget {
  const BanknoteSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.serial = 'GBL · 00 · A28 · 411 · 928',
  });
  final Color tone;
  final Widget child;
  final BorderRadius borderRadius;
  final String serial;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _BanknotePainter(tone: tone, serial: serial),
        child: child,
      ),
    );
  }
}

class _BanknotePainter extends CustomPainter {
  _BanknotePainter({required this.tone, required this.serial});
  final Color tone;
  final String serial;

  @override
  void paint(Canvas canvas, Size size) {
    // Polymer base — deep tonal field with subtle vertical gradient.
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(Colors.black, tone, 0.30)!,
          Color.lerp(Colors.black, tone, 0.18)!,
          Color.lerp(Colors.black, tone, 0.10)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Intaglio engraved horizontal lines — fine, dense (15 per inch).
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    for (var y = 0.0; y < size.height; y += 4) {
      final wobble = math.sin(y * 0.12) * 4;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width; x += 6) {
        path.lineTo(x, y + wobble * math.sin(x * 0.02));
      }
      canvas.drawPath(path, lines);
    }

    // Vertical security thread.
    final thread = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.75, 0, 4, size.height));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.75, 0, 4, size.height),
      thread,
    );

    // OVI medallion — top-left, faded.
    final medallion = Paint()
      ..shader = SweepGradient(
        colors: [
          tone.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.18),
          tone.withValues(alpha: 0.30),
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(28, 28), radius: 18));
    canvas.drawCircle(const Offset(28, 28), 18, medallion);

    // Serial number — bottom-left.
    final serialTp = TextPainter(
      text: TextSpan(
        text: serial,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 8,
          letterSpacing: 1.4,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    serialTp.paint(canvas, Offset(10, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _BanknotePainter old) =>
      old.tone != tone || old.serial != serial;
}

// ─────────────────────────────────────────────────────────────────────
// TRANSIT CARD — PETG polymer card with NFC ring
// ─────────────────────────────────────────────────────────────────────

class TransitCardSubstrate extends StatelessWidget {
  const TransitCardSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.network = 'GLOBEID · TRANSIT',
  });
  final Color tone;
  final Widget child;
  final BorderRadius borderRadius;
  final String network;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _TransitCardPainter(tone: tone, network: network),
        child: child,
      ),
    );
  }
}

class _TransitCardPainter extends CustomPainter {
  _TransitCardPainter({required this.tone, required this.network});
  final Color tone;
  final String network;

  @override
  void paint(Canvas canvas, Size size) {
    // PETG polymer base — diagonal gradient.
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.black, tone, 0.42)!,
          Color.lerp(Colors.black, tone, 0.22)!,
          Color.lerp(Colors.black, tone, 0.08)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Curved highlight stripe top-right.
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    final hp = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width * 0.2,
        0,
      )
      ..close();
    canvas.drawPath(hp, highlight);

    // NFC ring — bottom-right corner, the iconic transit-card chip.
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final centre = Offset(size.width - 26, size.height - 26);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: 6.0 + i * 4),
        -math.pi * 0.35,
        math.pi * 0.7,
        false,
        ringPaint,
      );
    }
    canvas.drawCircle(
      centre,
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Network ID — top-right vertical.
    final netTp = TextPainter(
      text: TextSpan(
        text: network,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 8,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    netTp.paint(canvas, Offset(size.width - netTp.width - 14, 10));
  }

  @override
  bool shouldRepaint(covariant _TransitCardPainter old) =>
      old.tone != tone || old.network != network;
}

// ─────────────────────────────────────────────────────────────────────
// DOSSIER — vellum / cream paper dossier for country intelligence
// ─────────────────────────────────────────────────────────────────────

class DossierSubstrate extends StatelessWidget {
  const DossierSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.classification = 'CITIZEN · UNCLASSIFIED',
  });
  final Color tone;
  final Widget child;
  final BorderRadius borderRadius;
  final String classification;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _DossierPainter(tone: tone, classification: classification),
        child: child,
      ),
    );
  }
}

class _DossierPainter extends CustomPainter {
  _DossierPainter({required this.tone, required this.classification});
  final Color tone;
  final String classification;

  @override
  void paint(Canvas canvas, Size size) {
    // Cream vellum base.
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF7F0E0),
          const Color(0xFFEDE3CB),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Grain.
    final rng = math.Random(11);
    final grainPaint = Paint();
    for (var i = 0; i < 1200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      grainPaint.color = Colors.brown.withValues(alpha: rng.nextDouble() * 0.06);
      canvas.drawCircle(Offset(x, y), 0.4 + rng.nextDouble() * 0.5, grainPaint);
    }

    // Top "CLASSIFICATION" strip.
    final stripPaint = Paint()..color = tone.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 18), stripPaint);

    final classTp = TextPainter(
      text: TextSpan(
        text: classification,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    classTp.paint(canvas, Offset(12, 4.5));

    // Diagonal red CLASSIFIED-stamp watermark.
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-math.pi / 8);
    final stampPaint = Paint()
      ..color = tone.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 220, height: 60),
        const Radius.circular(8),
      ),
      stampPaint,
    );
    final stampTp = TextPainter(
      text: TextSpan(
        text: 'DOSSIER',
        style: TextStyle(
          color: tone.withValues(alpha: 0.12),
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 8.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stampTp.paint(canvas, Offset(-stampTp.width / 2, -stampTp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DossierPainter old) =>
      old.tone != tone || old.classification != classification;
}

// ─────────────────────────────────────────────────────────────────────
// NAV STRIP — turn-by-turn navigation ribbon (turn glyph + distance)
// ─────────────────────────────────────────────────────────────────────

class NavStripSubstrate extends StatelessWidget {
  const NavStripSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
  final Color tone;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _NavStripPainter(tone: tone),
        child: child,
      ),
    );
  }
}

class _NavStripPainter extends CustomPainter {
  _NavStripPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.black, tone, 0.55)!,
          Color.lerp(Colors.black, tone, 0.30)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Lane marking — dashed center line.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 3;
    for (var x = 14.0; x < size.width - 12; x += 22) {
      canvas.drawLine(
        Offset(x, size.height * 0.78),
        Offset(x + 12, size.height * 0.78),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NavStripPainter old) => old.tone != tone;
}

// ─────────────────────────────────────────────────────────────────────
// LOUNGE — luxury embossed card substrate (cognac leather feel)
// ─────────────────────────────────────────────────────────────────────

class LoungeCardSubstrate extends StatelessWidget {
  const LoungeCardSubstrate({
    super.key,
    required this.tone,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
  final Color tone;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _LoungeCardPainter(tone: tone),
        child: child,
      ),
    );
  }
}

class _LoungeCardPainter extends CustomPainter {
  _LoungeCardPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A0E08),
          Color.lerp(const Color(0xFF1A0E08), tone, 0.35)!,
          const Color(0xFF120906),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Leather grain — sparse dots.
    final rng = math.Random(91);
    final grain = Paint();
    for (var i = 0; i < 600; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      grain.color = Colors.black.withValues(alpha: rng.nextDouble() * 0.18);
      canvas.drawCircle(Offset(x, y), 0.7 + rng.nextDouble() * 0.7, grain);
    }

    // Embossed border.
    final emboss = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
        const Radius.circular(12),
      ),
      emboss,
    );
  }

  @override
  bool shouldRepaint(covariant _LoungeCardPainter old) => old.tone != tone;
}
