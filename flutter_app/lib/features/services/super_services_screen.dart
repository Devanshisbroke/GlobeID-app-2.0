import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../data/models/travel_score.dart';
import '../../domain/currency_engine.dart';
import '../../domain/service_engine.dart';
import '../../domain/visa_requirements.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../motion/haptic_refresh.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';
import '../wallet/wallet_provider.dart';

enum _SuperPanel {
  overview,
  score,
  fraud,
  safety,
  budget,
  exchange,
  visa,
  insurance,
  esim,
  weather,
  local,
}

class SuperServicesScreen extends ConsumerStatefulWidget {
  const SuperServicesScreen({super.key});

  @override
  ConsumerState<SuperServicesScreen> createState() =>
      _SuperServicesScreenState();
}

class _SuperServicesScreenState extends ConsumerState<SuperServicesScreen> {
  _SuperPanel _active = _SuperPanel.overview;
  late final TextEditingController _citizenshipController =
      TextEditingController(text: 'IN');
  late final TextEditingController _destinationController =
      TextEditingController(text: 'AE');

  @override
  void dispose() {
    _citizenshipController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await Future.wait<void>([
      ref.read(walletProvider.notifier).hydrate(),
      ref.read(lifecycleProvider.notifier).hydrate(),
      ref.read(userProvider.notifier).hydrate(),
      ref.refresh(scoreProvider.future),
    ]);
  }

  void _activate(_SuperPanel panel) {
    HapticFeedback.selectionClick();
    setState(() => _active = panel);
  }

