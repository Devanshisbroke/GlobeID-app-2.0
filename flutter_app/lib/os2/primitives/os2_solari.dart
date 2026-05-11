import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Solari.
///
/// Tabular departure-board numerals. Each glyph lives in a fixed-width
/// floor1 cell with a 0.6px tone-tinted hairline, mimicking the flap
/// chambers of a Solari split-flap display. The whole row is wrapped
/// in `FittedBox(BoxFit.scaleDown)` so it never overflows narrow
/// viewports — a regression we hit repeatedly on Pixel 4a (360 dp).
class Os2Solari extends StatelessWidget {
  const Os2Solari({
    super.key,
    required this.text,
    this.tone = Os2.pulseTone,
    this.cellWidth = 22,
    this.cellHeight = 32,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w800,
    this.gap = 3,
    this.cellColor,
  });

  final String text;
  final Color tone;
  final double cellWidth;
  final double cellHeight;
  final double fontSize;
  final FontWeight fontWeight;
  final double gap;
  final Color? cellColor;

  @override
  Widget build(BuildContext context) {
    final cellFill = cellColor ?? Os2.floor1;
    final chars = text.split('');
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < chars.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _Cell(
              char: chars[i],
              tone: tone,
              width: cellWidth,
              height: cellHeight,
              fontSize: fontSize,
              fontWeight: fontWeight,
              cellColor: cellFill,
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.char,
    required this.tone,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.fontWeight,
    required this.cellColor,
  });

  final String char;
  final Color tone;
  final double width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final Color cellColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: tone.withValues(alpha: 0.20),
          width: Os2.strokeFine,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: height / 2 - 0.5,
            left: 2,
            right: 2,
            child: Container(
              height: 0.6,
              color: Os2.hairline,
            ),
          ),
          Text(
            char,
            style: TextStyle(
              fontFamily: 'Departure Mono',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: tone,
              letterSpacing: 0,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
