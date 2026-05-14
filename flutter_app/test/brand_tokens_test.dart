import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/brand_tokens.dart';

void main() {
  group('BrandTokens', () {
    test('total count matches the published catalog (51 tokens)', () {
      // 22 colors + 11 spacing + 6 radius + 12 typography +
      //  10 motion duration + 6 motion curve = 67 tokens.
      expect(BrandTokens.totalCount, 67);
    });

    test('color tokens enumerate every brand foil + substrate band', () {
      final colors = BrandTokens.colorTokens();
      expect(colors.keys, containsAll(<String>[
        'color.foil.base',
        'color.foil.light',
        'color.foil.deep',
        'color.foil.champagne',
        'color.substrate.canvas',
        'color.substrate.floor1',
        'color.ink.bright',
        'color.hairline.standard',
        'color.world.identity',
      ]));
    });

    test('motion duration tokens are all positive ints in ms', () {
      final durations = BrandTokens.motionDurationTokens();
      expect(durations.length, 10);
      for (final entry in durations.entries) {
        expect(entry.value, greaterThan(0),
            reason: '${entry.key} should be > 0 ms');
      }
    });

    test('motion curve tokens are cubic-bezier formula strings', () {
      final curves = BrandTokens.motionCurveTokens();
      for (final entry in curves.entries) {
        final isLinear = entry.value == 'linear';
        final isCubic = entry.value.startsWith('cubic-bezier(');
        expect(
          isLinear || isCubic,
          isTrue,
          reason: '${entry.key} = "${entry.value}" must be either '
              '"linear" or a cubic-bezier formula',
        );
      }
    });

    test('toJson() round-trips through pretty-print', () {
      final json1 = BrandTokens.toPrettyJson();
      expect(json1, contains(r'"$schema": "globeid.tokens.v1"'));
      expect(json1, contains('"brand": "GlobeID"'));
      expect(json1, contains('"schemaVersion": "1.0.0"'));
    });

    test(
      'assets/atelier/tokens.json is byte-identical to the live exporter',
      () {
        // Walk up from the test file location to find the repo root.
        final cwd = Directory.current.path;
        File assetFile = File('$cwd/assets/atelier/tokens.json');
        if (!assetFile.existsSync()) {
          // When the test runner CWD is flutter_app/.
          assetFile = File('$cwd/../assets/atelier/tokens.json');
        }
        expect(
          assetFile.existsSync(),
          isTrue,
          reason: 'assets/atelier/tokens.json must be checked into the '
              'repo so downstream surfaces (web / marketing / watch '
              'face) can read it without running the Flutter app.',
        );
        final onDisk = assetFile.readAsStringSync();
        final live = BrandTokens.toPrettyJson();
        expect(
          onDisk.trim(),
          live.trim(),
          reason: 'assets/atelier/tokens.json is out of sync with '
              'BrandTokens.toPrettyJson(). Re-generate the asset:\n'
              '  flutter test test/brand_tokens_test.dart '
              '--update-goldens\n'
              'or copy the value of `live` above into the asset.',
        );
      },
    );
  });
}
