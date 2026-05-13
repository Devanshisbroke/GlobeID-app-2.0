import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ceremony/passport_opening_ceremony.dart';

void main() {
  group('phaseFor', () {
    test('0 → closed', () {
      expect(phaseFor(0), PassportCeremonyPhase.closed);
      expect(phaseFor(-0.5), PassportCeremonyPhase.closed);
    });
    test('substrate dawn 0 → 0.18', () {
      expect(phaseFor(0.05), PassportCeremonyPhase.substrateDawn);
      expect(phaseFor(0.17), PassportCeremonyPhase.substrateDawn);
    });
    test('foil sweep 0.18 → 0.46', () {
      expect(phaseFor(0.20), PassportCeremonyPhase.foilSweep);
      expect(phaseFor(0.45), PassportCeremonyPhase.foilSweep);
    });
    test('emboss settle 0.46 → 0.66', () {
      expect(phaseFor(0.50), PassportCeremonyPhase.embossSettle);
      expect(phaseFor(0.65), PassportCeremonyPhase.embossSettle);
    });
    test('bearer reveal 0.66 → 1.0', () {
      expect(phaseFor(0.70), PassportCeremonyPhase.bearerReveal);
      expect(phaseFor(0.99), PassportCeremonyPhase.bearerReveal);
    });
    test('1.0 → settled', () {
      expect(phaseFor(1.0), PassportCeremonyPhase.settled);
      expect(phaseFor(1.5), PassportCeremonyPhase.settled);
    });
  });

  group('PassportCeremonyPhase.handle', () {
    test('every phase has a MONO-CAP handle', () {
      for (final p in PassportCeremonyPhase.values) {
        expect(p.handle, equals(p.handle.toUpperCase()));
        expect(p.handle, isNotEmpty);
      }
    });
  });

  group('PassportOpeningCeremony — host integration', () {
    testWidgets('renders bearer when play=false (substrate idle)', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: PassportOpeningCeremony(
              play: false,
              bearer: SizedBox.shrink(),
            ),
          ),
        ),
      );
      // No exception; ceremony mounts at progress 0 without auto-playing.
      expect(find.byType(PassportOpeningCeremony), findsOneWidget);
    });

    testWidgets('plays to completion when play=true', (t) async {
      var settled = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: PassportOpeningCeremony(
              play: true,
              duration: const Duration(milliseconds: 600),
              onSettled: () => settled = true,
              bearer: const _Bearer(),
            ),
          ),
        ),
      );
      // Walk the animation forward; AnimationController completes after duration.
      await t.pump(); // initial
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 700));
      expect(settled, isTrue);
    });

    testWidgets('flipping play=true → false resets the controller',
        (t) async {
      var settled = false;
      Widget host(bool play) => MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: PassportOpeningCeremony(
                play: play,
                duration: const Duration(milliseconds: 400),
                onSettled: () => settled = true,
                bearer: const _Bearer(),
              ),
            ),
          );
      await t.pumpWidget(host(true));
      await t.pump(const Duration(milliseconds: 100));
      await t.pumpWidget(host(false));
      await t.pump(const Duration(milliseconds: 500));
      // Reset means onSettled does not fire after we flipped play off early.
      expect(settled, isFalse);
    });
  });
}

class _Bearer extends StatelessWidget {
  const _Bearer();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 80, height: 100);
}
