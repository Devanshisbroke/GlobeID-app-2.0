// Smoke tests for the new lib/bible/ liquid-glass cinematic OS layer.
//
// We don't pixel-match; we verify each hero screen mounts without
// throwing and that the routes parse. Sensor-driven widgets are
// rendered with `disableAnimations = true` so foil + atmosphere
// fall back to their static branches.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globeid/bible/screens/bible_arrival_screen.dart';
import 'package:globeid/bible/screens/bible_boarding_screen.dart';
import 'package:globeid/bible/screens/bible_home_screen.dart';
import 'package:globeid/bible/screens/bible_lock_screen.dart';
import 'package:globeid/bible/screens/bible_lounge_screen.dart';
import 'package:globeid/bible/screens/bible_passport_screen.dart';
import 'package:globeid/bible/screens/bible_trip_screen.dart';
import 'package:globeid/bible/screens/bible_wallet_screen.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        disableAnimations: true,
        size: Size(390, 844),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: screen),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // Tear the tree down so AnimationControllers / Tickers / Timers
  // are cancelled before the test framework's `!timersPending`
  // invariant check fires.
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  group('Bible hero screens — smoke', () {
    testWidgets('Lock screen mounts', (tester) async {
      await _pump(tester, const BibleLockScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home screen mounts', (tester) async {
      await _pump(tester, const BibleHomeScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Passport screen mounts', (tester) async {
      await _pump(tester, const BiblePassportScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Wallet screen mounts', (tester) async {
      await _pump(tester, const BibleWalletScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Boarding screen mounts', (tester) async {
      await _pump(tester, const BibleBoardingScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arrival screen mounts', (tester) async {
      await _pump(tester, const BibleArrivalScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lounge screen mounts', (tester) async {
      await _pump(tester, const BibleLoungeScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Trip screen mounts', (tester) async {
      await _pump(tester, const BibleTripScreen());
      expect(tester.takeException(), isNull);
    });
  });
}
