import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/identity_tier.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';
import '../wallet/wallet_provider.dart';

/// Home — premium dashboard with greeting, identity-tier badge,
/// upcoming trip glance, wallet glance, and a quick-action grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTokens.space5,
              left: AppTokens.space5,
              right: AppTokens.space5,
              bottom: AppTokens.space3,
            ),
            sliver: SliverToBoxAdapter(
              child: _GreetingHeader(
                name: user.profile.name.isEmpty
                    ? 'Traveller'
                    : user.profile.name.split(' ').first,
                greeting: greeting,
                avatarUrl: user.profile.avatarUrl,
                onProfileTap: () => context.push('/profile'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
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
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Next trip',
              subtitle:
                  lifecycle.trips.isEmpty ? 'No trips yet — plan one' : null,
              action: lifecycle.trips.isNotEmpty ? 'See all' : null,
              onAction: () => context.push('/travel'),
            ),
          ),
          if (lifecycle.trips.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
              sliver: SliverToBoxAdapter(
                child: _TripGlance(
                  trip: lifecycle.trips.first,
                  onTap: () =>
                      context.push('/trip/${lifecycle.trips.first.id}'),
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: _WalletStrip(balances: wallet.balances),
            ),
          ),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.name,
    required this.avatarUrl,
    required this.onProfileTap,
  });

  final String greeting;
  final String name;
  final String avatarUrl;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  )),
              const SizedBox(height: 2),
              Text('Hi, $name',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 24,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.18),
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
        ),
      ],
    );
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

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({required this.balances});
  final List balances; // List<WalletBalance>
  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return GlassSurface(
        child: Row(
          children: const [
            Icon(Icons.account_balance_wallet_outlined),
            SizedBox(width: AppTokens.space3),
            Expanded(child: Text('Add a currency or scan a receipt to begin')),
          ],
        ),
      );
    }
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space3),
        itemBuilder: (_, i) => _BalanceTile(balance: balances[i]),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance});
  final dynamic balance;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(balance.flag as String,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppTokens.space2),
                Text(balance.currency as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${balance.symbol}${(balance.amount as double).toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
