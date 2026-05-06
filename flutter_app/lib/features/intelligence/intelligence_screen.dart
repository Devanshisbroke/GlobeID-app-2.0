import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline.dart';
import '../insights/insights_provider.dart';

/// Intelligence v3 — flagship briefing HUD.
///
/// Replaces the v2 stat-grid layout with a cinematic, multi-section
/// dashboard: hero briefing card, contextual strip rail (location /
/// weather / FX / safety / visa), wallet-runway strip, predictive
/// next-trip pre-game, frequent-routes spark, alerts feed, and a
/// frequent destinations gallery. Every section reads from the
/// existing insights / context / alerts / recommendations providers
/// and renders via shared design-token primitives.
class IntelligenceScreen extends ConsumerWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(contextProvider);
    final travel = ref.watch(travelInsightsProvider);
    final wallet = ref.watch(walletInsightsProvider);
    final alerts = ref.watch(alertsProvider);
    final reco = ref.watch(recommendationsProvider);

    return PageScaffold(
      title: 'Intelligence',
      subtitle: 'Live deterministic briefing',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, AppTokens.space9),
        children: [
          AnimatedAppearance(
            child: _HeroBriefingCard(context: ctx),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 100),
            child: _ContextStripRail(context: ctx),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 160),
            child: _WalletRunwayStrip(wallet: wallet),
          ),
          const SectionHeader(title: 'Predictive next move', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 220),
            child: _PredictiveNextTripCard(travel: travel),
          ),
          const SectionHeader(title: 'Anomaly alerts', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 260),
            child: _AlertsFeed(alerts: alerts),
          ),
          const SectionHeader(title: 'Top routes', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 320),
            child: _TopRoutesPanel(travel: travel),
          ),
          const SectionHeader(title: 'Travel snapshot', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 380),
            child: _SnapshotGrid(travel: travel),
          ),
          const SectionHeader(title: 'Curated for you', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 440),
            child: _RecoStrip(reco: reco),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Hero briefing card
// ─────────────────────────────────────────────────────────────────

