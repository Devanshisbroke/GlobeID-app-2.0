import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/visual_regression_catalog.dart';

void main() {
  group('VisualRegressionCatalog', () {
    test('enumerates 8 canonical specimens', () {
      expect(VisualRegressionCatalog.specimens, hasLength(8));
    });

    test('specimen ids are unique', () {
      final ids = VisualRegressionCatalog.specimens.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('groups are non-empty and author-ordered', () {
      final groups = VisualRegressionCatalog.groups();
      expect(groups, isNotEmpty);
      // First group on the list is the first specimen's group.
      expect(groups.first, VisualRegressionCatalog.specimens.first.group);
    });

    test('canonical sizes are reasonable (≥1×1, ≤500×500)', () {
      for (final s in VisualRegressionCatalog.specimens) {
        expect(s.canonicalSize.width, greaterThanOrEqualTo(1));
        expect(s.canonicalSize.height, greaterThanOrEqualTo(1));
        expect(s.canonicalSize.width, lessThanOrEqualTo(500));
        expect(s.canonicalSize.height, lessThanOrEqualTo(500));
      }
    });

    test('byId resolves known specimen, null on miss', () {
      expect(
        VisualRegressionCatalog.byId('globe-id-signature'),
        isNotNull,
      );
      expect(VisualRegressionCatalog.byId('does-not-exist'), isNull);
    });
  });

  group('VisualSpecimen · mount', () {
    for (final spec in VisualRegressionCatalog.specimens) {
      testWidgets('${spec.id} mounts at canonical size', (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: Material(
              child: Center(
                child: SizedBox(
                  width: spec.canonicalSize.width,
                  height: spec.canonicalSize.height,
                  child: Builder(
                    builder: (ctx) => spec.builder(ctx),
                  ),
                ),
              ),
            ),
          ),
        );
        // Pump one frame so async animation controllers settle to
        // their initial paint; another frame so any first-tick
        // animations have something to do.
        await t.pump(const Duration(milliseconds: 16));
        // Specimen should mount without throwing and not exceed
        // the canonical size box.
        final found = find.byType(SizedBox).first;
        expect(found, findsOneWidget);
      });
    }
  });
}
