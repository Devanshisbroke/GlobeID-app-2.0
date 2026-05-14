import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/branding/camera_chrome.dart';

void main() {
  group('ScanModeSpec', () {
    test('every mode resolves to a spec', () {
      for (final mode in ScanMode.values) {
        final spec = ScanModeSpec.of(mode);
        expect(spec.label.isNotEmpty, isTrue);
        expect(spec.aim.aspect, greaterThan(0));
        expect(spec.aim.widthFraction, lessThanOrEqualTo(1.0));
        expect(spec.aim.widthFraction, greaterThan(0));
      }
    });

    test('mode labels read as mono-cap copy', () {
      expect(ScanModeSpec.passport.label, 'SCANNING · PASSPORT');
      expect(ScanModeSpec.face.label, 'SCANNING · FACE');
      expect(ScanModeSpec.qr.label, 'SCANNING · QR · CODE');
      expect(ScanModeSpec.nfc.label, 'NFC · TAP · TO · READ');
      expect(ScanModeSpec.document.label, 'SCANNING · DOCUMENT');
    });

    test('face mode uses an oval aim, others use brackets', () {
      expect(ScanModeSpec.face.aim.oval, isTrue);
      expect(ScanModeSpec.passport.aim.oval, isFalse);
      expect(ScanModeSpec.qr.aim.oval, isFalse);
      expect(ScanModeSpec.nfc.aim.oval, isFalse);
      expect(ScanModeSpec.document.aim.oval, isFalse);
    });

    test('cadence is monotonic-ish — faster modes have shorter cadence', () {
      // QR is the lowest-effort scan, so its cadence should be the
      // shortest. NFC is the most patient (tap and hold), so longest.
      expect(
        ScanModeSpec.qr.scanCadence,
        lessThan(ScanModeSpec.passport.scanCadence),
      );
      expect(
        ScanModeSpec.nfc.scanCadence,
        greaterThan(ScanModeSpec.qr.scanCadence),
      );
    });
  });

  group('computeAimRect', () {
    test('aim is centred horizontally', () {
      final size = const Size(400, 600);
      final rect = computeAimRect(size, ScanModeSpec.qr.aim);
      expect(rect.center.dx, closeTo(size.width / 2, 0.5));
    });

    test('aim respects widthFraction', () {
      final size = const Size(400, 600);
      final rect = computeAimRect(size, ScanModeSpec.qr.aim);
      expect(rect.width, closeTo(size.width * 0.62, 0.5));
    });

    test('aim height = width * aspect', () {
      final size = const Size(400, 600);
      final rect = computeAimRect(size, ScanModeSpec.passport.aim);
      expect(rect.height, closeTo(rect.width * 0.62, 0.5));
    });
  });

  group('CameraChrome widget', () {
    testWidgets('mounts with passport mode + GLOBE · ID watermark',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: CameraChrome(
                mode: ScanMode.passport,
                child: ColoredBox(color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      // Pump once more so the AnimationController emits a tick.
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('SCANNING · PASSPORT'), findsOneWidget);
      expect(find.text('GLOBE · ID'), findsOneWidget);
      expect(find.text('N° SCAN-OPEN'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('updates chrome when mode changes', (t) async {
      Widget testWidget(ScanMode mode) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CameraChrome(
                  mode: mode,
                  child: const ColoredBox(color: Color(0xFF000000)),
                ),
              ),
            ),
          );
      await t.pumpWidget(testWidget(ScanMode.passport));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('SCANNING · PASSPORT'), findsOneWidget);
      await t.pumpWidget(testWidget(ScanMode.face));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('SCANNING · FACE'), findsOneWidget);
      expect(find.text('SCANNING · PASSPORT'), findsNothing);
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('uses a custom case number when provided', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: CameraChrome(
                mode: ScanMode.qr,
                caseNumber: 'N° QR-TEST',
                child: ColoredBox(color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('N° QR-TEST'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
    });
  });
}
