import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/sheets/apple_sheet.dart';

void main() {
  group('AppleSheet — substrate', () {
    testWidgets('mounts, renders builder content, and dismisses cleanly',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppleSheet<void>(
                    context: capturedContext,
                    title: 'Sheet title',
                    eyebrow: 'EYEBROW · STRIP',
                    builder: (controller) => ListView(
                      controller: controller,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('SHEET BODY CONTENT'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      // The DraggableScrollableSheet + entrance animation needs a
      // handful of pumps before everything settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 280));

      expect(find.text('Sheet title'), findsOneWidget);
      expect(find.text('EYEBROW · STRIP'), findsOneWidget);
      expect(find.text('SHEET BODY CONTENT'), findsOneWidget);

      // Tapping the backdrop should dismiss the sheet.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('SHEET BODY CONTENT'), findsNothing);
    });

    testWidgets('renders without title / eyebrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppleSheet<void>(
                  context: ctx,
                  builder: (controller) => ListView(
                    controller: controller,
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('NO HEADER BODY'),
                      ),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.text('NO HEADER BODY'), findsOneWidget);
    });
  });
}
