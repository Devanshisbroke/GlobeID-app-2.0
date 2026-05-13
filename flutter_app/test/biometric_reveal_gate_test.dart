import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/identity/biometric_reveal_gate.dart';

class _StubAuth implements BiometricAuthenticator {
  _StubAuth({this.willPass = true, this.callsRecorded});
  bool willPass;
  final List<String>? callsRecorded;
  int callCount = 0;
  @override
  Future<bool> authenticate({required String reason}) async {
    callCount++;
    callsRecorded?.add(reason);
    return willPass;
  }
}

void main() {
  group('maskValue', () {
    test('replaces every non-separator char with a mid-dot', () {
      expect(maskValue('AB1234567'), '·········');
    });

    test('preserves spaces, dashes, slashes, dots', () {
      // Spaces / dashes / slashes / mid-dots are preserved 1:1; every
      // other glyph maps to a mid-dot. Mid-dots in the input blend
      // visually with the masked output, which is the point —
      // silhouette stays stable.
      expect(maskValue('AB 12-34/56-78'), '·· ··-··/··-··');
      expect(maskValue('A/B'), '·/·');
    });

    test('blank value returns the fallback', () {
      expect(maskValue(''), '— — — —');
      expect(maskValue('   ', fallback: '∅'), '∅');
    });
  });

  group('BiometricRevealGate — UI', () {
    testWidgets('renders masked value + TAP TO REVEAL hint by default',
        (t) async {
      final auth = _StubAuth();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricRevealGate(
              label: 'Passport number',
              value: 'AB1234567',
              authenticator: auth,
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('PASSPORT NUMBER'), findsOneWidget);
      expect(find.text('TAP TO REVEAL · BIOMETRIC GATED'), findsOneWidget);
      // Value is not visible yet.
      expect(find.text('AB1234567'), findsNothing);
    });

    testWidgets('tap with successful auth reveals the value', (t) async {
      final auth = _StubAuth(willPass: true);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricRevealGate(
              label: 'Passport number',
              value: 'AB1234567',
              authenticator: auth,
              // Disable auto-lock for this test.
              autoLockAfter: Duration.zero,
            ),
          ),
        ),
      );
      await t.tap(find.byType(BiometricRevealGate));
      await t.pumpAndSettle();
      expect(auth.callCount, 1);
      expect(find.text('AB1234567'), findsOneWidget);
      expect(find.text('REVEALED · TAP TO LOCK'), findsOneWidget);
    });

    testWidgets('tap with failed auth keeps the value masked', (t) async {
      final auth = _StubAuth(willPass: false);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricRevealGate(
              label: 'Passport number',
              value: 'AB1234567',
              authenticator: auth,
              autoLockAfter: Duration.zero,
            ),
          ),
        ),
      );
      await t.tap(find.byType(BiometricRevealGate));
      await t.pumpAndSettle();
      expect(auth.callCount, 1);
      expect(find.text('AB1234567'), findsNothing);
      expect(find.text('TAP TO REVEAL · BIOMETRIC GATED'), findsOneWidget);
    });

    testWidgets('tap on a revealed gate locks it immediately without re-auth',
        (t) async {
      final auth = _StubAuth(willPass: true);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricRevealGate(
              label: 'Passport number',
              value: 'AB1234567',
              authenticator: auth,
              autoLockAfter: Duration.zero,
            ),
          ),
        ),
      );
      // First tap reveals.
      await t.tap(find.byType(BiometricRevealGate));
      await t.pumpAndSettle();
      expect(find.text('AB1234567'), findsOneWidget);
      // Second tap re-locks without invoking authenticate again.
      await t.tap(find.byType(BiometricRevealGate));
      await t.pumpAndSettle();
      expect(auth.callCount, 1);
      expect(find.text('AB1234567'), findsNothing);
    });

    testWidgets('reason string is forwarded to the authenticator',
        (t) async {
      final calls = <String>[];
      final auth = _StubAuth(willPass: false, callsRecorded: calls);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricRevealGate(
              label: 'Passport number',
              value: 'AB1234567',
              authenticator: auth,
              reason: 'Reveal passport',
            ),
          ),
        ),
      );
      await t.tap(find.byType(BiometricRevealGate));
      await t.pumpAndSettle();
      expect(calls, ['Reveal passport']);
    });
  });
}