  void _handleServiceTap(ServiceTab tab) {
    switch (tab) {
      case ServiceTab.visa:
        _activate(_SuperPanel.visa);
      case ServiceTab.insurance:
        _activate(_SuperPanel.insurance);
      case ServiceTab.esim:
        _activate(_SuperPanel.esim);
      case ServiceTab.exchange:
        context.push('/multi-currency');
      case ServiceTab.hotels:
        context.push('/services/hotels');
      case ServiceTab.rides:
        context.push('/services/rides');
      case ServiceTab.food:
        context.push('/services/food');
      case ServiceTab.local:
        _activate(_SuperPanel.local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final lifecycle = ref.watch(lifecycleProvider);
    final user = ref.watch(userProvider);
    final score = ref.watch(scoreProvider);
    final nextTrip = nextActionableTrip(lifecycle.trips);
    final activeCountry = _countryFromProfile(user.profile.nationality) ??
        wallet.activeCountry ??
        'US';
    final destinationCountry = destinationCountryIso2ForTrip(nextTrip);
    final defaultCurrency = wallet.defaultCurrency;
    final destinationCurrency =
        destinationCurrencyForTrip(nextTrip) ?? defaultCurrency;
    final overBudgetCount = _overBudgetCategoryCount(wallet, nextTrip);
    final rankings = rankServices(ServiceInput(
      activeCountryIso2: activeCountry,
      nextDestinationIso2: destinationCountry,
      daysToNextTrip: daysUntilTrip(nextTrip),
      overBudgetCategoryCount: overBudgetCount,
    ));
    final readiness = _readinessIndex(
      wallet: wallet,
      nextTrip: nextTrip,
      score: score.valueOrNull,
      overBudgetCount: overBudgetCount,
    );

    return PageScaffold(
      title: 'Super Services',
      subtitle: 'Predictive travel, money, safety and identity hub',
      body: HapticRefresh(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppTokens.space9),
          children: [
            AnimatedAppearance(
              child: _CommandHero(
                readiness: readiness,
                nextTrip: nextTrip,
                activeCountry: activeCountry,
                destinationCountry: destinationCountry,
                destinationCurrency: destinationCurrency,
                walletTotal: _walletTotal(wallet),
              ),
            ),
            AnimatedAppearance(
              delay: const Duration(milliseconds: 90),
              child: _RankedServiceRail(
                rankings: rankings,
                onTap: _handleServiceTap,
              ),
            ),
            const SectionHeader(title: 'Control layer', dense: true),
            AnimatedAppearance(
              delay: const Duration(milliseconds: 140),
              child: _PanelSelector(
                active: _active,
                onSelect: _activate,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            AnimatedSwitcher(
              duration: AppTokens.durationMd,
              switchInCurve: AppTokens.easeOutSoft,
              switchOutCurve: AppTokens.easeInSoft,
              child: KeyedSubtree(
                key: ValueKey(_active),
                child: _panelFor(
                  panel: _active,
                  wallet: wallet,
                  lifecycle: lifecycle,
                  score: score,
                  nextTrip: nextTrip,
                  activeCountry: activeCountry,
                  destinationCountry: destinationCountry,
                  destinationCurrency: destinationCurrency,
                  readiness: readiness,
                  rankings: rankings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelFor({
    required _SuperPanel panel,
    required WalletStateView wallet,
    required LifecycleState lifecycle,
    required AsyncValue<TravelScore> score,
    required TripLifecycle? nextTrip,
    required String activeCountry,
    required String? destinationCountry,
    required String destinationCurrency,
    required int readiness,
    required List<ServiceRanking> rankings,
  }) {
    switch (panel) {
      case _SuperPanel.overview:
        return _OverviewPanel(
          readiness: readiness,
          wallet: wallet,
          nextTrip: nextTrip,
          rankings: rankings,
          onServiceTap: _handleServiceTap,
        );
      case _SuperPanel.score:
        return _ScorePanel(score: score);
      case _SuperPanel.fraud:
        return _FraudPanel(wallet: wallet);
      case _SuperPanel.safety:
        return _SafetyPanel(
          nextTrip: nextTrip,
          destinationCountry: destinationCountry,
        );
      case _SuperPanel.budget:
        return _BudgetPanel(wallet: wallet, nextTrip: nextTrip);
      case _SuperPanel.exchange:
        return _ExchangePanel(
          fromCurrency: wallet.defaultCurrency,
          toCurrency: destinationCurrency,
        );
      case _SuperPanel.visa:
        return _VisaPanel(
          citizenshipController: _citizenshipController,
          destinationController: _destinationController,
          onChanged: () => setState(() {}),
        );
      case _SuperPanel.insurance:
        return _InsurancePanel(nextTrip: nextTrip, readiness: readiness);
      case _SuperPanel.esim:
        return _EsimPanel(
          destinationCountry: destinationCountry ?? activeCountry,
        );
      case _SuperPanel.weather:
        return _WeatherPanel(nextTrip: nextTrip);
      case _SuperPanel.local:
        return _LocalPanel(country: destinationCountry ?? activeCountry);
    }
  }
}

class _CommandHero extends StatelessWidget {
  const _CommandHero({
    required this.readiness,
    required this.nextTrip,
    required this.activeCountry,
    required this.destinationCountry,
    required this.destinationCurrency,
    required this.walletTotal,
  });

  final int readiness;
  final TripLifecycle? nextTrip;
  final String activeCountry;
  final String? destinationCountry;
  final String destinationCurrency;
  final double walletTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = readiness >= 80
        ? const Color(0xFF10B981)
        : readiness >= 60
            ? const Color(0xFF0EA5E9)
            : const Color(0xFFF59E0B);

    return PremiumCard.hero(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tone.withValues(alpha: 0.92),
          const Color(0xFF111827),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LivePulse(),
              const SizedBox(width: 8),
              Text(
                'LIVE SERVICE GRAPH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _HeroBadge(label: destinationCurrency),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: readiness / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '$readiness',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextTrip?.name ?? 'No active itinerary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _heroSubtitle(
                        activeCountry: activeCountry,
                        destinationCountry: destinationCountry,
                        walletTotal: walletTotal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _heroSubtitle({
    required String activeCountry,
    required String? destinationCountry,
    required double walletTotal,
  }) {
    final route = destinationCountry == null
        ? activeCountry
        : '$activeCountry to $destinationCountry';
    final cash = CurrencyEngine.format(walletTotal, 'USD', decimals: 0);
    return '$route service layer online. Wallet runway: $cash equivalent.';
  }
}

class _RankedServiceRail extends StatelessWidget {
  const _RankedServiceRail({
    required this.rankings,
    required this.onTap,
  });

  final List<ServiceRanking> rankings;
  final ValueChanged<ServiceTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space4),
      child: SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: math.min(6, rankings.length),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, index) {
            final ranking = rankings[index];
            return _RankCard(
              ranking: ranking,
              index: index,
              onTap: () => onTap(ranking.tab),
            );
          },
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.ranking,
    required this.index,
    required this.onTap,
  });

  final ServiceRanking ranking;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _tabSpec(ranking.tab);
    return SizedBox(
      width: 232,
      child: Pressable(
        onTap: onTap,
        child: PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space4),
          glass: false,
          elevation: PremiumElevation.sm,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              spec.color.withValues(alpha: 0.22),
              spec.color.withValues(alpha: 0.05),
            ],
          ),
          borderColor: spec.color.withValues(alpha: 0.24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: spec.color.withValues(alpha: 0.18),
                    ),
                    child: Icon(spec.icon, color: spec.color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    '#${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: spec.color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                ranking.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelSelector extends StatelessWidget {
  const _PanelSelector({
    required this.active,
    required this.onSelect,
  });

  final _SuperPanel active;
  final ValueChanged<_SuperPanel> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final panel in _SuperPanel.values)
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.space2),
              child: _PanelPill(
                panel: panel,
                active: active == panel,
                onTap: () => onSelect(panel),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelPill extends StatelessWidget {
  const _PanelPill({
    required this.panel,
    required this.active,
    required this.onTap,
  });

  final _SuperPanel panel;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _panelColor(panel);
    return Pressable(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: active
              ? tone.withValues(alpha: 0.18)
              : theme.colorScheme.surface.withValues(alpha: 0.56),
          border: Border.all(
            color: active
                ? tone.withValues(alpha: 0.55)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_panelIcon(panel), size: 15, color: active ? tone : null),
            const SizedBox(width: 6),
            Text(
              _panelLabel(panel),
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? tone : null,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.readiness,
    required this.wallet,
    required this.nextTrip,
    required this.rankings,
    required this.onServiceTap,
  });

  final int readiness;
  final WalletStateView wallet;
  final TripLifecycle? nextTrip;
  final List<ServiceRanking> rankings;
  final ValueChanged<ServiceTab> onServiceTap;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      startDelayMs: 20,
      children: [
        _ReadinessChecklist(
          readiness: readiness,
          wallet: wallet,
          nextTrip: nextTrip,
        ),
        _SmartActionGrid(
          rankings: rankings,
          onTap: onServiceTap,
        ),
      ],
    );
  }
}

class _ReadinessChecklist extends StatelessWidget {
  const _ReadinessChecklist({
    required this.readiness,
    required this.wallet,
    required this.nextTrip,
  });

  final int readiness;
  final WalletStateView wallet;
  final TripLifecycle? nextTrip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checks = <_CheckItem>[
      _CheckItem(
        label: 'Identity signals',
        passed: readiness >= 70,
        detail: readiness >= 70 ? 'Strong trust posture' : 'Review vault',
      ),
      _CheckItem(
        label: 'Trip context',
        passed: nextTrip != null,
        detail: nextTrip?.name ?? 'No itinerary staged',
      ),
      _CheckItem(
        label: 'Wallet runway',
        passed: _walletTotal(wallet) > 250,
        detail: CurrencyEngine.format(_walletTotal(wallet), 'USD', decimals: 0),
      ),
      _CheckItem(
        label: 'Travel docs',
        passed: nextTrip?.legs.isNotEmpty ?? false,
        detail: nextTrip == null ? 'No legs detected' : 'Flights attached',
      ),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Readiness checklist',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$readiness%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          for (final check in checks) _CheckRow(check: check),
        ],
      ),
    );
  }
}

class _SmartActionGrid extends StatelessWidget {
  const _SmartActionGrid({
    required this.rankings,
    required this.onTap,
  });

  final List<ServiceRanking> rankings;
  final ValueChanged<ServiceTab> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.space2,
        crossAxisSpacing: AppTokens.space2,
        childAspectRatio: 1.34,
      ),
      itemCount: math.min(4, rankings.length),
      itemBuilder: (_, index) {
        final ranking = rankings[index];
        final spec = _tabSpec(ranking.tab);
        return Pressable(
          onTap: () => onTap(ranking.tab),
          child: PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space3),
            glass: false,
            elevation: PremiumElevation.sm,
            borderColor: spec.color.withValues(alpha: 0.20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(spec.icon, color: spec.color, size: 22),
                const Spacer(),
                Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Score ${ranking.score}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.58),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.score});
  final AsyncValue<TravelScore> score;

  @override
  Widget build(BuildContext context) {
    return score.when(
      loading: () => const _LoadingPanel(label: 'Loading score graph'),
      error: (e, _) => EmptyState(
        title: 'Score unavailable',
        message: e.toString(),
        icon: Icons.cloud_off_rounded,
      ),
      data: (snapshot) {
        final theme = Theme.of(context);
        return StaggeredColumn(
          children: [
            PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.24),
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: snapshot.score.clamp(0, 1000) / 1000,
                          strokeWidth: 7,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            '${snapshot.score}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trust tier ${snapshot.tier + 1}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Government-grade identity, travel history and payment reliability compressed into one signal.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.62),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final factor in snapshot.factors)
              _ProgressMetric(
                label: factor.label,
                value: factor.value,
                detail: 'Weight ${(factor.weight * 100).round()}%',
                tone: theme.colorScheme.primary,
              ),
          ],
        );
      },
    );
  }
}

class _FraudPanel extends StatelessWidget {
  const _FraudPanel({required this.wallet});
  final WalletStateView wallet;

