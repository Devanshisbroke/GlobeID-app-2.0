import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ambient/watch_face_preview.dart';

const _model = WatchComplicationModel(
  flightCode: 'LH 401',
  gate: 'B27',
  boardingIn: Duration(minutes: 18),
  origin: 'FRA',
  destination: 'OSL',
  trustScore: 842,
);

void main() {
  group('WatchComplicationPreview', () {
    testWidgets('circular renders only the countdown', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchComplicationPreview(
                model: _model,
                form: WatchComplicationForm.circular,
              ),
            ),
          ),
        ),
      );
      expect(find.text('0:18'), findsOneWidget);
      expect(find.text('FRA'), findsNothing);
    });

    testWidgets('inline renders flight + gate + countdown', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchComplicationPreview(
                model: _model,
                form: WatchComplicationForm.inline,
              ),
            ),
          ),
        ),
      );
      expect(find.text('LH 401 · GATE B27'), findsOneWidget);
      expect(find.text('0:18'), findsOneWidget);
    });

    testWidgets('modularSmall renders eyebrow + countdown + gate', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchComplicationPreview(
                model: _model,
                form: WatchComplicationForm.modularSmall,
              ),
            ),
          ),
        ),
      );
      expect(find.text('BOARDING'), findsOneWidget);
      expect(find.text('0:18'), findsOneWidget);
      expect(find.text('GATE B27'), findsOneWidget);
    });

    testWidgets('modularLarge renders origin → destination + flight',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchComplicationPreview(
                model: _model,
                form: WatchComplicationForm.modularLarge,
              ),
            ),
          ),
        ),
      );
      expect(find.text('GLOBE·ID'), findsOneWidget);
      expect(find.text('FRA'), findsOneWidget);
      expect(find.text('OSL'), findsOneWidget);
      expect(find.text('LH 401'), findsOneWidget);
      expect(find.text('0:18'), findsOneWidget);
    });

    testWidgets('countdown formats hours when boardingIn >= 1h', (t) async {
      const model = WatchComplicationModel(
        flightCode: 'LH 401',
        gate: 'B27',
        boardingIn: Duration(hours: 1, minutes: 30),
        origin: 'FRA',
        destination: 'OSL',
        trustScore: 842,
      );
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchComplicationPreview(
                model: model,
                form: WatchComplicationForm.circular,
              ),
            ),
          ),
        ),
      );
      expect(find.text('1:30'), findsOneWidget);
    });
  });

  testWidgets('WatchFaceStencil renders a complication centered', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: WatchFaceStencil(
              complication: WatchComplicationPreview(
                model: _model,
                form: WatchComplicationForm.modularLarge,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('FRA'), findsOneWidget);
    expect(find.text('OSL'), findsOneWidget);
  });
}
