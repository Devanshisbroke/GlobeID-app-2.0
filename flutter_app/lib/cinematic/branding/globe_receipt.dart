import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Five canonical receipt kinds. Each keys eyebrow, accent tone,
/// and footer copy — body rows are passed in by the caller.
enum ReceiptKind {
  payment,
  trip,
  credential,
  immigration,
  visa,
}

/// Per-kind manifest — eyebrow, footer copy, accent tone.
class ReceiptSpec {
  const ReceiptSpec({
    required this.eyebrow,
    required this.footer,
    required this.tone,
  });

  /// Mono-cap eyebrow that sits above the receipt title (e.g.
  /// `WALLET · PAYMENT`).
  final String eyebrow;

  /// Mono-cap footer chip below the totals (e.g.
  /// `THANK · YOU · FOR · USING · GLOBE · ID`).
  final String footer;

  /// Foil-tone accent — colours the hairline frame, eyebrow,
  /// totals, footer chip and watermark.
  final Color tone;

  static const payment = ReceiptSpec(
    eyebrow: 'WALLET · PAYMENT',
    footer: 'THANK · YOU · FOR · USING · GLOBE · ID',
    tone: Color(0xFFD4AF37),
  );

  static const trip = ReceiptSpec(
    eyebrow: 'TRIP · SETTLEMENT',
    footer: 'TRIP · ARCHIVED · GLOBE · ID',
    tone: Color(0xFFE9C75D),
  );

  static const credential = ReceiptSpec(
    eyebrow: 'CREDENTIAL · ISSUED',
    footer: 'VAULTED · GLOBE · ID',
    tone: Color(0xFFC9A961),
  );

  static const immigration = ReceiptSpec(
    eyebrow: 'IMMIGRATION · CLEARED',
    footer: 'BORDER · CLEARED · GLOBE · ID',
    tone: Color(0xFF6B8FB8),
  );

  static const visa = ReceiptSpec(
    eyebrow: 'VISA · GRANTED',
    footer: 'CHRONICLED · GLOBE · ID',
    tone: Color(0xFF3FB68B),
  );

  static ReceiptSpec of(ReceiptKind kind) {
    switch (kind) {
      case ReceiptKind.payment:
        return payment;
      case ReceiptKind.trip:
        return trip;
      case ReceiptKind.credential:
        return credential;
      case ReceiptKind.immigration:
        return immigration;
      case ReceiptKind.visa:
        return visa;
    }
  }
}

/// A single row on a [GlobeReceipt] — label + value with an
/// optional accent tone override (e.g. green totals on a refund row).
class ReceiptRow {
  const ReceiptRow({
    required this.label,
    required this.value,
    this.toneOverride,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? toneOverride;
  final bool bold;
}

/// GlobeID receipt — OLED-black card with gold hairline frame,
/// mono-cap eyebrow, display title, body rows, foil-gold total,
/// dash-cut perforation, mono-cap footer chip, and bottom-right
/// GLOBE · ID watermark.
///
/// Renders at a fixed 360 × intrinsic-height layout so it screenshots
/// cleanly into share sheets and social posts — every shared receipt
/// then *advertises* the brand.
class GlobeReceipt extends StatelessWidget {
  const GlobeReceipt({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountSub,
    required this.rows,
    required this.caseNumber,
    this.timestamp,
    this.signatureLabel = 'SIGNED · GLOBE · ID',
  });

  /// Receipt kind — drives eyebrow / footer / tone.
  final ReceiptKind kind;

  /// Display title (e.g. `Confirmed`, `Issued`, `Cleared`).
  final String title;

  /// Body subtitle under the title (e.g. recipient name, country).
  final String subtitle;

  /// Hero amount (e.g. `€42.18`, `Schengen · 90 d`).
  final String amount;

  /// Sub-label under the amount (e.g. `USD · LIVE · RATE`).
  final String amountSub;

  /// Body rows printed between the amount block and the totals line.
  final List<ReceiptRow> rows;

  /// Mono-cap case number printed bottom-right (e.g. `N° A8C-2024`).
  final String caseNumber;

  /// Optional timestamp (e.g. `2024 · 09 · 14 · 17:42 · UTC`). If
  /// null, the receipt prints `LIVE · MOMENT` as the timestamp.
  final String? timestamp;

  /// Mono-cap signature label printed under the perforation line.
  final String signatureLabel;

  @override
  Widget build(BuildContext context) {
    final spec = ReceiptSpec.of(kind);
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: spec.tone.withValues(alpha: 0.46),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: spec.tone.withValues(alpha: 0.14),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(spec: spec, title: title, subtitle: subtitle),
          _Amount(spec: spec, amount: amount, sub: amountSub),
          if (rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final row in rows) ...[
                    _Row(row: row, fallbackTone: spec.tone),
                    if (row != rows.last)
                      _Hairline(tone: spec.tone, alpha: 0.10),
                  ],
                ],
              ),
            ),
          _Perforation(tone: spec.tone),
          _Footer(
            spec: spec,
            caseNumber: caseNumber,
            timestamp: timestamp ?? 'LIVE · MOMENT',
            signatureLabel: signatureLabel,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.spec,
    required this.title,
    required this.subtitle,
  });
  final ReceiptSpec spec;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      spec.tone.withValues(alpha: 0.95),
                      HSLColor.fromColor(spec.tone)
                          .withLightness(0.20)
                          .toColor()
                          .withValues(alpha: 0.96),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: HSLColor.fromColor(spec.tone)
                          .withLightness(0.10)
                          .toColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  spec.eyebrow,
                  style: TextStyle(
                    color: spec.tone,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.spec,
    required this.amount,
    required this.sub,
  });
  final ReceiptSpec spec;
  final String amount;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              colors: [
                spec.tone,
                HSLColor.fromColor(spec.tone)
                    .withLightness(0.62)
                    .toColor(),
              ],
            ).createShader(rect),
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.46),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.fallbackTone});
  final ReceiptRow row;
  final Color fallbackTone;

  @override
  Widget build(BuildContext context) {
    final tone = row.toneOverride ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            row.value,
            style: TextStyle(
              color: row.toneOverride ?? tone,
              fontSize: row.bold ? 16 : 13,
              fontWeight: row.bold ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.tone, this.alpha = 0.12});
  final Color tone;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.6,
      color: tone.withValues(alpha: alpha),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation({required this.tone});
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
      child: CustomPaint(
        size: const Size.fromHeight(1.6),
        painter: _PerfPainter(tone: tone),
      ),
    );
  }
}

class _PerfPainter extends CustomPainter {
  _PerfPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tone.withValues(alpha: 0.44)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    const dashLen = 6.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dashLen, size.width), 0),
        paint,
      );
      x += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(_PerfPainter old) => old.tone != tone;
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.spec,
    required this.caseNumber,
    required this.timestamp,
    required this.signatureLabel,
  });
  final ReceiptSpec spec;
  final String caseNumber;
  final String timestamp;
  final String signatureLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signatureLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timestamp,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: spec.tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: spec.tone.withValues(alpha: 0.36),
                width: 0.6,
              ),
            ),
            child: Text(
              spec.footer,
              style: TextStyle(
                color: spec.tone,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GLOBE · ID',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.36),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MANUFACTURED · CREDENTIAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.20),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            spec.tone.withValues(alpha: 0.46),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caseNumber,
                      style: TextStyle(
                        color: spec.tone.withValues(alpha: 0.78),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
