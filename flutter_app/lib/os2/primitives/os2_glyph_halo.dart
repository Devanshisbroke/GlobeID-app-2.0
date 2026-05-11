import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Glyph halo.
///
/// A circular icon container with a radial tone halo and a hairline rim.
/// Used inside info chips, timeline rows, and action cards. Three sizes:
/// 26 (micro, inside chips), 36 (default), 48 (hero).
class Os2GlyphHalo extends StatelessWidget {
  const Os2GlyphHalo({
    super.key,
    required this.icon,
    this.tone = Os2.pulseTone,
    this.size = 36,
    this.iconSize,
  });

  final IconData icon;
  final Color tone;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final ico = iconSize ?? size * 0.46;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            tone.withValues(alpha: 0.35),
            tone.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.40),
          width: Os2.strokeFine,
        ),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(icon, size: ico, color: Os2.inkBright),
    );
  }
}
