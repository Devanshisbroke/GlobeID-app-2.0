import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/os2/os2_tokens.dart';
import 'package:globeid/os2/primitives/os2_text.dart';

/// Phase 6a — canonical typography contract.
///
/// These tests pin the GlobeID type-scale invariants so a future
/// refactor can't accidentally drop a token, invert the scale, or
/// regress the auto-relaxing tracking curve that gives the worlds
/// their uniform typographic identity.
void main() {
  group('Os2 type scale', () {
    test('ladder is strictly monotonically increasing', () {
      final ladder = <double>[
        Os2.textTiny,
        Os2.textMicro,
        Os2.textXs,
        Os2.textSm,
        Os2.textMd,
        Os2.textRg,
        Os2.textBase,
        Os2.textLg,
        Os2.textXl,
        Os2.textXxl,
        Os2.textH2,
        Os2.textH1,
      ];
      for (var i = 1; i < ladder.length; i++) {
        expect(
          ladder[i] > ladder[i - 1],
          isTrue,
          reason: 'expected ${ladder[i]} > ${ladder[i - 1]} at index $i',
        );
      }
    });

    test('canonical sizes anchor inside the scale', () {
      expect(Os2.canonDisplay, Os2.textH1);
      expect(Os2.canonHeadline, Os2.textH2);
      expect(Os2.canonBody, Os2.textBase);
      expect(Os2.canonCaption, Os2.textXs);
      expect(Os2.canonMonoCap, Os2.textSm);
    });
  });

  group('Os2.trackingFor — auto-relaxing tracking curve', () {
    test('at canonical size, tracking is the canonical value', () {
      expect(
        Os2.trackingFor(Os2.trackTitle, Os2.canonTitle, Os2.canonTitle),
        Os2.trackTitle,
      );
    });

    test('above canonical size, tracking is unchanged', () {
      expect(
        Os2.trackingFor(Os2.trackDisplay, 64, Os2.canonDisplay),
        Os2.trackDisplay,
      );
    });

    test('below canonical size, tracking relaxes proportionally', () {
      final relaxed = Os2.trackingFor(Os2.trackTitle, 14, Os2.canonTitle);
      expect(relaxed.abs() < Os2.trackTitle.abs(), isTrue);
      // Linear ratio: -0.4 * (14 / 20) = -0.28.
      expect(relaxed, closeTo(-0.28, 0.001));
    });

    test('positive tracking relaxes toward zero below canonical', () {
      final relaxed = Os2.trackingFor(Os2.trackMonoCap, 9, Os2.canonMonoCap);
      expect(relaxed < Os2.trackMonoCap, isTrue);
      expect(relaxed > 0, isTrue);
    });
  });

  group('Os2Text — constructable variants', () {
    testWidgets('every variant is constructable as a const widget',
        (tester) async {
      const widgets = <Widget>[
        Os2Text.display('Display'),
        Os2Text.headline('Headline'),
        Os2Text.title('Title'),
        Os2Text.body('Body'),
        Os2Text.caption('Caption'),
        Os2Text.monoCap('mono'),
        Os2Text.credential('92'),
        Os2Text.watermark('GLOBE·ID'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(children: widgets),
          ),
        ),
      );
      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Headline'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('CAPTION'), findsOneWidget);
      expect(find.text('MONO'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('GLOBE·ID'), findsOneWidget);
    });

    testWidgets('credential carries tabular figures + tight tracking',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Os2Text.credential('1234')),
        ),
      );
      final text = tester.widget<Text>(find.text('1234'));
      expect(text.style?.fontWeight, FontWeight.w900);
      expect(text.style?.fontSize, 36);
      expect(text.style?.letterSpacing, -1.0);
      expect(text.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('watermark uppercases + uses brand chrome defaults',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Os2Text.watermark('globe·id')),
        ),
      );
      // Watermark is uppercased by default.
      expect(find.text('GLOBE·ID'), findsOneWidget);
      final text = tester.widget<Text>(find.text('GLOBE·ID'));
      expect(text.style?.fontSize, Os2.textTiny);
      expect(text.style?.letterSpacing, 2.4);
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('display gradient renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Os2Text.display(
              'GlobeID',
              gradient: Os2.foilGoldHero,
            ),
          ),
        ),
      );
      expect(find.text('GlobeID'), findsOneWidget);
    });
  });

  group('Os2 brand DNA palette', () {
    test('gold stops are the canonical champagne ramp', () {
      expect(Os2.goldDeep, const Color(0xFFD4AF37));
      expect(Os2.goldLight, const Color(0xFFE9C75D));
    });

    test('foilGoldHero gradient ramps through both gold stops', () {
      expect(Os2.foilGoldHero.colors, contains(Os2.goldDeep));
      expect(Os2.foilGoldHero.colors, contains(Os2.goldLight));
    });
  });
}
