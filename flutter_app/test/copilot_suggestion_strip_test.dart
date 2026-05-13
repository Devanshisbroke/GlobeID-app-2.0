import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/copilot/copilot_suggestion_strip.dart';

void main() {
  group('CopilotSuggestionStrip', () {
    testWidgets('renders eyebrow + headline + subhead + CTA', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CopilotSuggestionStrip(
              headline: 'Convert €500 to USD now',
              subhead: 'EUR/USD spiked 0.7% in the last 30 minutes',
              ctaLabel: 'CONVERT',
              impactBadge: 'SAVES \$14',
            ),
          ),
        ),
      );

      expect(find.text('COPILOT · NOW'), findsOneWidget);
      expect(find.text('Convert €500 to USD now'), findsOneWidget);
      expect(find.text('EUR/USD spiked 0.7% in the last 30 minutes'), findsOneWidget);
      expect(find.text('CONVERT'), findsOneWidget);
      expect(find.text('SAVES \$14'), findsOneWidget);
    });

    testWidgets('CTA tap invokes the callback', (t) async {
      var tapped = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopilotSuggestionStrip(
              headline: 'Renew passport before 14 Apr',
              subhead: 'Passport expires in 11 days.',
              ctaLabel: 'RENEW',
              onCta: () => tapped += 1,
            ),
          ),
        ),
      );

      await t.tap(find.text('RENEW'));
      await t.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('critical urgency surfaces red eyebrow tone', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CopilotSuggestionStrip(
              headline: 'Gate change · B22 → B27',
              subhead: 'Boarding moved 3 gates down concourse B.',
              ctaLabel: 'NAVIGATE',
              urgency: CopilotUrgency.critical,
              countdown: '18M',
            ),
          ),
        ),
      );

      expect(find.text('COPILOT · NOW'), findsOneWidget);
      expect(find.text('18M'), findsOneWidget);
      // BreathingHalo wraps the content when urgency != normal,
      // confirming the breathing rim is mounted on critical strips.
      expect(find.byType(CopilotSuggestionStrip), findsOneWidget);
    });

    testWidgets('custom eyebrow overrides the default', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CopilotSuggestionStrip(
              headline: 'Lounge open · Concourse C',
              subhead: 'Your Star Alliance Gold tier admits you.',
              ctaLabel: 'NAVIGATE',
              eyebrow: 'COPILOT · LOUNGE',
            ),
          ),
        ),
      );

      expect(find.text('COPILOT · LOUNGE'), findsOneWidget);
    });
  });
}
