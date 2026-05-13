import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ambient/quick_settings_preview.dart';

void main() {
  group('QuickTileSpec', () {
    test('exposes three actions in the canonical order', () {
      expect(QuickTileSpec.all.length, 3);
      expect(QuickTileSpec.all[0].action, QuickTileAction.scan);
      expect(QuickTileSpec.all[1].action, QuickTileAction.vault);
      expect(QuickTileSpec.all[2].action, QuickTileAction.copilot);
    });
  });

  group('QuickSettingsTilePreview', () {
    testWidgets('iosExpanded renders handle + label + subtitle', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuickSettingsTilePreview(
                spec: QuickTileSpec.scan,
                form: QuickTileForm.iosExpanded,
              ),
            ),
          ),
        ),
      );
      expect(find.text('SCAN · GLOBE·ID'), findsOneWidget);
      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('READ ANY CREDENTIAL'), findsOneWidget);
    });

    testWidgets('iosCompact renders the spec icon', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuickSettingsTilePreview(
                spec: QuickTileSpec.scan,
                form: QuickTileForm.iosCompact,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    });

    testWidgets('androidTile renders icon + label + subtitle', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuickSettingsTilePreview(
                spec: QuickTileSpec.vault,
                form: QuickTileForm.androidTile,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Vault'), findsOneWidget);
      expect(find.text('IDENTITY DASHBOARD'), findsOneWidget);
    });
  });

  group('Panels', () {
    testWidgets('IosControlCenterPanel hosts every tile passed in', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IosControlCenterPanel(
                tiles: [
                  for (final spec in QuickTileSpec.all)
                    QuickSettingsTilePreview(
                      spec: spec,
                      form: QuickTileForm.iosCompact,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(QuickSettingsTilePreview), findsNWidgets(3));
    });

    testWidgets('AndroidQuickSettingsPanel renders the system eyebrow',
        (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AndroidQuickSettingsPanel(
                tiles: [
                  for (final spec in QuickTileSpec.all)
                    QuickSettingsTilePreview(
                      spec: spec,
                      form: QuickTileForm.androidTile,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('09:24 · TUE'), findsOneWidget);
      expect(find.text('WIFI · 5G · 92%'), findsOneWidget);
    });
  });
}
