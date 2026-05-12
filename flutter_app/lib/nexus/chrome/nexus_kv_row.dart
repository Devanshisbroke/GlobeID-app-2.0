import 'package:flutter/material.dart';

import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Eyebrow-over-value row — the canonical data row used on the boarding
/// pass card and elsewhere ("Passenger / ALEXANDER V. GRAFF").
class NKv extends StatelessWidget {
  const NKv({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.color = N.ink,
    this.spread = false,
  });

  final String label;
  final String value;
  final bool mono;
  final Color color;
  final bool spread;

  @override
  Widget build(BuildContext context) {
    final valueWidget = mono
        ? NText.mono14(value, color: color)
        : Text(
            value,
            style: NType.title16(color: color),
          );
    return Column(
      crossAxisAlignment: spread
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        NText.eyebrow10(label, color: N.inkLow),
        const SizedBox(height: N.s1),
        valueWidget,
      ],
    );
  }
}

/// Inline mini KV — eyebrow + tiny mono value in a single row.
class NKvInline extends StatelessWidget {
  const NKvInline({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NText.eyebrow10(label, color: N.inkLow),
        const SizedBox(width: N.s2),
        mono
            ? NText.mono12(value, color: N.ink)
            : Text(value, style: NType.body13(color: N.ink)),
      ],
    );
  }
}
