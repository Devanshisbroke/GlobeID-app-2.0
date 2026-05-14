import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/i18n/brand_text_scale.dart';

void main() {
  group('BrandTextScale clamping', () {
    test('body never clamps', () {
      expect(BrandTextScale.clampForBody(1.0), 1.0);
      expect(BrandTextScale.clampForBody(2.0), 2.0);
      expect(BrandTextScale.clampForBody(3.5), 3.5);
    });

    test('chrome caps at 1.35×', () {
      expect(BrandTextScale.clampForChrome(1.0), 1.0);
      expect(BrandTextScale.clampForChrome(1.2), 1.2);
      expect(BrandTextScale.clampForChrome(1.35), 1.35);
      expect(BrandTextScale.clampForChrome(2.0), 1.35);
      expect(BrandTextScale.clampForChrome(3.0), 1.35);
    });

    test('chrome never scales below 1.0×', () {
      expect(BrandTextScale.clampForChrome(0.85), 1.0);
    });

    test('credential caps at 1.20×', () {
      expect(BrandTextScale.clampForCredential(1.0), 1.0);
      expect(BrandTextScale.clampForCredential(1.1), 1.1);
      expect(BrandTextScale.clampForCredential(1.2), 1.2);
      expect(BrandTextScale.clampForCredential(2.0), 1.2);
    });
  });

  group('BrandTextScale.scalerOf', () {
    testWidgets('body role respects the system textScaler', (t) async {
      late TextScaler scaler;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Builder(builder: (ctx) {
            scaler = BrandTextScale.scalerOf(ctx, BrandTextRole.body);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(scaler.scale(10), 20);
    });

    testWidgets('chrome role caps at 1.35×', (t) async {
      late TextScaler scaler;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Builder(builder: (ctx) {
            scaler = BrandTextScale.scalerOf(ctx, BrandTextRole.chrome);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(scaler.scale(10), 13.5);
    });

    testWidgets('credential role caps at 1.20×', (t) async {
      late TextScaler scaler;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Builder(builder: (ctx) {
            scaler = BrandTextScale.scalerOf(ctx, BrandTextRole.credential);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(scaler.scale(10), 12);
    });

    testWidgets('chrome below cap is unchanged', (t) async {
      late TextScaler scaler;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
          child: Builder(builder: (ctx) {
            scaler = BrandTextScale.scalerOf(ctx, BrandTextRole.chrome);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(scaler.scale(10), closeTo(12.0, 1e-6));
    });
  });

  group('ChromeTextScale / CredentialTextScale widgets', () {
    testWidgets('ChromeTextScale clamps the MediaQuery textScaler',
        (t) async {
      late double scaledFor10;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: ChromeTextScale(
            child: Builder(builder: (ctx) {
              scaledFor10 = MediaQuery.textScalerOf(ctx).scale(10);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(scaledFor10, 13.5);
    });

    testWidgets('CredentialTextScale clamps the MediaQuery textScaler',
        (t) async {
      late double scaledFor10;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: CredentialTextScale(
            child: Builder(builder: (ctx) {
              scaledFor10 = MediaQuery.textScalerOf(ctx).scale(10);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(scaledFor10, 12);
    });
  });
}
