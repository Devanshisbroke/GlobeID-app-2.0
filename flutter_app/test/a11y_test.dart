import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/widgets/empty_state.dart';
import 'package:globeid/widgets/premium/inbox_premium_row.dart';
import 'package:globeid/widgets/premium/magnetic_pressable.dart';
import 'package:globeid/widgets/pressable.dart';

void main() {
  group('Pressable — semantic layer', () {
    testWidgets(
      'no semantic label leaves the affordance untouched',
      (t) async {
        await t.pumpWidget(
          const MaterialApp(
            home: Pressable(
              onTap: null,
              child: Icon(Icons.flag_rounded),
            ),
          ),
        );
        // No label → no extra Semantics node from Pressable.
        expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      },
    );

    testWidgets(
      'semantic label surfaces as a button node',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            home: Material(
              child: Pressable(
                onTap: () {},
                semanticLabel: 'Open passport',
                semanticHint: 'opens the bearer page',
                child: const Icon(Icons.menu_book_rounded),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Open passport'), findsOneWidget);

        final node = t.getSemantics(find.bySemanticsLabel('Open passport'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.hint, 'opens the bearer page');

        handle.dispose();
      },
    );

    testWidgets(
      'disabled (no callbacks) still announces label without tap action',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          const MaterialApp(
            home: Material(
              child: Pressable(
                semanticLabel: 'Disabled action',
                child: Icon(Icons.lock_rounded),
              ),
            ),
          ),
        );

        final node = t.getSemantics(find.bySemanticsLabel('Disabled action'));
        // Tristate: when the affordance is disabled, isEnabled is isFalse
        // (property applies, state is "false / off").
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        handle.dispose();
      },
    );
  });

  group('MagneticPressable — semantic layer', () {
    testWidgets(
      'semantic label surfaces as a button node',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            home: Material(
              child: MagneticPressable(
                onTap: () {},
                semanticLabel: 'Premium service',
                semanticHint: 'opens the service detail',
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Icon(Icons.star_rounded),
                ),
              ),
            ),
          ),
        );

        final node = t.getSemantics(find.bySemanticsLabel('Premium service'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.hint, 'opens the service detail');
        handle.dispose();
      },
    );
  });

  group('InboxPremiumRow — semantic layer', () {
    testWidgets(
      'unread row announces unread status in the label',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            home: Material(
              child: InboxPremiumRow(
                icon: Icons.flight_rounded,
                title: 'Gate change',
                subtitle: 'Now boarding from B22',
                tone: const Color(0xFFD4AF37),
                unread: true,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp('Gate change, unread')),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'read row drops the unread marker',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            home: Material(
              child: InboxPremiumRow(
                icon: Icons.flight_rounded,
                title: 'Boarding ended',
                subtitle: 'Flight LH437',
                tone: const Color(0xFFD4AF37),
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Boarding ended'), findsOneWidget);
        handle.dispose();
      },
    );
  });

  group('EmptyState — semantic layer', () {
    testWidgets(
      'empty state announces the title + message as a live region',
      (t) async {
        final handle = t.ensureSemantics();
        await t.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyState(
                title: 'No trips yet',
                message: 'Plan your first trip to see it here.',
                icon: Icons.flight_takeoff_rounded,
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(
            'No trips yet. Plan your first trip to see it here.',
          ),
          findsOneWidget,
        );
        handle.dispose();
      },
    );
  });
}
