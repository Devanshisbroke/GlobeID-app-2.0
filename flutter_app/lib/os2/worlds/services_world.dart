import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../os2_tokens.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Services world.
///
/// Concierge floor. Each service is a full-bleed vignette slab,
/// stacked vertically (not a 3-column grid). The user reads each
/// service as a deliberate offer, not a tile in a menu.
class ServicesWorld extends ConsumerWidget {
  const ServicesWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.services,
              title: 'Concierge',
              subtitle: 'Hand-curated service floor',
              beacon: 'READY',
            ),
            const SizedBox(height: Os2.space4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: [
                  _Vignette(
                    icon: Icons.bed_rounded,
                    label: 'STAY',
                    title: 'Hotels & residences',
                    body: 'Boutique stays, suites, and long-stay residences in 84 cities.',
                    route: '/services/hotels',
                    tone: Os2.servicesTone,
                  ),
                  _Vignette(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'FLY',
                    title: 'Flights & charters',
                    body: 'Premium economy through full charter \u00b7 Star Alliance + oneworld.',
                    route: '/services/flights',
                    tone: Os2.travelTone,
                  ),
                  _Vignette(
                    icon: Icons.local_taxi_rounded,
                    label: 'MOVE',
                    title: 'Ground mobility',
                    body: 'Premium rides, chauffeurs, helicopter transfers in 36 cities.',
                    route: '/services/rides',
                    tone: Os2.discoverTone,
                  ),
                  _Vignette(
                    icon: Icons.restaurant_rounded,
                    label: 'DINE',
                    title: 'Restaurants & reservations',
                    body: 'Same-day tables at Michelin and "impossible" reservations.',
                    route: '/services/food',
                    tone: Os2.pulseTone,
                  ),
                  _Vignette(
                    icon: Icons.event_rounded,
                    label: 'EXPERIENCE',
                    title: 'Activities & tickets',
                    body: 'Private tours, sold-out concerts, sports premium boxes.',
                    route: '/services/activities',
                    tone: Os2.identityTone,
                  ),
                  _Vignette(
                    icon: Icons.local_cafe_rounded,
                    label: 'LOUNGE',
                    title: 'Lounge access',
                    body: 'One-tap entry into 1,800 airport lounges worldwide.',
                    route: '/lounge',
                    tone: Os2.walletTone,
                  ),
                  _Vignette(
                    icon: Icons.sim_card_rounded,
                    label: 'CONNECT',
                    title: 'eSIM & data plans',
                    body: 'Country and region packs activate before you land.',
                    route: '/esim',
                    tone: Os2.discoverTone,
                  ),
                  _Vignette(
                    icon: Icons.health_and_safety_rounded,
                    label: 'SAFETY',
                    title: 'Emergency desk',
                    body: 'Tap-to-talk crisis support \u00b7 medical \u00b7 evacuation in 24/7 ops.',
                    route: '/emergency',
                    tone: Os2.identityTone,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.route,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String title;
  final String body;
  final String route;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Os2.space3),
      child: Os2Magnetic(
        onTap: () => GoRouter.of(context).push(route),
        child: Os2Slab(
          tone: tone,
          tier: Os2SlabTier.floor2,
          radius: Os2.rSlab,
          halo: Os2SlabHalo.edge,
          elevation: Os2SlabElevation.raised,
          padding: const EdgeInsets.all(Os2.space5),
          breath: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.40),
                    width: Os2.strokeFine,
                  ),
                ),
                child: Icon(icon, color: tone, size: 24),
              ),
              const SizedBox(width: Os2.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Os2Chip(
                      label: label,
                      tone: tone,
                      intensity: Os2ChipIntensity.solid,
                      size: Os2ChipSize.compact,
                    ),
                    const SizedBox(height: Os2.space2),
                    Os2Text.headline(
                      title,
                      color: Os2.inkBright,
                      size: 20,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Os2Text.body(
                      body,
                      color: Os2.inkMid,
                      size: 13,
                      maxLines: 3,
                    ),
                    const SizedBox(height: Os2.space3),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: tone),
                        const SizedBox(width: 4),
                        Os2Text.caption('OPEN', color: tone),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
