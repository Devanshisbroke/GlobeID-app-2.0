import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/copilot/trust_score_breakdown.dart';
import 'package:globeid/data/models/travel_score.dart';

void main() {
  final score = TravelScore(
    score: 824,
    tier: 2,
    factors: [
      TravelScoreFactor(id: 'identity', label: 'Identity', weight: 0.32, value: 0.94),
      TravelScoreFactor(id: 'history', label: 'History', weight: 0.24, value: 0.86),
      TravelScoreFactor(id: 'payments', label: 'Payments', weight: 0.18, value: 0.91),
      TravelScoreFactor(id: 'social', label: 'Social', weight: 0.14, value: 0.74),
      TravelScoreFactor(id: 'compliance', label: 'Compliance', weight: 0.12, value: 1.0),
    ],
    history: [780, 790, 805, 818, 824],
  );

  group('TrustScoreBreakdown', () {
    testWidgets('renders hero number + tier + every factor row', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(score: score),
            ),
          ),
        ),
      );

      expect(find.text('824'), findsOneWidget);
      expect(find.text('TIER · GOLD'), findsOneWidget);
      expect(find.text('IDENTITY'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('SOCIAL'), findsOneWidget);
      expect(find.text('COMPLIANCE'), findsOneWidget);
    });

    testWidgets('renders weight deltas as percent mono-caps', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(score: score),
            ),
          ),
        ),
      );

      // 0.32 → "+32", 0.24 → "+24", etc.
      expect(find.text('+32'), findsOneWidget);
      expect(find.text('+24'), findsOneWidget);
      expect(find.text('+18'), findsOneWidget);
    });

    testWidgets('CTA appears only when onImproveTap is provided', (t) async {
      // No CTA when callback is null.
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(score: score),
            ),
          ),
        ),
      );
      expect(find.text('IMPROVE SCORE'), findsNothing);

      // CTA renders when callback is provided.
      var tapped = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(
                score: score,
                onImproveTap: () => tapped += 1,
              ),
            ),
          ),
        ),
      );
      expect(find.text('IMPROVE SCORE'), findsOneWidget);

      await t.tap(find.text('IMPROVE SCORE'));
      // BreathingHalo runs an infinite breathing animation, so settle
      // can't terminate — pump a finite duration instead.
      await t.pump(const Duration(milliseconds: 100));
      expect(tapped, 1);
    });

    testWidgets('tier 3 reveals ELITE label', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(
                score: TravelScore(
                  score: 962,
                  tier: 3,
                  factors: score.factors,
                  history: score.history,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('TIER · ELITE'), findsOneWidget);
    });

    testWidgets('tier 0 reveals BRONZE label', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrustScoreBreakdown(
                score: TravelScore(
                  score: 510,
                  tier: 0,
                  factors: score.factors,
                  history: score.history,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('TIER · BRONZE'), findsOneWidget);
    });
  });
}
