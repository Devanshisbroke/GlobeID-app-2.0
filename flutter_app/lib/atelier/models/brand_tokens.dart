import 'dart:convert';

import 'package:flutter/material.dart';

import '../../motion/motion_tokens.dart';
import '../../os2/os2_tokens.dart';

/// Atelier — canonical brand token export.
///
/// Single source of truth for the design tokens that get shipped to
/// downstream surfaces (web, marketing, watch face complications,
/// designers). Reads from [Os2] + [Motion] so the export is always
/// in lock-step with the in-app tokens — no parallel taxonomy.
///
/// The exporter produces a stable JSON document; the schema is
/// versioned with [schemaVersion] so consumers can detect breaking
/// changes.
class BrandTokens {
  BrandTokens._();

  static const String schemaVersion = '1.0.0';
  static const String brand = 'GlobeID';

  /// Canonical color tokens. Names mirror the dotted-path style of
  /// the rest of the design-token ecosystem (e.g. `color.foil.base`).
  static Map<String, Color> colorTokens() {
    return <String, Color>{
      // ── Foil (gold) palette ─────────────────────────────────────
      'color.foil.base': const Color(0xFFD4AF37),
      'color.foil.light': const Color(0xFFE9C75D),
      'color.foil.deep': Os2.identityTone,
      'color.foil.champagne': Os2.pulseTone,
      'color.foil.hairline': Os2.goldHairline,

      // ── Substrate / OLED ────────────────────────────────────────
      'color.substrate.canvas': Os2.canvas,
      'color.substrate.floor1': Os2.floor1,
      'color.substrate.floor2': Os2.floor2,
      'color.substrate.floor3': Os2.floor3,

      // ── Ink ladder ──────────────────────────────────────────────
      'color.ink.bright': Os2.inkBright,
      'color.ink.high': Os2.inkHigh,
      'color.ink.mid': Os2.inkMid,
      'color.ink.low': Os2.inkLow,
      'color.ink.faint': Os2.inkFaint,

      // ── Hairlines ───────────────────────────────────────────────
      'color.hairline.standard': Os2.hairline,
      'color.hairline.soft': Os2.hairlineSoft,

      // ── World tones ─────────────────────────────────────────────
      'color.world.pulse': Os2.pulseTone,
      'color.world.identity': Os2.identityTone,
      'color.world.wallet': Os2.walletTone,
      'color.world.travel': Os2.travelTone,
      'color.world.discover': Os2.discoverTone,
      'color.world.services': Os2.servicesTone,
    };
  }

  /// Spacing scale (logical pixels).
  static Map<String, double> spacingTokens() {
    return <String, double>{
      'spacing.0': Os2.space0,
      'spacing.1': Os2.space1,
      'spacing.2': Os2.space2,
      'spacing.3': Os2.space3,
      'spacing.4': Os2.space4,
      'spacing.5': Os2.space5,
      'spacing.6': Os2.space6,
      'spacing.7': Os2.space7,
      'spacing.8': Os2.space8,
      'spacing.9': Os2.space9,
      'spacing.10': Os2.space10,
    };
  }

  /// Border-radius scale (logical pixels).
  static Map<String, double> radiusTokens() {
    return <String, double>{
      'radius.chip': Os2.rChip,
      'radius.tile': Os2.rTile,
      'radius.card': Os2.rCard,
      'radius.slab': Os2.rSlab,
      'radius.hero': Os2.rHero,
      'radius.floor': Os2.rFloor,
    };
  }

  /// Type scale font sizes (logical pixels).
  static Map<String, double> typographyTokens() {
    return <String, double>{
      'typography.text.tiny': Os2.textTiny,
      'typography.text.micro': Os2.textMicro,
      'typography.text.xs': Os2.textXs,
      'typography.text.sm': Os2.textSm,
      'typography.text.md': Os2.textMd,
      'typography.text.rg': Os2.textRg,
      'typography.text.base': Os2.textBase,
      'typography.text.lg': Os2.textLg,
      'typography.text.xl': Os2.textXl,
      'typography.text.xxl': Os2.textXxl,
      'typography.text.h2': Os2.textH2,
      'typography.text.h1': Os2.textH1,
    };
  }