  @override
  Widget build(BuildContext context) {
    final findings = _fraudFindings(wallet);
    if (findings.isEmpty) {
      return const _PlainStatusPanel(
        icon: Icons.verified_user_rounded,
        title: 'No anomalies detected',
        message:
            'Transactions are within your normal travel pattern. Card rails are monitored for location, velocity and amount drift.',
      );
    }
    return StaggeredColumn(
      children: [
        for (final finding in findings)
          _FindingCard(
            title: finding.title,
            message: finding.message,
            severity: finding.severity,
            icon: Icons.security_rounded,
          ),
      ],
    );
  }
}

class _SafetyPanel extends StatelessWidget {
  const _SafetyPanel({
    required this.nextTrip,
    required this.destinationCountry,
  });

  final TripLifecycle? nextTrip;
  final String? destinationCountry;

  @override
  Widget build(BuildContext context) {
    final country = destinationCountry ?? 'current region';
    final days = daysUntilTrip(nextTrip);
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.health_and_safety_rounded,
          title: 'Safety layer armed',
          message: days == 9999
              ? 'No upcoming trip found. Local safety actions remain available.'
              : 'Monitoring $country for airport, weather and document readiness signals.',
        ),
        _ActionList(
          actions: const [
            _ActionSpec(
              icon: Icons.local_police_rounded,
              title: 'Embassy channel',
              subtitle: 'Consular contacts and document recovery path staged.',
              color: Color(0xFF0EA5E9),
            ),
            _ActionSpec(
              icon: Icons.medical_services_rounded,
              title: 'Health card',
              subtitle: 'Insurance, allergies and emergency notes ready.',
              color: Color(0xFF10B981),
            ),
            _ActionSpec(
              icon: Icons.warning_amber_rounded,
              title: 'Risk sweep',
              subtitle: 'Crowd, transport and weather watchlist active.',
              color: Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
  }
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.wallet, required this.nextTrip});
  final WalletStateView wallet;
  final TripLifecycle? nextTrip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categorySpend(wallet);
    final total = categories.values.fold<double>(0, (a, b) => a + b);
    final budget = nextTrip?.budget ?? math.max(1200, total * 1.35);
    final used = total / math.max(1, budget);
    return StaggeredColumn(
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Trip budget runway',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(used * 100).clamp(0, 999).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: used > 1
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              _Bar(
                value: used.clamp(0, 1),
                color: used > 1
                    ? const Color(0xFFEF4444)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                '${CurrencyEngine.format(total, wallet.defaultCurrency)} of ${CurrencyEngine.format(budget, wallet.defaultCurrency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
        if (categories.isEmpty)
          const _PlainStatusPanel(
            icon: Icons.receipt_long_rounded,
            title: 'No spend yet',
            message:
                'Scan receipts or make wallet payments to build a budget graph.',
          )
        else
          PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              children: [
                for (final entry in _topCategories(categories))
                  _SpendRow(
                    label: entry.key,
                    amount: entry.value,
                    max: total,
                    currency: wallet.defaultCurrency,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExchangePanel extends StatelessWidget {
  const _ExchangePanel({
    required this.fromCurrency,
    required this.toCurrency,
  });

  final String fromCurrency;
  final String toCurrency;

  @override
  Widget build(BuildContext context) {
    final amounts = CurrencyEngine.quickAmounts(100).map((e) => e * 10);
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.currency_exchange_rounded,
          title: '$fromCurrency to $toCurrency',
          message:
              'Live wallet conversion preview using the deterministic rate engine.',
        ),
        for (final amount in amounts)
          _ConversionCard(
            amount: amount.toDouble(),
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
          ),
      ],
    );
  }
}

class _VisaPanel extends StatelessWidget {
  const _VisaPanel({
    required this.citizenshipController,
    required this.destinationController,
    required this.onChanged,
  });

  final TextEditingController citizenshipController;
  final TextEditingController destinationController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = visaSummary(
      citizenshipController.text.trim().isEmpty
          ? 'IN'
          : citizenshipController.text.trim(),
      destinationController.text.trim().isEmpty
          ? 'AE'
          : destinationController.text.trim(),
    );
    return StaggeredColumn(
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visa policy lookup',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              Row(
                children: [
                  Expanded(
                    child: _CodeField(
                      controller: citizenshipController,
                      label: 'Citizen',
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: _CodeField(
                      controller: destinationController,
                      label: 'Destination',
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _VisaResult(summary: summary),
      ],
    );
  }
}

class _InsurancePanel extends StatelessWidget {
  const _InsurancePanel({required this.nextTrip, required this.readiness});
  final TripLifecycle? nextTrip;
  final int readiness;

  @override
  Widget build(BuildContext context) {
    final days = daysUntilTrip(nextTrip);
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Coverage recommendation',
          message: days <= 30
              ? 'Trip is inside the quote window. Plans include disruption, medical and document recovery.'
              : 'No urgent quote needed. Keep an annual policy ready for spontaneous travel.',
        ),
        _PlanCard(
          name: 'Essential',
          price: 29,
          fit: readiness > 82 ? 'Good' : 'Basic',
          features: const ['Medical support', 'Lost bag assist', 'Delay cover'],
          color: const Color(0xFF0EA5E9),
        ),
        _PlanCard(
          name: 'Premium',
          price: 59,
          fit: 'Recommended',
          features: const [
            'Trip cancellation',
            'Priority doctor',
            'Passport recovery'
          ],
          color: const Color(0xFF10B981),
        ),
        _PlanCard(
          name: 'Frontier',
          price: 119,
          fit: 'High-risk routes',
          features: const [
            'Evacuation',
            'Satellite hotline',
            'Concierge claims'
          ],
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _EsimPanel extends StatelessWidget {
  const _EsimPanel({required this.destinationCountry});
  final String destinationCountry;

  @override
  Widget build(BuildContext context) {
    final currency = currencyForCountryIso2(destinationCountry) ?? 'USD';
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.sim_card_rounded,
          title: 'Data plans for $destinationCountry',
          message:
              'Install before departure. GlobeID keeps the QR and activation code in the vault.',
        ),
        _PlanCard(
          name: 'Landing',
          price: 8,
          fit: '3 GB / 7 days',
          features: ['Instant QR', 'Airport activation', currency],
          color: const Color(0xFF06B6D4),
        ),
        _PlanCard(
          name: 'Explorer',
          price: 18,
          fit: '10 GB / 30 days',
          features: ['5G where available', 'Hotspot', 'Top-up ready'],
          color: const Color(0xFF10B981),
        ),
        _PlanCard(
          name: 'Nomad',
          price: 34,
          fit: 'Regional / 30 days',
          features: ['Multi-country', 'Auto-switch', 'Priority support'],
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({required this.nextTrip});
  final TripLifecycle? nextTrip;

  @override
  Widget build(BuildContext context) {
    final code =
        nextTrip?.legs.isNotEmpty == true ? nextTrip!.legs.first.to : 'HOME';
    final seed = code.codeUnits.fold<int>(0, (a, b) => a + b);
    final temp = 18 + seed % 14;
    final wind = 8 + seed % 18;
    final rain = seed % 45;
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.wb_cloudy_rounded,
          title: 'Weather briefing for $code',
          message:
              'Deterministic trip forecast preview for packing, rides and delays.',
        ),
        _MetricGrid(
          metrics: [
            _MetricSpec('Temp', '$temp C', Icons.thermostat_rounded,
                const Color(0xFFEF4444)),
            _MetricSpec('Rain', '$rain%', Icons.water_drop_rounded,
                const Color(0xFF0EA5E9)),
            _MetricSpec('Wind', '$wind km/h', Icons.air_rounded,
                const Color(0xFF10B981)),
            _MetricSpec('Delay risk', '${math.min(72, rain + wind)}%',
                Icons.schedule_rounded, const Color(0xFFF59E0B)),
          ],
        ),
      ],
    );
  }
}

class _LocalPanel extends StatelessWidget {
  const _LocalPanel({required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      children: [
        _PlainStatusPanel(
          icon: Icons.location_city_rounded,
          title: '$country local layer',
          message:
              'Trusted services around you: consular help, cash points, pharmacies and transit.',
        ),
        _ActionList(
          actions: const [
            _ActionSpec(
              icon: Icons.account_balance_rounded,
              title: 'Consulate',
              subtitle: 'Nearest embassy and emergency document desk.',
              color: Color(0xFF0EA5E9),
            ),
            _ActionSpec(
              icon: Icons.local_atm_rounded,
              title: 'Cash and FX',
              subtitle: 'Low-fee ATMs and trusted exchange counters.',
              color: Color(0xFF10B981),
            ),
            _ActionSpec(
              icon: Icons.local_pharmacy_rounded,
              title: 'Pharmacy',
              subtitle: 'Open-now medication and travel clinic options.',
              color: Color(0xFFE11D48),
            ),
            _ActionSpec(
              icon: Icons.train_rounded,
              title: 'Transit',
              subtitle: 'Metro cards, airport trains and city passes.',
              color: Color(0xFF7C3AED),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckItem {
  const _CheckItem({
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String label;
  final bool passed;
  final String detail;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});
  final _CheckItem check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone =
        check.passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: Row(
        children: [
          Icon(
            check.passed ? Icons.check_circle_rounded : Icons.info_rounded,
            color: tone,
            size: 20,
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  check.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.tone,
  });

  final String label;
  final double value;
  final String detail;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Bar(value: value.clamp(0, 1), color: tone),
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
  });

  final String title;
  final String message;
  final String severity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tone = switch (severity) {
      'high' => const Color(0xFFEF4444),
      'medium' => const Color(0xFFF59E0B),
      _ => const Color(0xFF0EA5E9),
    };
    return _ActionSpecCard(
      spec: _ActionSpec(
        icon: icon,
        title: title,
        subtitle: message,
        color: tone,
      ),
      trailing: severity.toUpperCase(),
    );
  }
}

class _PlainStatusPanel extends StatelessWidget {
  const _PlainStatusPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.32),
                  theme.colorScheme.secondary.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions});
  final List<_ActionSpec> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: _ActionSpecCard(spec: action),
          ),
      ],
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _ActionSpecCard extends StatelessWidget {
  const _ActionSpecCard({
    required this.spec,
    this.trailing,
  });

  final _ActionSpec spec;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      glass: false,
      elevation: PremiumElevation.sm,
      borderColor: spec.color.withValues(alpha: 0.22),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              color: spec.color.withValues(alpha: 0.16),
            ),
            child: Icon(spec.icon, color: spec.color, size: 20),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  spec.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTokens.space2),
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: spec.color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpendRow extends StatelessWidget {
  const _SpendRow({
    required this.label,
    required this.amount,
    required this.max,
    required this.currency,
  });

  final String label;
  final double amount;
  final double max;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = max <= 0 ? 0.0 : (amount / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                CurrencyEngine.format(amount, currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(value: pct, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  final double amount;
  final String fromCurrency;
  final String toCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final converted = CurrencyEngine.convert(amount, fromCurrency, toCurrency);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              CurrencyEngine.format(amount, fromCurrency),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            CurrencyEngine.format(converted, toCurrency),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        final next = value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
        if (value != next) {
          controller.value = TextEditingValue(
            text: next.length > 2 ? next.substring(0, 2) : next,
            selection: TextSelection.collapsed(
              offset: math.min(2, next.length),
            ),
          );
        }
        onChanged();
      },
      textCapitalization: TextCapitalization.characters,
      maxLength: 2,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
      ),
    );
  }
}

class _VisaResult extends StatelessWidget {
  const _VisaResult({required this.summary});
  final VisaSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (summary.policy) {
      VisaPolicy.visaFree => const Color(0xFF10B981),
      VisaPolicy.eta => const Color(0xFF0EA5E9),
      VisaPolicy.voa => const Color(0xFF7C3AED),
      VisaPolicy.eVisa => const Color(0xFFF59E0B),
      VisaPolicy.embassy => const Color(0xFFEF4444),
    };
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      borderColor: tone.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: tone),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(
                  '${summary.citizenship} to ${summary.destination}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _visaKind(summary.policy),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            summary.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          for (final requirement in _visaRequirements(summary.policy))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_rounded, size: 15, color: tone),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      requirement,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.fit,
    required this.features,
    required this.color,
  });

  final String name;
  final int price;
  final String fit;
  final List<String> features;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      glass: false,
      elevation: PremiumElevation.sm,
      borderColor: color.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '\$$price',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            fit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final feature in features)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    feature,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<_MetricSpec> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.space2,
        crossAxisSpacing: AppTokens.space2,
        childAspectRatio: 1.45,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, index) => _MetricTile(spec: metrics[index]),
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.spec});
  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      glass: false,
      elevation: PremiumElevation.sm,
      borderColor: spec.color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(spec.icon, color: spec.color),
          const Spacer(),
          Text(
            spec.value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: spec.color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            spec.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: SizedBox(
        height: 7,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.55)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTokens.space3),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final alpha = 0.45 + 0.55 * _controller.value;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: alpha),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: alpha * 0.45),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabVisualSpec {
  const _TabVisualSpec(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

_TabVisualSpec _tabSpec(ServiceTab tab) {
  switch (tab) {
    case ServiceTab.visa:
      return const _TabVisualSpec(
        'Visa',
        Icons.assignment_ind_rounded,
        Color(0xFF7C3AED),
      );
    case ServiceTab.insurance:
      return const _TabVisualSpec(
        'Insurance',
        Icons.assignment_turned_in_rounded,
        Color(0xFF10B981),
      );
    case ServiceTab.esim:
      return const _TabVisualSpec(
        'eSIM',
        Icons.sim_card_rounded,
        Color(0xFF06B6D4),
      );
    case ServiceTab.exchange:
      return const _TabVisualSpec(
        'FX',
        Icons.currency_exchange_rounded,
        Color(0xFF059669),
      );
    case ServiceTab.hotels:
      return const _TabVisualSpec(
        'Hotels',
        Icons.hotel_rounded,
        Color(0xFF7C3AED),
      );
    case ServiceTab.rides:
      return const _TabVisualSpec(
        'Rides',
        Icons.local_taxi_rounded,
        Color(0xFFF59E0B),
      );
    case ServiceTab.food:
      return const _TabVisualSpec(
        'Food',
        Icons.restaurant_rounded,
        Color(0xFFE11D48),
      );
    case ServiceTab.local:
      return const _TabVisualSpec(
        'Local',
        Icons.location_city_rounded,
        Color(0xFF0EA5E9),
      );
  }
}

String _panelLabel(_SuperPanel panel) {
  switch (panel) {
    case _SuperPanel.overview:
      return 'Overview';
    case _SuperPanel.score:
      return 'Score';
    case _SuperPanel.fraud:
      return 'Fraud';
    case _SuperPanel.safety:
      return 'Safety';
    case _SuperPanel.budget:
      return 'Budget';
    case _SuperPanel.exchange:
      return 'FX';
    case _SuperPanel.visa:
      return 'Visa';
    case _SuperPanel.insurance:
      return 'Insurance';
    case _SuperPanel.esim:
      return 'eSIM';
    case _SuperPanel.weather:
      return 'Weather';
    case _SuperPanel.local:
      return 'Local';
  }
}

IconData _panelIcon(_SuperPanel panel) {
  switch (panel) {
    case _SuperPanel.overview:
      return Icons.dashboard_customize_rounded;
    case _SuperPanel.score:
      return Icons.verified_user_rounded;
    case _SuperPanel.fraud:
      return Icons.security_rounded;
    case _SuperPanel.safety:
      return Icons.health_and_safety_rounded;
    case _SuperPanel.budget:
      return Icons.savings_rounded;
    case _SuperPanel.exchange:
      return Icons.currency_exchange_rounded;
    case _SuperPanel.visa:
      return Icons.assignment_ind_rounded;
    case _SuperPanel.insurance:
      return Icons.assignment_turned_in_rounded;
    case _SuperPanel.esim:
      return Icons.sim_card_rounded;
    case _SuperPanel.weather:
      return Icons.wb_cloudy_rounded;
    case _SuperPanel.local:
      return Icons.location_city_rounded;
  }
}

Color _panelColor(_SuperPanel panel) {
  switch (panel) {
    case _SuperPanel.overview:
      return const Color(0xFF0EA5E9);
    case _SuperPanel.score:
      return const Color(0xFF7C3AED);
    case _SuperPanel.fraud:
      return const Color(0xFFEF4444);
    case _SuperPanel.safety:
      return const Color(0xFF10B981);
    case _SuperPanel.budget:
      return const Color(0xFFF59E0B);
    case _SuperPanel.exchange:
      return const Color(0xFF059669);
    case _SuperPanel.visa:
      return const Color(0xFF7C3AED);
    case _SuperPanel.insurance:
      return const Color(0xFF10B981);
    case _SuperPanel.esim:
      return const Color(0xFF06B6D4);
    case _SuperPanel.weather:
      return const Color(0xFF0EA5E9);
    case _SuperPanel.local:
      return const Color(0xFF4F46E5);
  }
}

int _readinessIndex({
  required WalletStateView wallet,
  required TripLifecycle? nextTrip,
  required TravelScore? score,
  required int overBudgetCount,
}) {
  var value = 42;
  if (nextTrip != null) value += 14;
  if (nextTrip?.legs.isNotEmpty ?? false) value += 8;
  if (_walletTotal(wallet) > 250) value += 12;
  if (_walletTotal(wallet) > 1000) value += 6;
  if ((score?.score ?? 0) > 650) value += 12;
  if ((score?.score ?? 0) > 820) value += 6;
  value -= overBudgetCount * 5;
  return value.clamp(0, 100);
}

double _walletTotal(WalletStateView wallet) {
  return wallet.balances.fold<double>(0, (sum, balance) {
    return sum +
        CurrencyEngine.convert(
          balance.amount,
          balance.currency,
          'USD',
        );
  });
}

Map<String, double> _categorySpend(WalletStateView wallet) {
  final categories = <String, double>{};
  for (final tx in wallet.transactions) {
    if (tx.type == 'receive' || tx.type == 'refund') continue;
    final category = tx.category.trim().isEmpty ? 'Other' : tx.category;
    categories[category] = (categories[category] ?? 0) +
        CurrencyEngine.convert(
          tx.amount.abs(),
          tx.currency,
          wallet.defaultCurrency,
        );
  }
  return categories;
}

List<MapEntry<String, double>> _topCategories(Map<String, double> categories) {
  final entries = categories.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(6).toList();
}

int _overBudgetCategoryCount(WalletStateView wallet, TripLifecycle? trip) {
  final categories = _categorySpend(wallet);
  if (categories.isEmpty) return 0;
  final budget = trip?.budget;
  if (budget == null || budget <= 0) return 0;
  final perCategory = budget / math.max(3, categories.length);
  return categories.values.where((value) => value > perCategory).length;
}

List<_FraudFinding> _fraudFindings(WalletStateView wallet) {
  final spends = wallet.transactions
      .where((tx) => tx.type != 'receive' && tx.type != 'refund')
      .toList();
  if (spends.length < 3) return const [];
  final amounts = spends.map((tx) => tx.amount.abs()).toList();
  final avg = amounts.fold<double>(0, (a, b) => a + b) / amounts.length;
  final findings = <_FraudFinding>[];
  for (final tx in spends.take(8)) {
    final amount = tx.amount.abs();
    if (avg > 0 && amount > avg * 2.25) {
      findings.add(_FraudFinding(
        title: tx.merchant ?? tx.description,
        message:
            '${CurrencyEngine.format(amount, tx.currency)} is above your travel baseline.',
        severity: 'high',
      ));
    } else if ((tx.country ?? '').isNotEmpty &&
        wallet.activeCountry != null &&
        tx.country != wallet.activeCountry) {
      findings.add(_FraudFinding(
        title: tx.merchant ?? tx.description,
        message: 'Cross-border transaction detected in ${tx.country}.',
        severity: 'medium',
      ));
    }
  }
  return findings.take(4).toList();
}

class _FraudFinding {
  const _FraudFinding({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final String severity;
}

String? _countryFromProfile(String nationality) {
  final n = nationality.trim().toLowerCase();
  if (n.isEmpty) return null;
  if (n.contains('india') || n == 'in') return 'IN';
  if (n.contains('united states') || n.contains('american') || n == 'us') {
    return 'US';
  }
  if (n.contains('brit') || n.contains('united kingdom') || n == 'gb') {
    return 'GB';
  }
  if (n.contains('singapore') || n == 'sg') return 'SG';
  if (n.contains('japan') || n == 'jp') return 'JP';
  if (n.contains('emirat') || n == 'ae') return 'AE';
  return null;
}

String _visaKind(VisaPolicy policy) {
  switch (policy) {
    case VisaPolicy.visaFree:
      return 'VISA FREE';
    case VisaPolicy.eta:
      return 'ETA';
    case VisaPolicy.voa:
      return 'VOA';
    case VisaPolicy.eVisa:
      return 'EVISA';
    case VisaPolicy.embassy:
      return 'EMBASSY';
  }
}

List<String> _visaRequirements(VisaPolicy policy) {
  switch (policy) {
    case VisaPolicy.visaFree:
      return const [
        'Passport valid for the whole stay.',
        'Return or onward ticket may be requested.',
      ];
    case VisaPolicy.eta:
      return const [
        'Online authorization before travel.',
        'Passport and airline itinerary required.',
      ];
    case VisaPolicy.voa:
      return const [
        'Visa issued on arrival at supported gates.',
        'Carry passport photo and proof of accommodation.',
      ];
    case VisaPolicy.eVisa:
      return const [
        'Apply online before departure.',
        'Upload passport scan, photo and itinerary.',
      ];
    case VisaPolicy.embassy:
      return const [
        'Consular appointment recommended.',
        'Prepare bank statement, itinerary and invitation documents.',
      ];
  }
}
