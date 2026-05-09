import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import 'premium_service_card.dart';

/// Unified services hub. Sectioned by intent (Travel essentials, Money,
/// Identity, Lifestyle, Tools), each tile is a premium pressable card
/// with hero gradient, label and short description, no duplication.
/// All paths resolve to existing screens, so flows stay functional.
class ServicesHubScreen extends ConsumerStatefulWidget {
  const ServicesHubScreen({super.key});

  @override
  ConsumerState<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends ConsumerState<ServicesHubScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppTokens.space5,
        MediaQuery.of(context).padding.top + AppTokens.space5,
        // Right padding leaves room for the floating top-right theme
        // chrome rendered by AppShell.
        AppTokens.space5 + 48,
        AppTokens.space9 + 16,
      ),
      children: [
        AnimatedAppearance(
          child: Text('Services', style: theme.textTheme.headlineLarge),
        ),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 60),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Everything you need on the road, all in one place.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              const PremiumHud(label: 'LIVE', dense: true),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space5),

        // ── Featured hero card: live passport fast path ─────────
        AnimatedAppearance(
          delay: const Duration(milliseconds: 80),
          child: _FeaturedFastPath(),
        ),

        const SectionHeader(title: 'Featured', dense: true),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 100),
          child: SizedBox(
            height: 188,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
              children: [
                SizedBox(
                  width: 240,
                  child: PremiumServiceCard(
                    title: 'Hotels',
                    subtitle: 'Premium stays curated by Globe',
                    icon: Icons.hotel_rounded,
                    tone: const Color(0xFF8B5CF6),
                    tag: 'Concierge',
                    onTap: () => context.push('/services/hotels'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                SizedBox(
                  width: 240,
                  child: PremiumServiceCard(
                    title: 'eSIM',
                    subtitle: 'Connect in 30s · 200 countries',
                    icon: Icons.sim_card_rounded,
                    tone: const Color(0xFF10B981),
                    tag: 'New',
                    onTap: () => context.push('/esim'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                SizedBox(
                  width: 240,
                  child: PremiumServiceCard(
                    title: 'Lounges',
                    subtitle: 'Worldwide access via Globe Identity',
                    icon: Icons.weekend_rounded,
                    tone: const Color(0xFFF59E0B),
                    tag: 'Tier',
                    onTap: () => context.push('/lounge'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                SizedBox(
                  width: 240,
                  child: PremiumServiceCard(
                    title: 'Rides',
                    subtitle: 'Airport-to-door black car',
                    icon: Icons.directions_car_rounded,
                    tone: const Color(0xFFEC4899),
                    onTap: () => context.push('/services/rides'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                SizedBox(
                  width: 240,
                  child: PremiumServiceCard(
                    title: 'Concierge',
                    subtitle: 'Real human help, anywhere',
                    icon: Icons.support_agent_rounded,
                    tone: const Color(0xFF3B82F6),
                    onTap: () => context.push('/copilot'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SectionHeader(title: 'Travel essentials', dense: true),
        _ServicesGrid(
          startDelayMs: 80,
          tiles: const [
            _ServiceItem(
              name: 'Flights',
              path: '/services/flights',
              icon: Icons.flight_rounded,
              accent: AccentName.sky,
              description: 'Skyscanner-grade fare search',
            ),
            _ServiceItem(
              name: 'Hotels',
              path: '/services/hotels',
              icon: Icons.hotel_rounded,
              accent: AccentName.violet,
              description: 'Find a room near your itinerary',
            ),
            _ServiceItem(
              name: 'Rides',
              path: '/services/rides',
              icon: Icons.directions_car_rounded,
              accent: AccentName.amber,
              description: 'Airport transfers + city rides',
            ),
            _ServiceItem(
              name: 'Food',
              path: '/services/food',
              icon: Icons.restaurant_rounded,
              accent: AccentName.rose,
              description: 'Local restaurants + delivery',
            ),
            _ServiceItem(
              name: 'Activities',
              path: '/services/activities',
              icon: Icons.local_activity_rounded,
              accent: AccentName.emerald,
              description: 'Tours and tickets',
            ),
            _ServiceItem(
              name: 'Transport',
              path: '/services/transport',
              icon: Icons.train_rounded,
              accent: AccentName.sky,
              description: 'Trains, buses, ferries',
            ),
            _ServiceItem(
              name: 'Airport',
              path: '/airport',
              icon: Icons.local_airport_rounded,
              accent: AccentName.indigo,
              description: 'Boarding lobby & lounge map',
            ),
            _ServiceItem(
              name: 'Travel OS',
              path: '/travel-os',
              icon: Icons.hub_rounded,
              accent: AccentName.fuchsia,
              description: 'Agentic orchestration of trips',
            ),
            _ServiceItem(
              name: 'Live trip',
              path: '/services/rides/live',
              icon: Icons.timeline_rounded,
              accent: AccentName.amber,
              description: 'Premium live ride tracker',
            ),
            _ServiceItem(
              name: 'Arrival',
              path: '/arrival',
              icon: Icons.celebration_rounded,
              accent: AccentName.rose,
              description: 'Welcome flow for new countries',
            ),
            _ServiceItem(
              name: 'Cinematic globe',
              path: '/globe-cinematic',
              icon: Icons.public_rounded,
              accent: AccentName.cyan,
              description: 'Animated arcs · contextual cards',
            ),
            _ServiceItem(
              name: 'Sensors Lab',
              path: '/sensors-lab',
              icon: Icons.sensors_rounded,
              accent: AccentName.violet,
              description: 'Live device intelligence',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        const SectionHeader(title: 'Money', dense: true),
        _ServicesGrid(
          startDelayMs: 200,
          tiles: const [
            _ServiceItem(
              name: 'Wallet',
              path: '/wallet',
              icon: Icons.account_balance_wallet_rounded,
              accent: AccentName.cyan,
              description: 'Balances + recent transactions',
            ),
            _ServiceItem(
              name: 'Send',
              path: '/wallet/send',
              icon: Icons.arrow_upward_rounded,
              accent: AccentName.sky,
              description: 'Instant transfer to anyone',
            ),
            _ServiceItem(
              name: 'Receive',
              path: '/wallet/receive',
              icon: Icons.qr_code_2_rounded,
              accent: AccentName.emerald,
              description: 'Show code · auto-FX',
            ),
            _ServiceItem(
              name: 'Scan to pay',
              path: '/wallet/scan',
              icon: Icons.qr_code_scanner_rounded,
              accent: AccentName.fuchsia,
              description: 'Tap-and-go for kiosks',
            ),
            _ServiceItem(
              name: 'Exchange',
              path: '/wallet/exchange',
              icon: Icons.currency_exchange_rounded,
              accent: AccentName.amber,
              description: 'Live multi-currency conversion',
            ),
            _ServiceItem(
              name: 'Multi-currency',
              path: '/multi-currency',
              icon: Icons.public_rounded,
              accent: AccentName.emerald,
              description: 'Per-currency balances',
            ),
            _ServiceItem(
              name: 'Receipts',
              path: '/receipt',
              icon: Icons.receipt_long_rounded,
              accent: AccentName.amber,
              description: 'Scan + categorise spend',
            ),
            _ServiceItem(
              name: 'Analytics',
              path: '/analytics',
              icon: Icons.insights_rounded,
              accent: AccentName.indigo,
              description: 'Where your money flows',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        const SectionHeader(title: 'Identity', dense: true),
        _ServicesGrid(
          startDelayMs: 320,
          tiles: const [
            _ServiceItem(
              name: 'Vault',
              path: '/vault',
              icon: Icons.shield_moon_rounded,
              accent: AccentName.amber,
              description: 'Documents + secure storage',
            ),
            _ServiceItem(
              name: 'Identity',
              path: '/identity',
              icon: Icons.verified_user_rounded,
              accent: AccentName.violet,
              description: 'Score + verified factors',
            ),
            _ServiceItem(
              name: 'Loyalty',
              path: '/passport-book',
              icon: Icons.workspace_premium_rounded,
              accent: AccentName.fuchsia,
              description: 'Stamp book + status tier',
            ),
            _ServiceItem(
              name: 'Kiosk simulator',
              path: '/kiosk-sim',
              icon: Icons.qr_code_scanner_rounded,
              accent: AccentName.sky,
              description: 'Test how a gate sees your pass',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        const SectionHeader(title: 'Lifestyle', dense: true),
        _ServicesGrid(
          startDelayMs: 380,
          tiles: const [
            _ServiceItem(
              name: 'eSIM',
              path: '/esim',
              icon: Icons.sim_card_rounded,
              accent: AccentName.cyan,
              description: 'Data plans for 180+ countries',
            ),
            _ServiceItem(
              name: 'Lounges',
              path: '/lounge',
              icon: Icons.airline_seat_recline_extra_rounded,
              accent: AccentName.fuchsia,
              description: 'Airport lounge access',
            ),
            _ServiceItem(
              name: 'Phrasebook',
              path: '/phrasebook',
              icon: Icons.translate_rounded,
              accent: AccentName.rose,
              description: 'Adapted to your destination',
            ),
            _ServiceItem(
              name: 'Itinerary',
              path: '/itinerary',
              icon: Icons.event_note_rounded,
              accent: AccentName.indigo,
              description: 'Drag · drop · smart-fill',
            ),
            _ServiceItem(
              name: 'Emergency',
              path: '/emergency',
              icon: Icons.shield_rounded,
              accent: AccentName.rose,
              description: 'SOS · embassy · hotlines',
            ),
            _ServiceItem(
              name: 'Country profile',
              path: '/country',
              icon: Icons.public_rounded,
              accent: AccentName.violet,
              description: 'Etiquette · weather · FX',
            ),
            _ServiceItem(
              name: 'Packing list',
              path: '/packing',
              icon: Icons.luggage_rounded,
              accent: AccentName.violet,
              description: 'Smart-pack by destination',
            ),
            _ServiceItem(
              name: 'Customs form',
              path: '/customs',
              icon: Icons.assignment_rounded,
              accent: AccentName.indigo,
              description: 'Pre-fill arrival declaration',
            ),
            _ServiceItem(
              name: 'Trip journal',
              path: '/journal',
              icon: Icons.menu_book_rounded,
              accent: AccentName.cyan,
              description: 'Cinematic memory feed',
            ),
            _ServiceItem(
              name: 'Insurance',
              path: '/identity',
              icon: Icons.health_and_safety_rounded,
              accent: AccentName.emerald,
              description: 'Travel + medical coverage',
            ),
            _ServiceItem(
              name: 'Fraud center',
              path: '/audit-log',
              icon: Icons.gpp_maybe_rounded,
              accent: AccentName.rose,
              description: 'Disputes + suspicious activity',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        const SectionHeader(title: 'Tools', dense: true),
        _ServicesGrid(
          startDelayMs: 440,
          tiles: const [
            _ServiceItem(
              name: 'Plan trip',
              path: '/planner',
              icon: Icons.flight_takeoff_rounded,
              accent: AccentName.violet,
              description: 'Multi-leg itineraries',
            ),
            _ServiceItem(
              name: 'Copilot',
              path: '/copilot',
              icon: Icons.smart_toy_rounded,
              accent: AccentName.emerald,
              description: 'Ask anything about your trip',
            ),
            _ServiceItem(
              name: 'Explore',
              path: '/explore',
              icon: Icons.travel_explore_rounded,
              accent: AccentName.cyan,
              description: 'Cities + visa-free destinations',
            ),
            _ServiceItem(
              name: 'Timeline',
              path: '/timeline',
              icon: Icons.timeline_rounded,
              accent: AccentName.indigo,
              description: 'All travel events in one feed',
            ),
            _ServiceItem(
              name: 'Social',
              path: '/social',
              icon: Icons.people_alt_rounded,
              accent: AccentName.rose,
              description: 'Travelers near you',
            ),
            _ServiceItem(
              name: 'Feed',
              path: '/feed',
              icon: Icons.dynamic_feed_rounded,
              accent: AccentName.amber,
              description: 'Updates + community posts',
            ),
          ],
        ),
      ],
    );
  }
}

enum AccentName { violet, amber, rose, emerald, sky, cyan, indigo, fuchsia }

class _ServiceItem {
  const _ServiceItem({
    required this.name,
    required this.path,
    required this.icon,
    required this.accent,
    required this.description,
  });
  final String name;
  final String path;
  final IconData icon;
  final AccentName accent;
  final String description;
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.tiles, this.startDelayMs = 0});
  final List<_ServiceItem> tiles;
  final int startDelayMs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.space3,
        crossAxisSpacing: AppTokens.space3,
        childAspectRatio: 1.05,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => AnimatedAppearance(
        delay: Duration(milliseconds: startDelayMs + i * 50),
        child: _ServiceTile(svc: tiles[i]),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.svc});
  final _ServiceItem svc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _resolveAccent(theme, svc.accent);
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        GoRouter.of(context).push(svc.path);
      },
      child: PremiumCard(
        radius: AppTokens.radius2xl,
        glass: false,
        elevation: PremiumElevation.sm,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderColor: accent.withValues(alpha: 0.30),
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                boxShadow: AppTokens.shadowSm(tint: accent),
              ),
              child: Icon(svc.icon, color: accent, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  svc.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  svc.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveAccent(ThemeData theme, AccentName a) {
    switch (a) {
      case AccentName.violet:
        return const Color(0xFF7C3AED);
      case AccentName.amber:
        return const Color(0xFFF59E0B);
      case AccentName.rose:
        return const Color(0xFFE11D48);
      case AccentName.emerald:
        return const Color(0xFF10B981);
      case AccentName.sky:
        return const Color(0xFF0EA5E9);
      case AccentName.cyan:
        return const Color(0xFF06B6D4);
      case AccentName.indigo:
        return const Color(0xFF4F46E5);
      case AccentName.fuchsia:
        return const Color(0xFFD946EF);
    }
  }
}

/// Featured fast-path card — surfaces the live passport opening
/// experience right at the top of services so first-time users discover
/// the most cinematic system in the app immediately.
class _FeaturedFastPath extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF7C3AED);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space5),
      child: Pressable(
        scale: 0.99,
        onTap: () {
          HapticFeedback.mediumImpact();
          GoRouter.of(context).push('/passport-live');
        },
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C3AED),
                Color(0xFF06B6D4),
                Color(0xFF050912),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32)),
                ),
                child: const Icon(Icons.book_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                      child: const Text(
                        'FLAGSHIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open your live passport',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Holographic, NFC-grade, anti-counterfeit — the digital twin of your real passport.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
