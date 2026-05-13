import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/offline/stale_text.dart';
import 'package:globeid/data/offline/timestamped_cache.dart';
import 'package:globeid/widgets/stale_chip.dart';

void main() {
  group('staleHandle', () {
    test('seconds < 60 → s · AGO', () {
      expect(staleHandle(const Duration(seconds: 12)), 'STALE · 12s · AGO');
    });
    test('minutes < 60 → m · AGO', () {
      expect(staleHandle(const Duration(minutes: 14)), 'STALE · 14m · AGO');
    });
    test('hours < 24 → h · AGO', () {
      expect(staleHandle(const Duration(hours: 2)), 'STALE · 2h · AGO');
    });
    test('days < 30 → d · AGO', () {
      expect(staleHandle(const Duration(days: 3)), 'STALE · 3d · AGO');
    });
    test('months ≥ 30 → mo · AGO', () {
      expect(staleHandle(const Duration(days: 45)), 'STALE · 1mo · AGO');
    });
  });

  group('staleSeverity', () {
    test('fresh < 5m', () {
      expect(
        staleSeverity(const Duration(minutes: 1)),
        StaleSeverity.fresh,
      );
    });
    test('notice 5–60m', () {
      expect(
        staleSeverity(const Duration(minutes: 30)),
        StaleSeverity.notice,
      );
    });
    test('warning 1–24h', () {
      expect(
        staleSeverity(const Duration(hours: 6)),
        StaleSeverity.warning,
      );
    });
    test('danger > 24h', () {
      expect(
        staleSeverity(const Duration(days: 2)),
        StaleSeverity.danger,
      );
    });
  });

  group('TimestampedCache', () {
    test('put/get/contains/timestamp', () {
      final cache = TimestampedCache<String, int>();
      expect(cache.contains('x'), isFalse);
      cache.put('x', 42, at: DateTime(2025));
      expect(cache.get('x'), 42);
      expect(cache.timestamp('x'), DateTime(2025));
      expect(cache.contains('x'), isTrue);
    });

    test('isStale flips when age > threshold', () {
      var now = DateTime(2025, 1, 1, 10);
      final cache = TimestampedCache<String, int>(now: () => now);
      cache.put('x', 1);
      expect(cache.isStale('x', const Duration(minutes: 5)), isFalse);
      now = now.add(const Duration(minutes: 10));
      expect(cache.isStale('x', const Duration(minutes: 5)), isTrue);
    });

    test('forget removes one key', () {
      final cache = TimestampedCache<String, int>();
      cache.put('x', 1);
      cache.put('y', 2);
      cache.forget('x');
      expect(cache.contains('x'), isFalse);
      expect(cache.get('y'), 2);
    });

    test('clear empties the store', () {
      final cache = TimestampedCache<String, int>();
      cache.put('x', 1);
      cache.put('y', 2);
      cache.clear();
      expect(cache.isEmpty, isTrue);
    });

    test('age returns null for missing keys', () {
      final cache = TimestampedCache<String, int>();
      expect(cache.age('x'), isNull);
    });

    test('watch emits on put', () async {
      final cache = TimestampedCache<String, int>();
      final next = cache.watch('x').first;
      cache.put('x', 99);
      expect(await next, 99);
      await cache.dispose();
    });
  });

  group('StaleChip', () {
    testWidgets('hides when fresh (default)', (t) async {
      final now = DateTime(2025, 1, 1, 10);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StaleChip(
              fetchedAt: now.subtract(const Duration(minutes: 1)),
              now: now,
            ),
          ),
        ),
      ));
      expect(find.textContaining('STALE'), findsNothing);
    });

    testWidgets('renders when stale > 5m', (t) async {
      final now = DateTime(2025, 1, 1, 10);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StaleChip(
              fetchedAt: now.subtract(const Duration(minutes: 10)),
              now: now,
            ),
          ),
        ),
      ));
      // Os2Text.monoCap uppercases its content for the on-screen render.
      expect(find.textContaining('10M'), findsOneWidget);
    });

    testWidgets('renderWhenFresh shows label even when fresh', (t) async {
      final now = DateTime(2025, 1, 1, 10);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StaleChip(
              fetchedAt: now.subtract(const Duration(seconds: 30)),
              now: now,
              renderWhenFresh: true,
            ),
          ),
        ),
      ));
      expect(find.textContaining('STALE'), findsOneWidget);
    });
  });
}
