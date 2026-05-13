import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ambient/lock_screen_preview.dart';

const _model = LockWidgetModel(
  headline: 'LH 401 · B27',
  subline: 'BOARDING · 0:18',
  tickerDigit: '0:18',
);

void main() {
  group('LockWidgetPreview', () {
    testWidgets('accessoryCircular renders the digit only', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockWidgetPreview(
                model: _model,
                form: LockWidgetForm.accessoryCircular,
              ),
            ),
          ),
        ),
      );
      expect(find.text('0:18'), findsOneWidget);
      expect(find.text('LH 401 · B27'), findsNothing);
    });

    testWidgets('accessoryRectangular renders headline + subline + watermark',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockWidgetPreview(
                model: _model,
                form: LockWidgetForm.accessoryRectangular,
              ),
            ),
          ),
        ),
      );
      expect(find.text('LH 401 · B27'), findsOneWidget);
      expect(find.text('BOARDING · 0:18'), findsOneWidget);
      expect(find.text('GLOBE·ID'), findsOneWidget);
    });

    testWidgets('accessoryInline renders the combined row', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockWidgetPreview(
                model: _model,
                form: LockWidgetForm.accessoryInline,
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('LH 401 · B27 · BOARDING · 0:18'),
        findsOneWidget,
      );
    });

    testWidgets('alwaysOnDim renders the same data as rectangular', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockWidgetPreview(
                model: _model,
                form: LockWidgetForm.alwaysOnDim,
              ),
            ),
          ),
        ),
      );
      expect(find.text('LH 401 · B27'), findsOneWidget);
      expect(find.text('BOARDING · 0:18'), findsOneWidget);
    });
  });

  group('LockScreenStencil', () {
    testWidgets('renders 09:24 clock + the widget at the specified slot',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockScreenStencil(
                slot: LockSlot.belowTime,
                widget: LockWidgetPreview(
                  model: _model,
                  form: LockWidgetForm.accessoryRectangular,
                ),
              ),
            ),
          ),
        ),
      );
      // The stencil renders a status bar 09:24 + the big 09:24 clock,
      // so 2 occurrences expected.
      expect(find.text('09:24'), findsNWidgets(2));
      expect(find.text('LH 401 · B27'), findsOneWidget);
    });

    testWidgets('dim mode swaps the status eyebrow', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LockScreenStencil(
                dim: true,
                slot: LockSlot.belowTime,
                widget: LockWidgetPreview(
                  model: _model,
                  form: LockWidgetForm.alwaysOnDim,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('...'), findsOneWidget);
      expect(find.text('WIFI · 5G'), findsNothing);
    });
  });
}
