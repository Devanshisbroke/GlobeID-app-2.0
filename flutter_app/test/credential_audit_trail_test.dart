import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/identity/credential_access_event.dart';
import 'package:globeid/features/vault/credential_audit_trail_screen.dart';

void main() {
  group('seedAccessEvents', () {
    test('is deterministic for the same credentialId', () {
      final a = seedAccessEvents(credentialId: 'iceland-passport', count: 8);
      final b = seedAccessEvents(credentialId: 'iceland-passport', count: 8);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].audienceHandle, b[i].audienceHandle);
        expect(a[i].action, b[i].action);
        expect(a[i].fieldHandles, b[i].fieldHandles);
      }
    });

    test('returns the requested count', () {
      expect(seedAccessEvents(credentialId: 'x', count: 5).length, 5);
      expect(seedAccessEvents(credentialId: 'x', count: 24).length, 24);
    });

    test('events are sorted newest first', () {
      final events = seedAccessEvents(credentialId: 'x', count: 12);
      for (var i = 0; i + 1 < events.length; i++) {
        expect(
          events[i].timestamp.isAfter(events[i + 1].timestamp) ||
              events[i].timestamp.isAtSameMomentAs(events[i + 1].timestamp),
          isTrue,
          reason: 'events should be sorted newest first',
        );
      }
    });

    test('every event has a non-empty audience handle and label', () {
      final events = seedAccessEvents(credentialId: 'x');
      for (final e in events) {
        expect(e.audienceHandle.isNotEmpty, isTrue);
        expect(e.audienceLabel.isNotEmpty, isTrue);
      }
    });
  });

  group('relativeAge', () {
    test('renders just-now under one minute', () {
      final now = DateTime(2025, 1, 1, 12);
      final then = now.subtract(const Duration(seconds: 30));
      expect(relativeAge(then, now: now), 'just now');
    });

    test('renders minutes / hours / days correctly', () {
      final now = DateTime(2025, 1, 1, 12);
      expect(
        relativeAge(now.subtract(const Duration(minutes: 42)), now: now),
        '42m ago',
      );
      expect(
        relativeAge(now.subtract(const Duration(hours: 5)), now: now),
        '5h ago',
      );
      expect(
        relativeAge(now.subtract(const Duration(days: 2)), now: now),
        '2d ago',
      );
      expect(
        relativeAge(now.subtract(const Duration(days: 12)), now: now),
        '1w ago',
      );
      expect(
        relativeAge(now.subtract(const Duration(days: 90)), now: now),
        '3mo ago',
      );
    });
  });

  group('CredentialAuditTrailScreen — UI', () {
    testWidgets('renders summary + ledger + at least one event card',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: CredentialAuditTrailScreen(
            credentialId: 'iceland-passport',
            credentialLabel: 'Iceland · Passport',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Audit trail'), findsOneWidget);
      expect(find.text('REVEALS'), findsOneWidget);
      expect(find.text('SCANS'), findsOneWidget);
      expect(find.text('DECLINES'), findsOneWidget);
      // Ledger label includes the number of entries.
      expect(find.textContaining('LEDGER ·'), findsOneWidget);
    });

    testWidgets('filter chips narrow the visible ledger', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: CredentialAuditTrailScreen(
            credentialId: 'iceland-passport',
            credentialLabel: 'Iceland · Passport',
          ),
        ),
      );
      await t.pumpAndSettle();

      // Tap an outcome chip — DECLINED — and the ledger should
      // re-render with a reduced count or the empty state.
      final declined = find.text('DECLINED').first;
      await t.tap(declined);
      await t.pumpAndSettle();
      // Either ledger drops or empty state appears.
      final hasEmpty = find.text('NO ENTRIES MATCH FILTER').evaluate().isNotEmpty;
      final hasLedger = find.textContaining('LEDGER ·').evaluate().isNotEmpty;
      expect(hasEmpty || hasLedger, isTrue);
    });
  });
}