class _HeroBriefingCard extends StatelessWidget {
  const _HeroBriefingCard({required this.context});
  final AsyncValue<Map<String, dynamic>> context;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.36),
          theme.colorScheme.secondary.withValues(alpha: 0.12),
        ],
      ),
      child: context.when(
        loading: () => const SizedBox(
          height: 168,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _HeroBriefingFallback(message: '$e'),
        data: (m) {
          final location = (m['location'] ?? 'Unknown').toString();
          final localTime = (m['localTime'] ?? '—').toString();
          final nextLeg = (m['nextLeg'] ?? 'No upcoming legs').toString();
          final walletAlert = (m['walletAlert'] ?? '').toString();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE BRIEFING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  _HeroPill(label: localTime, icon: Icons.schedule_rounded),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              Text(
                location,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Row(
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nextLeg,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (walletAlert.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        walletAlert,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroBriefingFallback extends StatelessWidget {
  const _HeroBriefingFallback({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            'Briefing temporarily unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = 0.4 + 0.6 * Curves.easeInOut.transform(_ctrl.value);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEF4444).withValues(alpha: v),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5 * v),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Context strip — weather / FX / safety / visa quick chips
// ─────────────────────────────────────────────────────────────────

class _ContextStripRail extends StatelessWidget {
  const _ContextStripRail({required this.context});
  final AsyncValue<Map<String, dynamic>> context;

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: SizedBox(
        height: 72,
        child: context.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (m) {
            final chips = <_StripChip>[];
            void add(String v, IconData icon, Color tone, String label) {
              if (v.isEmpty) return;
              chips.add(_StripChip(
                label: label,
                value: v,
                icon: icon,
                tone: tone,
              ));
            }

            add(
              (m['weather'] ?? '').toString(),
              Icons.thermostat_rounded,
              const Color(0xFF06B6D4),
              'Weather',
            );
            add(
              (m['fxAlert'] ?? '').toString(),
              Icons.currency_exchange_rounded,
              const Color(0xFF10B981),
              'FX',
            );
            add(
              (m['safety'] ?? '').toString(),
              Icons.shield_rounded,
              const Color(0xFFF59E0B),
              'Safety',
            );
            add(
              (m['visa'] ?? '').toString(),
              Icons.credit_card_rounded,
              const Color(0xFF7C3AED),
              'Visa',
            );

            return ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.space1),
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => chips[i],
            );
          },
        ),
      ),
    );
  }
}

class _StripChip extends StatelessWidget {
  const _StripChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        gradient: LinearGradient(
          colors: [
            tone.withValues(alpha: 0.20),
            tone.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.28),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tone, tone.withValues(alpha: 0.6)],
              ),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
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

// ─────────────────────────────────────────────────────────────────
// Wallet runway strip — minimalist deterministic balance bar
// ─────────────────────────────────────────────────────────────────

class _WalletRunwayStrip extends StatelessWidget {
  const _WalletRunwayStrip({required this.wallet});
  final AsyncValue<Map<String, dynamic>> wallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: wallet.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 60,
            child: Center(
              child: Text('Wallet insights offline'),
            ),
          ),
          data: (m) {
            final spend = ((m['monthlySpend'] as num?) ?? 0).toDouble();
            final balance = ((m['balance'] as num?) ?? 0).toDouble();
            final runway = balance > 0 && spend > 0
                ? (balance / spend * 30).round()
                : 0;
            final pct = balance > 0 ? (spend * 12 / balance).clamp(0.0, 1.0) : 0.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WALLET RUNWAY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.62),
                      ),
                    ),
                    const Spacer(),
                    AnimatedNumber(
                      value: runway.toDouble(),
                      decimals: 0,
                      duration: AppTokens.durationLg,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.06),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monthly spend \$${spend.toStringAsFixed(0)} of'
                  ' \$${balance.toStringAsFixed(0)} balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Predictive next trip card
// ─────────────────────────────────────────────────────────────────

class _PredictiveNextTripCard extends StatelessWidget {
  const _PredictiveNextTripCard({required this.travel});
  final AsyncValue<Map<String, dynamic>> travel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return travel.when(
      loading: () => const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => EmptyState(
        title: 'Travel insights unavailable',
        message: e.toString(),
        icon: Icons.cloud_off_rounded,
      ),
      data: (m) {
        final routes =
            ((m['topRoutes'] as List?) ?? const []).cast<Map<String, dynamic>>();
        final top = routes.isNotEmpty ? routes.first : null;
        final from = (top?['from'] ?? 'JFK').toString();
        final to = (top?['to'] ?? 'LHR').toString();
        return PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space5),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1D4ED8).withValues(alpha: 0.32),
              const Color(0xFF06B6D4).withValues(alpha: 0.10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PREDICTED NEXT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _IataChip(code: from),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomPaint(
                        size: const Size(double.infinity, 24),
                        painter: _ArcPainter(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
                  _IataChip(code: to),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              Text(
                'Pattern detected: this is your most-flown route. We\'ll '
                'pre-fill the planner the next time you tap +.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IataChip extends StatelessWidget {
  const _IataChip({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 18,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width / 2,
        -size.height,
        size.width,
        size.height,
      );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color,
    );
    // Plane glyph at midpoint.
    final mid = Offset(size.width / 2, -size.height * 0.18);
    final plane = TextPainter(
      text: const TextSpan(
        text: '✈',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    plane.paint(canvas, mid - Offset(plane.width / 2, plane.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────
// Alerts feed
// ─────────────────────────────────────────────────────────────────

class _AlertsFeed extends StatelessWidget {
  const _AlertsFeed({required this.alerts});
  final AsyncValue<List<dynamic>> alerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return alerts.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: EmptyState(
          title: 'Alerts unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
      ),
      data: (raw) {
        final items = raw.cast<Map<String, dynamic>>();
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Text(
                'No alerts. All systems nominal.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space2),
                child: _AlertRow(data: items[i], index: i),
              ),
          ],
        );
      },
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.data, required this.index});
  final Map<String, dynamic> data;
  final int index;

  Color _toneFor(String severity) {
    switch (severity) {
      case 'critical':
      case 'high':
        return const Color(0xFFEF4444);
      case 'warning':
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'info':
      case 'low':
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _iconFor(String severity) {
    switch (severity) {
      case 'critical':
      case 'high':
        return Icons.error_rounded;
      case 'warning':
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'info':
      case 'low':
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = (data['severity'] ?? 'info').toString();
    final title = (data['title'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    final tone = _toneFor(severity);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tone.withValues(alpha: 0.36), tone.withValues(alpha: 0.10)],
              ),
              border: Border.all(color: tone.withValues(alpha: 0.32)),
            ),
            child: Icon(_iconFor(severity), color: tone, size: 18),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: tone.withValues(alpha: 0.16),
            ),
            child: Text(
              severity.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top routes panel — frequent flying patterns with sparkline
// ─────────────────────────────────────────────────────────────────

class _TopRoutesPanel extends StatelessWidget {
  const _TopRoutesPanel({required this.travel});
  final AsyncValue<Map<String, dynamic>> travel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return travel.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => EmptyState(
        title: 'Routes unavailable',
        message: e.toString(),
        icon: Icons.cloud_off_rounded,
      ),
      data: (m) {
        final routes =
            ((m['topRoutes'] as List?) ?? const []).cast<Map<String, dynamic>>();
        if (routes.isEmpty) {
          return PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Text(
              'Not enough flights yet to detect patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          );
        }
        final maxCount = routes
            .map((e) => (e['count'] as num?)?.toDouble() ?? 0)
            .fold<double>(0, math.max);
        return PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Column(
            children: [
              for (var i = 0; i < routes.length; i++)
                _TopRouteRow(
                  data: routes[i],
                  maxCount: maxCount,
                  index: i,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TopRouteRow extends StatelessWidget {
  const _TopRouteRow({
    required this.data,
    required this.maxCount,
    required this.index,
  });
  final Map<String, dynamic> data;
  final double maxCount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = (data['count'] as num?)?.toDouble() ?? 0;
    final pct = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                data['from']?.toString() ?? '—',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                data['to']?.toString() ?? '—',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${count.toInt()}×',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Snapshot grid + sparkline of distance
// ─────────────────────────────────────────────────────────────────

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.travel});
  final AsyncValue<Map<String, dynamic>> travel;

  @override
  Widget build(BuildContext context) {
    return travel.when(
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => EmptyState(
        title: 'Snapshot unavailable',
        message: e.toString(),
        icon: Icons.cloud_off_rounded,
      ),
      data: (m) {
        final distance = (m['totalDistance'] as num?) ?? 0;
        final countries = (m['countries'] as num?) ?? 0;
        final continents = (m['continents'] as num?) ?? 0;
        final flights = ((m['topRoutes'] as List?) ?? const [])
            .map((e) => (e as Map)['count'] as num? ?? 0)
            .fold<num>(0, (a, b) => a + b);
        final history = ((m['monthlyDistance'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList();
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.space2,
          crossAxisSpacing: AppTokens.space2,
          childAspectRatio: 1.65,
          children: [
            _SnapTile(
              label: 'Distance',
              value: '${(distance / 1000).round()}k',
              suffix: 'km',
              accent: const Color(0xFF06B6D4),
              spark: history.isEmpty ? null : history,
            ),
            _SnapTile(
              label: 'Countries',
              value: '$countries',
              suffix: 'visited',
              accent: const Color(0xFF7C3AED),
            ),
            _SnapTile(
              label: 'Continents',
              value: '$continents',
              suffix: 'of 7',
              accent: const Color(0xFF10B981),
            ),
            _SnapTile(
              label: 'Flights',
              value: '$flights',
              suffix: 'logged',
              accent: const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );
  }
}

class _SnapTile extends StatelessWidget {
  const _SnapTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.accent,
    this.spark,
  });
  final String label;
  final String value;
  final String suffix;
  final Color accent;
  final List<double>? spark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    suffix,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (spark != null && spark!.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: 76,
                height: 28,
                child: Sparkline(
                  values: spark!,
                  color: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recommendations strip — horizontal pop carousel
// ─────────────────────────────────────────────────────────────────

class _RecoStrip extends StatelessWidget {
  const _RecoStrip({required this.reco});
  final AsyncValue<Map<String, dynamic>> reco;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: reco.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (m) {
          final items = ((m['items'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()
              .take(8)
              .toList();
          if (items.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _RecoCard(data: items[i]),
          );
        },
      ),
    );
  }
}

class _RecoCard extends StatelessWidget {
  const _RecoCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flag = (data['flag'] ?? '🌍').toString();
    final title = (data['title'] ?? '').toString();
    final subtitle = (data['subtitle'] ?? '').toString();
    final kind = (data['kind'] ?? 'place').toString();
    return Container(
      width: 230,
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.20),
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  color: theme.colorScheme.primary.withValues(alpha: 0.16),
                ),
                child: Text(
                  kind.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
