import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/identity_tier.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';

/// Identity screen — radial score ring, tier ladder, factor bars,
/// stagger reveal. Premium chrome on a deep canvas.
class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final score = ref.watch(scoreProvider);
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
          child: Text('Identity', style: theme.textTheme.headlineLarge),
        ),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 60),
          child: Text(
            'Verified factors compound over time. Higher tier unlocks better gates.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space5),
        score.when(
          data: (s) => AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: _IdentityHero(
              score: s.score,
              tier: IdentityTier.forScore(s.score),
              history: s.history,
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _IdentityHero(
            score: user.profile.identityScore,
            tier: IdentityTier.forScore(user.profile.identityScore),
            history: const [],
          ),
        ),
        const SectionHeader(title: 'Tier ladder', dense: true),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 200),
          child: const _TierLadder(),
        ),
        const SectionHeader(title: 'Documents'),
        if (user.documents.isEmpty)
          const EmptyState(
            title: 'No documents yet',
            message: 'Add your passport or visa to bump up your tier.',
            icon: Icons.badge_outlined,
          )
        else
          for (var i = 0; i < user.documents.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 280 + i * 50),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: _DocRow(
                  title: user.documents[i].label,
                  subtitle:
                      '${user.documents[i].country} · expires ${user.documents[i].expiryDate}',
                  trailing: user.documents[i].status,
                ),
              ),
            ),
        const SectionHeader(title: 'Verification factors'),
        score.when(
          data: (s) => Column(
            children: [
              for (var i = 0; i < s.factors.length; i++)
                AnimatedAppearance(
                  delay: Duration(milliseconds: 360 + i * 40),
                  child: _FactorRow(
                      label: s.factors[i].label, value: s.factors[i].value),
                ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppTokens.space5),
        FilledButton.icon(
          onPressed: () => context.push('/vault'),
          icon: const Icon(Icons.shield_moon_rounded),
          label: const Text('Open vault'),
        ),
      ],
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.score,
    required this.tier,
    required this.history,
  });
  final int score;
  final IdentityTier tier;
  final List<int> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.04),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(score: score, accent: accent),
              const SizedBox(width: AppTokens.space5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillChip(
                      label: tier.label,
                      icon: Icons.workspace_premium_rounded,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      'Identity score',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.6,
                      ),
                    ),
                    AnimatedNumber(
                      value: score.toDouble(),
                      decimals: 0,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                        height: 1,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (history.length > 2) ...[
            const SizedBox(height: AppTokens.space4),
            SizedBox(
              height: 56,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: accent,
                      barWidth: 2.4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: 0.32),
                            accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      spots: [
                        for (var i = 0; i < history.length; i++)
                          FlSpot(i.toDouble(), history[i].toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.accent});
  final int score;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score / 100).clamp(0, 1)),
      duration: AppTokens.durationXl,
      curve: AppTokens.easeOutSoft,
      builder: (_, v, __) {
        return SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _RingPainter(progress: v, color: accent),
            child: Center(
              child: Text(
                score.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 6;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.2), color],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _TierLadder extends StatelessWidget {
  const _TierLadder();
  @override
  Widget build(BuildContext context) {
    const tiers = [
      ('Citizen', 0, Icons.person_outline_rounded, Color(0xFF94A3B8)),
      ('Verified', 50, Icons.verified_user_outlined, Color(0xFF06B6D4)),
      ('Trusted', 70, Icons.shield_outlined, Color(0xFF7C3AED)),
      ('Elite', 90, Icons.workspace_premium_outlined, Color(0xFFF59E0B)),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final t in tiers)
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.$4.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.$3, color: t.$4, size: 22),
                ),
                const SizedBox(height: 6),
                Text(t.$1,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${t.$2}+',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    )),
              ],
            ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(
      {required this.title, required this.subtitle, required this.trailing});
  final String title;
  final String subtitle;
  final String trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Icon(Icons.badge_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          PillChip(label: trailing),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
              duration: AppTokens.durationLg,
              curve: AppTokens.easeOutSoft,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Text('${(value * 100).toInt()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
