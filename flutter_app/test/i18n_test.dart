import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/i18n/globe_id_locale.dart';

void main() {
  group('GlobeIdLocale', () {
    test('covers en / ar / zh / es / ja', () {
      final tags = GlobeIdLocale.values.map((l) => l.tag).toSet();
      expect(tags, {'en-US', 'ar-SA', 'zh-CN', 'es-ES', 'ja-JP'});
    });

    test('Arabic is the only RTL locale', () {
      final rtl = GlobeIdLocale.values
          .where((l) => l.textDirection == TextDirection.rtl)
          .toList();
      expect(rtl.length, 1);
      expect(rtl.single, GlobeIdLocale.arSA);
    });

    test('fromTag round-trips every locale', () {
      for (final l in GlobeIdLocale.values) {
        expect(GlobeIdLocale.fromTag(l.tag), l);
      }
    });

    test('fromTag falls back to en-US for unknown tags', () {
      expect(GlobeIdLocale.fromTag('xx-XX'), GlobeIdLocale.enUS);
    });

    test('toMaterialLocale carries language + country', () {
      expect(
        GlobeIdLocale.arSA.toMaterialLocale(),
        const Locale('ar', 'SA'),
      );
    });
  });

  group('GlobeIdStrings', () {
    test('every locale resolves to a non-empty bundle', () {
      for (final l in GlobeIdLocale.values) {
        final s = GlobeIdStrings.of(l);
        expect(s.appName, 'GlobeID');
        expect(s.brandTagline.isNotEmpty, isTrue);
        expect(s.continueAction.isNotEmpty, isTrue);
        expect(s.signedByGlobeId.contains('GlobeID'), isTrue);
      }
    });

    test('Arabic + Chinese + Japanese bundles use native scripts', () {
      expect(GlobeIdStrings.of(GlobeIdLocale.arSA).continueAction, 'متابعة');
      expect(GlobeIdStrings.of(GlobeIdLocale.zhCN).continueAction, '继续');
      expect(GlobeIdStrings.of(GlobeIdLocale.jaJP).continueAction, '続ける');
    });

    test('app name (GlobeID) is the constant across every locale', () {
      final names = GlobeIdLocale.values.map((l) => GlobeIdStrings.of(l).appName).toSet();
      expect(names, {'GlobeID'});
    });
  });

  group('GlobeIdLocaleScope', () {
    testWidgets('flips Directionality for RTL locales', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        GlobeIdLocaleScope(
          initial: GlobeIdLocale.arSA,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(Directionality.of(captured), TextDirection.rtl);
      expect(GlobeIdLocaleScope.localeOf(captured), GlobeIdLocale.arSA);
    });

    testWidgets('setLocale switches the live bundle', (t) async {
      final scopeKey = GlobeIdLocale.enUS;
      late GlobeIdLocaleScopeState scopeState;
      await t.pumpWidget(
        GlobeIdLocaleScope(
          initial: scopeKey,
          child: MaterialApp(
            home: Builder(builder: (ctx) {
              scopeState = GlobeIdLocaleScope.of(ctx);
              final strings = GlobeIdLocaleScope.stringsOf(ctx);
              return Material(child: Text(strings.continueAction));
            }),
          ),
        ),
      );
      expect(find.text('Continue'), findsOneWidget);

      scopeState.setLocale(GlobeIdLocale.esES);
      await t.pump();

      expect(find.text('Continuar'), findsOneWidget);
    });
  });
}
