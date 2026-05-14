import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ambient/live_activity_preview.dart';

const _model = LiveActivityModel(
  flightCode: 'LH 401',
  gate: 'B27',
  boardingIn: Duration(minutes: 18),
  origin: 'FRA',
  destination: 'OSL',
  seat: '12A',
);

void main() {
  group('LiveActivityPreview', () {
    testWidgets('minimal renders the gold pill glyph', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveActivityPreview(
              model: _model,
              form: LiveActivityForm.minimal,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    });

    testWidgets('compact renders the countdown', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveActivityPreview(
                model: _model,
                form: LiveActivityForm.compact,
              ),
            ),
          ),
        ),
      );
      expect(find.text('BOARDING · 0:18'), findsOneWidget);
    });

    testWidgets('expanded renders origin / destination / gate / seat',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveActivityPreview(
              model: _model,
              form: LiveActivityForm.expanded,
            ),
          ),
        ),
      );
      expect(find.text('FRA'), findsOneWidget);
      expect(find.text('OSL'), findsOneWidget);
      expect(find.text('B27'), findsOneWidget);
      expect(find.text('ORIGIN'), findsOneWidget);
      expect(find.text('DESTINATION'), findsOneWidget);
      expect(find.text('LH 401 · SEAT 12A'), findsOneWidget);
    });

    testWidgets('expanded formats hours when boardingIn >= 1h', (t) async {
      const model = LiveActivityModel(
        flightCode: 'LH 401',
        gate: 'B27',
        boardingIn: Duration(hours: 2, minutes: 5),
        origin: 'FRA',
        destination: 'OSL',
        seat: '12A',
      );
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveActivityPreview(
              model: model,
              form: LiveActivityForm.expanded,
            ),
          ),
        ),
      );
      expect(find.text('2:05'), findsOneWidget);
    });
  });

  testWidgets('DeviceFrame hosts the child at the top center', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeviceFrame(
            child: LiveActivityPreview(
              model: _model,
              form: LiveActivityForm.compact,
            ),
          ),
        ),
      ),
    );
    expect(find.text('BOARDING · 0:18'), findsOneWidget);
  });
}
