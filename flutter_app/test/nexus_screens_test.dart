import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/nexus/screens/nexus_passport_screen.dart';
import 'package:globeid/nexus/screens/nexus_travel_os_screen.dart';
import 'package:globeid/nexus/screens/nexus_wallet_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SizedBox(
      width: 390,
      height: 1100,
      child: child,
    ),
  );
}

void main() {
  testWidgets('NexusTravelOsScreen renders core surfaces', (tester) async {
    tester.view.physicalSize = const Size(1170, 3300);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const NexusTravelOsScreen()));
    await tester.pump();
    expect(find.text('GlobeID Travel OS'), findsOneWidget);
    expect(find.text('ZRH'), findsOneWidget);
    expect(find.text('SIN'), findsOneWidget);
  });

  testWidgets('NexusWalletScreen renders the global reserve', (tester) async {
    tester.view.physicalSize = const Size(1170, 3300);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const NexusWalletScreen()));
    await tester.pump();
    expect(find.text('Global Reserve'), findsOneWidget);
    expect(find.text('\$237,031'), findsOneWidget);
  });

  testWidgets('NexusPassportScreen renders bearer + credentials', (tester) async {
    tester.view.physicalSize = const Size(1170, 3300);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const NexusPassportScreen()));
    await tester.pump();
    expect(find.text('Diplomatic Credential'), findsOneWidget);
    expect(find.text('ALEXANDER V. GRAFF'), findsOneWidget);
  });
}