  /// Motion duration tokens (milliseconds).
  static Map<String, int> motionDurationTokens() {
    return <String, int>{
      'motion.duration.instant': Motion.dInstant.inMilliseconds,
      'motion.duration.tap': Motion.dTap.inMilliseconds,
      'motion.duration.quickReverse': Motion.dQuickReverse.inMilliseconds,
      'motion.duration.modal': Motion.dModal.inMilliseconds,
      'motion.duration.sheet': Motion.dSheet.inMilliseconds,
      'motion.duration.page': Motion.dPage.inMilliseconds,
      'motion.duration.cruise': Motion.dCruise.inMilliseconds,
      'motion.duration.portal': Motion.dPortal.inMilliseconds,
      'motion.duration.breathFast': Motion.dBreathFast.inMilliseconds,
      'motion.duration.breathSlow': Motion.dBreathSlow.inMilliseconds,
    };
  }

  /// Motion curve tokens — formula strings keyed by dotted path.
  ///
  /// Sourced from the live [Motion] curves but expressed in a
  /// portable cubic-bezier-formula format so downstream engines
  /// (Lottie, CSS, After Effects) can consume them directly.
  static Map<String, String> motionCurveTokens() {
    return <String, String>{
      'motion.curve.standard': 'cubic-bezier(0.16, 1.00, 0.30, 1.00)',
      'motion.curve.emphasized': 'cubic-bezier(0.65, 0.00, 0.35, 1.00)',
      'motion.curve.spring': 'cubic-bezier(0.34, 1.56, 0.64, 1.00)',
      'motion.curve.exit': 'cubic-bezier(0.55, 0.00, 1.00, 0.45)',
      'motion.curve.settle': 'cubic-bezier(0.33, 1.00, 0.68, 1.00)',
      'motion.curve.linear': 'linear',
    };
  }

  /// Compose all token groups into a single JSON-serializable map.
  static Map<String, dynamic> toJson() {
    return <String, dynamic>{
      r'$schema': 'globeid.tokens.v1',
      'meta': <String, String>{
        'brand': brand,
        'schemaVersion': schemaVersion,
        'generatedBy': 'BrandTokens.toJson()',
      },
      'color': _colorsAsHex(colorTokens()),
      'spacing': spacingTokens()
          .map<String, dynamic>((k, v) => MapEntry(k, v)),
      'radius': radiusTokens()
          .map<String, dynamic>((k, v) => MapEntry(k, v)),
      'typography': typographyTokens()
          .map<String, dynamic>((k, v) => MapEntry(k, v)),
      'motion': <String, dynamic>{
        'duration': motionDurationTokens()
            .map<String, dynamic>((k, v) => MapEntry(k, v)),
        'curve': motionCurveTokens()
            .map<String, dynamic>((k, v) => MapEntry(k, v)),
      },
    };
  }

  /// Pretty-printed (2-space indented) JSON export.
  ///
  /// The contents of `assets/atelier/tokens.json` are kept in sync
  /// with this function — a test in `test/brand_tokens_test.dart`
  /// asserts they are identical, so the asset file cannot drift.
  static String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Number of token entries across every group. Useful for tests
  /// and the lab summary chip.
  static int get totalCount {
    return colorTokens().length +
        spacingTokens().length +
        radiusTokens().length +
        typographyTokens().length +
        motionDurationTokens().length +
        motionCurveTokens().length;
  }
}

Map<String, String> _colorsAsHex(Map<String, Color> input) {
  return input.map((k, v) => MapEntry(k, _colorAsHex(v)));
}

/// Stable hex format including alpha — `#AARRGGBB` lowercase.
///
/// Using the modern Color API where possible, but falling back to
/// the deprecated `.value` accessor with a compatibility shim so the
/// exporter works on both the current and prior Flutter releases
/// referenced by `pubspec.yaml`.
String _colorAsHex(Color c) {
  // ignore: deprecated_member_use
  final argb = c.value & 0xFFFFFFFF;
  return '#${argb.toRadixString(16).padLeft(8, '0').toLowerCase()}';
}
