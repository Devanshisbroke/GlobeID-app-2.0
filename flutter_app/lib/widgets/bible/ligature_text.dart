// Travel ligature text widget.
//
// The bible (§4.2): "When the app recognises a known travel string
// (LHR-JFK, EUR/USD, UTC+9), it auto-promotes it to a ligature with
// a custom kerning + tone-tinted underline. This makes raw data feel
// typographically curated."
//
// LigatureText takes plain text, scans for IATA pair / FX pair /
// timezone offset patterns and renders matched substrings with a
// subtle tone-tinted underline + tightened kerning.

import 'package:flutter/material.dart';

import '../../app/theme/ux_bible.dart';

class LigatureText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? underlineColor;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const LigatureText(
    this.text, {
    super.key,
    this.style,
    this.underlineColor,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  // IATA pair: 3-letter airport → 3-letter airport.
  static final _iataPair =
      RegExp(r'\b([A-Z]{3})\s*[-–→]\s*([A-Z]{3})\b');
  // Currency pair: 3-letter ISO code over a slash.
  static final _fxPair = RegExp(r'\b([A-Z]{3})/([A-Z]{3})\b');
  // Timezone offset: UTC+09 / GMT-3 / UTC+9:30.
  static final _tz = RegExp(r'\b(UTC|GMT)\s*([+-])\s*(\d{1,2}(?::\d{2})?)\b');
  // Flight number: 2 letters + 2-4 digits.
  static final _flight = RegExp(r'\b([A-Z]{2}\d{2,4})\b');

  static final _patterns = [_iataPair, _fxPair, _tz, _flight];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final tint = underlineColor ?? BibleTone.runwayAmber;

    final spans = <TextSpan>[];
    var cursor = 0;
    while (cursor < text.length) {
      _Match? earliest;
      for (final p in _patterns) {
        final m = p.firstMatch(text.substring(cursor));
        if (m != null) {
          final candidate = _Match(p, m, cursor + m.start, cursor + m.end);
          if (earliest == null || candidate.start < earliest.start) {
            earliest = candidate;
          }
        }
      }
      if (earliest == null) {
        spans.add(TextSpan(text: text.substring(cursor), style: base));
        break;
      }
      if (earliest.start > cursor) {
        spans.add(TextSpan(
            text: text.substring(cursor, earliest.start), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(earliest.start, earliest.end),
        style: base.copyWith(
          letterSpacing: 0.4,
          fontFeatures: const [FontFeature.enable('liga')],
          decoration: TextDecoration.underline,
          decorationColor: tint.withValues(alpha: 0.70),
          decorationThickness: 1.6,
          decorationStyle: TextDecorationStyle.solid,
        ),
      ));
      cursor = earliest.end;
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _Match {
  final RegExp pattern;
  final Match match;
  final int start;
  final int end;
  _Match(this.pattern, this.match, this.start, this.end);
}
