import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:globeid/core/storage/preferences.dart';
import 'package:globeid/features/vault/vault_dashboard_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Preferences.instance = Preferences(await SharedPreferences.getInstance());
  });

  testWidgets('IdentityVaultDashboard renders the trust crown', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IdentityVaultDashboard()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('GLOBE·ID · TRUST'), findsOneWidget);
    expect(find.text('GOOD STANDING · ATTESTED'), findsOneWidget);
  });

  testWidgets('renders the portfolio strip with the 4 stats', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IdentityVaultDashboard()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('HELD'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);
    expect(find.text('EXPIRING'), findsOneWidget);
    expect(find.text('EXPIRED'), findsOneWidget);
  });

  testWidgets('renders the renewal radar eyebrow', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IdentityVaultDashboard()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('RENEWAL RADAR'), findsOneWidget);
  });

  testWidgets('renders the CTA strip with MINT NEW + AUDIT TRAIL',
      (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IdentityVaultDashboard()),
      ),
    );
    await t.pumpAndSettle();
    // CTA strip is below the fold on the default test viewport.
    await t.drag(find.byType(ListView).first, const Offset(0, -800));
    await t.pumpAndSettle();
    expect(find.text('MINT NEW'), findsOneWidget);
    expect(find.text('AUDIT TRAIL'), findsOneWidget);
  });
}
