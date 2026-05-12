import 'package:flutter/material.dart';

import 'nexus_tokens.dart';

/// Nexus typography — three deliberate tracks:
///   1. Display readouts (huge tabular numerals)
///   2. Title / body sans (restrained)
///   3. Eyebrow caps + mono codes (aviation HUD vocabulary)
///
/// All fonts inherit `letterSpacing` and `fontFeatures` to feel like
/// a cockpit instrument panel rather than a marketing site.
class NType {
  NType._();

  // ─────────────────────────────────────────────── display readout
  /// 56 px display — used for the giant balance readout
  /// ("$237,031", "02:14:45").
  static TextStyle display56({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 56,
        height: 1.0,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle display40({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 40,
        height: 1.0,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle display28({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 28,
        height: 1.05,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─────────────────────────────────────────────── title
  static TextStyle title22({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      );

  static TextStyle title18({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      );

  static TextStyle title16({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w500,
      );

  // ─────────────────────────────────────────────── body
  static TextStyle body14({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  static TextStyle body13({Color color = N.inkMid}) => TextStyle(
        color: color,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  static TextStyle body12({Color color = N.inkLow}) => TextStyle(
        color: color,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  // ─────────────────────────────────────────────── eyebrow (caps)
  static TextStyle eyebrow10({Color color = N.inkLow}) => TextStyle(
        color: color,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
      );

  static TextStyle eyebrow11({Color color = N.inkMid}) => TextStyle(
        color: color,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      );

  static TextStyle eyebrow12({Color color = N.inkMid}) => TextStyle(
        color: color,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      );

  // ─────────────────────────────────────────────── mono
  static TextStyle mono14({Color color = N.ink}) => TextStyle(
        color: color,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        fontFamily: 'monospace',
        fontFamilyFallback: const [
          'JetBrains Mono',
          'SF Mono',
          'Menlo',
          'Roboto Mono',
        ],
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle mono12({Color color = N.inkMid}) => TextStyle(
        color: color,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        fontFamily: 'monospace',
        fontFamilyFallback: const [
          'JetBrains Mono',
          'SF Mono',
          'Menlo',
          'Roboto Mono',
        ],
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle monoCap10({Color color = N.inkLow}) => TextStyle(
        color: color,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
        fontFamilyFallback: const [
          'JetBrains Mono',
          'SF Mono',
          'Menlo',
          'Roboto Mono',
        ],
      );
}

/// Widget-level shortcuts. Use these in screen code instead of bare
/// `Text(..., style: NType.xxx())` calls.
class NText {
  NText._();

  static Widget display56(String s, {Color color = N.ink}) =>
      Text(s, style: NType.display56(color: color));

  static Widget display40(String s, {Color color = N.ink}) =>
      Text(s, style: NType.display40(color: color));

  static Widget display28(String s, {Color color = N.ink}) =>
      Text(s, style: NType.display28(color: color));

  static Widget title22(String s, {Color color = N.ink}) =>
      Text(s, style: NType.title22(color: color));

  static Widget title18(String s, {Color color = N.ink}) =>
      Text(s, style: NType.title18(color: color));

  static Widget title16(String s, {Color color = N.ink}) =>
      Text(s, style: NType.title16(color: color));

  static Widget body14(String s, {Color color = N.ink}) =>
      Text(s, style: NType.body14(color: color));

  static Widget body13(String s, {Color color = N.inkMid}) =>
      Text(s, style: NType.body13(color: color));

  static Widget body12(String s, {Color color = N.inkLow}) =>
      Text(s, style: NType.body12(color: color));

  static Widget eyebrow10(String s, {Color color = N.inkLow}) =>
      Text(s.toUpperCase(), style: NType.eyebrow10(color: color));

  static Widget eyebrow11(String s, {Color color = N.inkMid}) =>
      Text(s.toUpperCase(), style: NType.eyebrow11(color: color));

  static Widget eyebrow12(String s, {Color color = N.inkMid}) =>
      Text(s.toUpperCase(), style: NType.eyebrow12(color: color));

  static Widget mono14(String s, {Color color = N.ink}) =>
      Text(s, style: NType.mono14(color: color));

  static Widget mono12(String s, {Color color = N.inkMid}) =>
      Text(s, style: NType.mono12(color: color));

  static Widget monoCap10(String s, {Color color = N.inkLow}) =>
      Text(s.toUpperCase(), style: NType.monoCap10(color: color));
}
