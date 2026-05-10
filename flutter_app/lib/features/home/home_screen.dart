import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/identity_tier.dart';
import '../../domain/smart_suggestions.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/bible/bible.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/safe_boundary.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';
import '../wallet/wallet_fx_ticker.dart';
import '../wallet/wallet_provider.dart';
import 'flight_status_card.dart';
import 'home_mini_globe.dart';

/// Home — premium dashboard with greeting, identity-tier badge,
/// upcoming trip glance, wallet glance, and a quick-action grid.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(userProvider);
    final wallet = ref.watch(walletProvider);
    final lifecycle = ref.watch(lifecycleProvider);
    final score = ref.watch(scoreProvider);
    final theme = Theme.of(context);
    final greeting = _greeting();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(userProvider.notifier).hydrate(),
          ref.read(walletProvider.notifier).hydrate(),
          ref.read(lifecycleProvider.notifier).hydrate(),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Bible §9.2 — collapsing iOS-grade large title with the
          // global chrome embedded as right-side actions.
          BibleTopBar(
            title: 'Hi, ${user.profile.name.isEmpty ? 'Traveller' : user.profile.name.split(' ').first}',
            subtitle: greeting,
            actions: appChromeActions(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: score.when(
                data: (s) => _IdentityCard(
                        score: s.score,
                        tier: IdentityTier.forScore(s.score),
                        history: s.history)
                    .animate()
                    .fadeIn(
                        duration: AppTokens.durationMd,
                        curve: AppTokens.easeStandard)
                    .slideY(begin: 0.04, end: 0),
                loading: () => _IdentityCard.skeleton(),
                error: (_, __) => _IdentityCard(
                    score: user.profile.identityScore,
                    tier: IdentityTier.forScore(user.profile.identityScore),
                    history: const []),
              ),
            ),
          ),
          // ── System pulse strip (live state) ───────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space2,
              AppTokens.space5,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: SafeBoundary(
                debugLabel: 'home.pulse_strip',
                child: PremiumPulseStrip(
                  pulses: [
                    PulseTile(
                      label: 'Identity',
                      value: '${user.profile.identityScore}',
                      tone: theme.colorScheme.primary,
                      icon: Icons.verified_user_rounded,
                    ),
                    PulseTile(
                      label: 'Wallet',
                      value: wallet.balances.isEmpty
                          ? '—'
                          : '${wallet.balances.length} ccy',
                      tone: const Color(0xFF10B981),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    PulseTile(
                      label: 'Trips',
                      value: '${lifecycle.trips.length}',
                      tone: const Color(0xFFD97706),
                      icon: Icons.flight_takeoff_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Smart suggestions ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: _SmartSuggestionsStrip(
                suggestions: generateSuggestions(
                  identityScore: user.profile.identityScore,
                  tripCount: lifecycle.trips.length,
                  documentCount: user.documents.length,
                  walletBalanceCount: wallet.balances.length,
                  hasUpcomingTrip: lifecycle.trips.any(
                    (t) => t.stage == 'upcoming',
                  ),
                  nextTripDestination: lifecycle.trips.isNotEmpty
                      ? lifecycle.trips.first.legs.isNotEmpty
                          ? lifecycle.trips.first.legs.first.to
                          : null
                      : null,
                  daysUntilTrip: 7,
                  hour: DateTime.now().hour,
                ),
              ),
            ),
          ),
          // ── Flight status (when trip active) ──────────────────
          if (lifecycle.trips.any((t) => t.stage == 'active'))
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space5,
                vertical: AppTokens.space2,
              ),
              sliver: SliverToBoxAdapter(
                child: FlightStatusCard(
                  flightNumber: lifecycle.trips
                      .firstWhere((t) => t.stage == 'active')
                      .legs
                      .first
                      .flightNumber,
                  airline: 'GlobeAir',
                  from: lifecycle.trips
                      .firstWhere((t) => t.stage == 'active')
                      .legs
                      .first
                      .from,
                  to: lifecycle.trips
                      .firstWhere((t) => t.stage == 'active')
                      .legs
                      .first
                      .to,
                  departureTime: '14:30',
                  arrivalTime: '21:45',
                  gate: lifecycle.trips
                          .firstWhere((t) => t.stage == 'active')
                          .legs
                          .first
                          .gate ??
                      'B12',
                  status: FlightStatus.boarding,
                  progress: 0.0,
                  tripId:
                      lifecycle.trips.firstWhere((t) => t.stage == 'active').id,
                  legId: lifecycle.trips
                      .firstWhere((t) => t.stage == 'active')
                      .legs
                      .first
                      .id,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Next trip',
              subtitle:
                  lifecycle.trips.isEmpty ? 'No trips yet — plan one' : null,
              action: lifecycle.trips.isNotEmpty ? 'See all' : null,
              onAction: () => context.push('/travel'),
            ),
          ),
          // ── Mini globe with next trip route ───────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: SafeBoundary(
                debugLabel: 'home.mini_globe',
                fallbackHeight: 170,
                child: HomeMiniGlobe(
                  height: 170,
                  fromLat: lifecycle.trips.isNotEmpty ? 40.6413 : null,
                  fromLng: lifecycle.trips.isNotEmpty ? -73.7781 : null,
                  toLat: lifecycle.trips.isNotEmpty ? 51.4700 : null,
                  toLng: lifecycle.trips.isNotEmpty ? -0.4543 : null,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
          if (lifecycle.trips.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
              sliver: SliverToBoxAdapter(
                child: SafeBoundary(
                  debugLabel: 'home.trip_glance',
                  child: _TripGlance(
                    trip: lifecycle.trips.first,
                    onTap: () =>
                        context.push('/trip/${lifecycle.trips.first.id}'),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Wallet',
              subtitle: wallet.balances.isEmpty
                  ? 'Add a balance to see snapshots'
                  : '${wallet.balances.length} currencies',
              action: 'Open',
              onAction: () => context.push('/wallet'),
            ),
          ),
          // ── FX ticker ──────────────────────────────────────
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Exchange rates', dense: true),
          ),
          SliverToBoxAdapter(
            child: SafeBoundary(
              debugLabel: 'home.fx_ticker',
              child: WalletFxTicker(pairs: FxPair.demo()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space2)),
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Quick actions'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.space5, 0, AppTokens.space5, AppTokens.space9 + 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppTokens.space3,
              crossAxisSpacing: AppTokens.space3,
              childAspectRatio: 1.7,
              children: [
                _QuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan',
                  tone: theme.colorScheme.primary,
                  onTap: () => context.push('/scan'),
                ),
                _QuickAction(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Plan trip',
                  tone: const Color(0xFF7E22CE),
                  onTap: () => context.push('/planner'),
                ),
                _QuickAction(
                  icon: Icons.shield_moon_rounded,
                  label: 'Vault',
                  tone: const Color(0xFFEA580C),
                  onTap: () => context.push('/vault'),
                ),
                _QuickAction(
                  icon: Icons.smart_toy_rounded,
                  label: 'Copilot',
                  tone: const Color(0xFF059669),
                  onTap: () => context.push('/copilot'),
                ),
                _QuickAction(
                  icon: Icons.travel_explore_rounded,
                  label: 'Discover',
                  tone: const Color(0xFF06B6D4),
                  onTap: () => context.push('/discover'),
                ),
                _QuickAction(
                  icon: Icons.notifications_rounded,
                  label: 'Inbox',
                  tone: const Color(0xFFE11D48),
                  onTap: () => context.push('/inbox'),
                ),
                _QuickAction(
                  icon: Icons.hub_rounded,
                  label: 'Airport mode',
                  tone: const Color(0xFF2563EB),
                  onTap: () => context.push('/airport-mode'),
                ),
                _QuickAction(
                  icon: Icons.savings_rounded,
                  label: 'Trip wallet',
                  tone: const Color(0xFF0EA5E9),
                  onTap: () => context.push('/trip-wallet'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 22) return 'Good evening';
    return 'Late night';
  }
}


class _IdentityCard extends StatelessWidget {
  const _IdentityCard(
      {required this.score, required this.tier, required this.history});

  final int score;
  final IdentityTier tier;
  final List<int> history;

  static Widget skeleton() => GlassSurface(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = score / 100;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillChip(
                  label: tier.label, icon: Icons.workspace_premium_rounded),
              const Spacer(),
              Text(score.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    height: 1,
                  )),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text('/100',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.08),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          if (history.isNotEmpty) ...[
            Sparkline(
              values: history,
              color: theme.colorScheme.primary,
              height: 28,
            ),
            const SizedBox(height: AppTokens.space3),
          ],
          Text('Identity score — verified factors compound over time',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TripGlance extends StatelessWidget {
  const _TripGlance({required this.trip, required this.onTap});
  final dynamic trip; // TripLifecycle
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstLeg = (trip.legs as List).isNotEmpty ? trip.legs.first : null;
    // No Hero here — Travel page owns `trip-${id}` as the source for the
    // shared-element transition into TripDetail. If Home also had a Hero
    // with the same tag, switching tabs Home ↔ Travel would briefly stage
    // two heroes with identical tags and trip the framework's
    // "dependent is not a descendant" assertion during the transition.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: GlassSurface(
          radius: AppTokens.radius2xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PillChip(
                    label: trip.stage.toUpperCase() as String,
                    icon: Icons.flight_takeoff_rounded,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              Text(
                trip.name as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              if (firstLeg != null) ...[
                const SizedBox(height: AppTokens.space2),
                Row(
                  children: [
                    _AirportTile(code: firstLeg.from as String),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTokens.space3),
                      child: Icon(Icons.arrow_right_alt_rounded),
                    ),
                    _AirportTile(code: firstLeg.to as String),
                    const Spacer(),
                    Text(firstLeg.flightNumber as String,
                        style: theme.textTheme.titleSmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AirportTile extends StatelessWidget {
  const _AirportTile({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3, vertical: AppTokens.space2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Text(code,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            border: Border.all(color: tone.withValues(alpha: 0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tone.withValues(alpha: 0.18),
                tone.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: Icon(icon, color: tone),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling smart suggestions band with glowing pills.
class _SmartSuggestionsStrip extends StatelessWidget {
  const _SmartSuggestionsStrip({required this.suggestions});
  final List<SmartSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.65)),
              const SizedBox(width: 6),
              Text(
                'Suggested for you',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = suggestions[i];
              return GestureDetector(
                onTap: () {
                  GoRouter.of(context).push(s.route);
                },
                child: AnimatedContainer(
                  duration: AppTokens.durationSm,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: LinearGradient(
                      colors: [
                        s.tone.withValues(alpha: 0.18),
                        s.tone.withValues(alpha: 0.06),
                      ],
                    ),
                    border: Border.all(
                      color: s.tone.withValues(alpha: 0.30),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: s.tone.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 14, color: s.tone),
                      const SizedBox(width: 6),
                      Text(
                        s.title,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: s.tone,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
