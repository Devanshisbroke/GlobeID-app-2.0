import 'package:flutter/material.dart';

import '../../cinematic/ambient/home_widget_preview.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// `/ambient/widgets` — gallery of GlobeID home-screen widgets.
///
/// Three widget designs rendered at their shipping iOS dimensions:
///   • Trip countdown   — systemSmall (158×158), gold-foil hero
///   • FX heartbeat     — systemSmall (158×158), sparkline + live tick
///   • Visa expiry      — systemMedium (338×158), urgency-tone strip
class HomeWidgetGalleryScreen extends StatelessWidget {
  const HomeWidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Widgets',
      subtitle: 'Home screen · GlobeID design',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _SectionEyebrow(label: 'SYSTEM · SMALL'),
          const SizedBox(height: Os2.space3),
          _PreviewWell(
            handle: 'TRIP · COUNTDOWN',
            description:
                'Foil-gold hero face. Days-until-departure in credential type scale, destination + date in mono-cap. Updates daily.',
            child: WidgetTileFrame(
              size: WidgetSize.small,
              child: TripCountdownWidget(
                destination: 'Tokyo',
                countryFlag: '🇯🇵',
                daysAway: 12,
                dateLabel: 'Nov 24',
              ),
            ),
          ),
          const SizedBox(height: Os2.space5),
          _PreviewWell(
            handle: 'FX · HEARTBEAT',
            description:
                'OLED face. Live rate in credential type scale, 5m sparkline with a gold-tick at the latest sample, delta-tone (emerald / crimson) on the % chip.',
            child: WidgetTileFrame(
              size: WidgetSize.small,
              child: FxHeartbeatWidget(
                pair: 'EUR/USD',
                rate: 1.0934,
                deltaPct: 0.72,
                spark: sparklineSamples(),
              ),
            ),
          ),
          const SizedBox(height: Os2.space6),
          _SectionEyebrow(label: 'SYSTEM · MEDIUM'),
          const SizedBox(height: Os2.space3),
          _PreviewWell(
            handle: 'VISA · EXPIRY',
            description:
                'OLED face. Flag tile tone-keyed to urgency (crimson < 14d, gold < 30d, signal-steel otherwise), days-remaining headline, expiry date in mono-cap.',
            child: WidgetTileFrame(
              size: WidgetSize.medium,
              child: VisaExpiryWidget(
                country: 'United States',
                countryFlag: '🇺🇸',
                expiryLabel: '14 Dec 2025',
                daysToExpiry: 21,
              ),
            ),
          ),
          const SizedBox(height: Os2.space6),
          _IntegrationCard(),
        ],
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Os2Text.monoCap(label, color: Os2.goldDeep, size: Os2.textTiny);
  }
}

class _PreviewWell extends StatelessWidget {
  const _PreviewWell({
    required this.handle,
    required this.description,
    required this.child,
  });
  final String handle;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                handle,
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'WIDGETKIT',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Center(child: child),
          const SizedBox(height: Os2.space3),
          Os2Text.body(description, color: Os2.inkMid, size: Os2.textSm),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'NATIVE · INTEGRATION',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'iOS — WidgetKit (`systemSmall` / `systemMedium`). Android — AppWidgetProvider with a `RemoteViews` layout that mirrors the same geometry. Refresh cadence: trip-countdown daily; fx-heartbeat 5 min foreground, 30 min background; visa-expiry daily.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
