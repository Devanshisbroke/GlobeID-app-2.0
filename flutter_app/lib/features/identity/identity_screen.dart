import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/travel_document.dart';
import '../../domain/audit_log.dart';
import '../../domain/identity_tier.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';
import 'identity_score_constellation.dart';
import 'identity_timeline.dart';
import 'passport_book_premium.dart';
import 'score_explainer_sheet.dart';
import 'tier_progression.dart';

/// Identity OS — the flagship hub for everything identity in GlobeID.
///
/// Surfaces every implemented identity system in one densely-layered
/// screen so users can reach passport-live, passport-book, vault,
/// scan, multi-currency, intelligence, audit log, and the security
/// center without ever opening the command palette.
class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        // ── Title row ────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AnimatedAppearance(
                child: Text('Identity', style: theme.textTheme.headlineLarge),
              ),
            ),
            AnimatedAppearance(
              delay: const Duration(milliseconds: 60),
              child: _IdentityChip(
                label: user.profile.verifiedStatus.toUpperCase(),
                accent: _statusAccent(user.profile.verifiedStatus, theme),
              ),
            ),
          ],
        ),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 80),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Your global identity layer — credentials, security, and trust signal in one place.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space5),

        // ── Hero: score + tier + delta ───────────────────────────
        score.when(
          data: (s) => AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: GestureDetector(
              onTap: () => ScoreExplainerSheet.show(context, s.score),
              child: _IdentityHero(
                score: s.score,
                tier: IdentityTier.forScore(s.score),
                history: s.history,
              ),
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => GestureDetector(
            onTap: () =>
                ScoreExplainerSheet.show(context, user.profile.identityScore),
            child: _IdentityHero(
              score: user.profile.identityScore,
              tier: IdentityTier.forScore(user.profile.identityScore),
              history: const [],
            ),
          ),
        ),

        // ── Premium identity surface (passport + constellation) ──
        const SectionHeader(title: 'Your identity'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 140),
          child: ContextualSurface(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space5,
              AppTokens.space5,
              AppTokens.space4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: PassportBookPremium(
                    country: user.profile.nationality.isEmpty
                        ? 'GLOBE'
                        : user.profile.nationality,
                    holderName: user.profile.name,
                    tier: IdentityTier.forScore(
                      _resolvedScore(score, user.profile),
                    ).label,
                    sealed:
                        user.profile.verifiedStatus.toLowerCase() == 'verified',
                    heroTag: 'identity-passport-${user.profile.userId}',
                  ),
                ),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  flex: 5,
                  child: IdentityScoreConstellation(
                    score: _resolvedScore(score, user.profile),
                    tier: IdentityTier.forScore(
                      _resolvedScore(score, user.profile),
                    ).label,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Travel readiness (visa / passport / verification) ────
        SectionHeader(
          title: 'Travel readiness',
          dense: true,
          action: 'Visa detail',
          onAction: () => context.push('/visa'),
        ),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 140),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            onTap: () => context.push('/visa'),
            child: ContextualSurface(
              child: Row(
                children: [
                  VisaReadinessRing(
                    percent: _readinessPercent(user, score),
                    label: 'Ready to fly',
                  ),
                  const SizedBox(width: AppTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Travel-doc readiness',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Passport sealed, identity score above tier '
                          'threshold, no expiring visas in 90 days.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Quick action grid: surfaces hidden systems ───────────
        const SectionHeader(title: 'Identity systems', dense: true),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 180),
          child: const _IdentitySystemsGrid(),
        ),

        // ── Credentials gallery (horizontal carousel) ────────────
        const SectionHeader(title: 'Credentials gallery'),
        if (user.documents.isEmpty)
          const EmptyState(
            title: 'No credentials yet',
            message: 'Add your passport or visa to bump up your tier.',
            icon: Icons.badge_outlined,
          )
        else
          AnimatedAppearance(
            delay: const Duration(milliseconds: 220),
            child: _CredentialsGallery(documents: user.documents),
          ),

        // ── Premium 3D credential stack ──────────────────────────
        const SectionHeader(title: 'Wallet of credentials', dense: true),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 240),
          child: CredentialGallery(
            cards: _credentialCards(user, score),
          ),
        ),

        // ── Tier ladder ──────────────────────────────────────────
        const SectionHeader(title: 'Tier ladder'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 260),
          child: _TierLadder(score: _resolvedScore(score, user.profile)),
        ),

        // ── Verification factors ─────────────────────────────────
        const SectionHeader(title: 'Verification factors'),
        score.when(
          data: (s) => Column(
            children: [
              for (var i = 0; i < s.factors.length; i++)
                AnimatedAppearance(
                  delay: Duration(milliseconds: 320 + i * 40),
                  child: _FactorRow(
                    label: s.factors[i].label,
                    value: s.factors[i].value,
                    weight: s.factors[i].weight,
                  ),
                ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Security center ──────────────────────────────────────
        const SectionHeader(title: 'Security center'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 480),
          child: const _SecurityCenter(),
        ),

        // ── Recent activity (audit log peek) ─────────────────────
        const SectionHeader(title: 'Recent activity'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 540),
          child: _AuditPeek(),
        ),

        const SizedBox(height: AppTokens.space5),

        // ── Enhanced tier progression ─────────────────────────────
        const SectionHeader(title: 'Tier progression'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 580),
          child: TierProgression(
            currentScore: _resolvedScore(score, user.profile),
            currentTier: _tierIndex(_resolvedScore(score, user.profile)),
          ),
        ),

        // ── Identity timeline ─────────────────────────────────────
        const SectionHeader(title: 'Activity timeline'),
        AnimatedAppearance(
          delay: const Duration(milliseconds: 640),
          child: IdentityTimeline(events: IdentityEvent.demo()),
        ),

        const SizedBox(height: AppTokens.space5),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/vault');
                },
                icon: const Icon(Icons.shield_moon_rounded),
                label: const Text('Open vault'),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/passport-live');
                },
                icon: const Icon(Icons.book_rounded),
                label: const Text('Live passport'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _tierIndex(int score) {
    if (score >= 95) return 4;
    if (score >= 75) return 3;
    if (score >= 50) return 2;
    if (score >= 25) return 1;
    return 0;
  }

  int _resolvedScore(AsyncValue<dynamic> async, dynamic profile) {
    return async.maybeWhen(
      data: (s) => (s as dynamic).score as int,
      orElse: () => (profile as dynamic).identityScore as int,
    );
  }

  /// Build deterministic premium credential cards for the 3D stack.
  /// Always returns the user's three highest-priority credentials
  /// (Passport · Identity · Boarding/E-SIM/Vault depending on
  /// availability).
  List<CredentialCardData> _credentialCards(
    dynamic user,
    AsyncValue<dynamic> score,
  ) {
    final profile = user.profile;
    final passportCode = (profile.passportNumber as String).isNotEmpty
        ? profile.passportNumber as String
        : 'PNL •••• ••••';
    final tier = IdentityTier.forScore(_resolvedScore(score, profile)).label;
    return [
      CredentialCardData(
        title: 'Passport',
        subtitle: profile.name as String,
        code: passportCode,
        tone: const Color(0xFF1D4ED8),
        icon: Icons.menu_book_rounded,
      ),
      CredentialCardData(
        title: 'Identity · $tier',
        subtitle: 'Score ${_resolvedScore(score, profile)} of 100',
        code: profile.userId as String,
        tone: const Color(0xFF7E22CE),
        icon: Icons.verified_user_rounded,
      ),
      const CredentialCardData(
        title: 'Vault',
        subtitle: 'Encrypted credentials',
        code: 'GID • LOCAL • OFFLINE',
        tone: Color(0xFF059669),
        icon: Icons.shield_moon_rounded,
      ),
      const CredentialCardData(
        title: 'Boarding',
        subtitle: 'Live boarding pass',
        code: 'TAP TO ACTIVATE',
        tone: Color(0xFFD97706),
        icon: Icons.airplane_ticket_rounded,
      ),
    ];
  }

  /// Compose a 0-1 readiness score from identity score + verified
  /// status + presence of a passport. Pure function, deterministic.
  double _readinessPercent(dynamic user, AsyncValue<dynamic> async) {
    final s = _resolvedScore(async, user.profile);
    final verified =
        (user.profile.verifiedStatus as String).toLowerCase() == 'verified';
    final hasPassport = (user.documents as Iterable)
        .any((d) => (d.type as String).toLowerCase() == 'passport');
    final base = (s.clamp(0, 100) / 100) * 0.7;
    final verifiedBonus = verified ? 0.18 : 0.0;
    final passportBonus = hasPassport ? 0.12 : 0.0;
    return (base + verifiedBonus + passportBonus).clamp(0.0, 1.0);
  }

  Color _statusAccent(String status, ThemeData theme) {
    switch (status) {
      case 'verified':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }
}

// ── Status / pill chip ─────────────────────────────────────────
class _IdentityChip extends StatelessWidget {
  const _IdentityChip({required this.label, required this.accent});
  final String label;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
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

  int _nextTierTarget() {
    if (score < 50) return 50;
    if (score < 70) return 70;
    if (score < 90) return 90;
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final next = _nextTierTarget();
    final remaining = (next - score).clamp(0, 100);

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
          const SizedBox(height: AppTokens.space4),
          // Delta-to-next-tier strip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remaining == 0
                        ? "You're at the top tier — keep flying."
                        : '$remaining points until next tier',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$score / $next',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (history.length > 2) ...[
            const SizedBox(height: AppTokens.space4),
            Text(
              'Score history',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
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
        return RepaintBoundary(
          child: SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              isComplex: true,
              willChange: true,
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

// ── Identity systems grid (the main expose-hidden-systems block) ─
class _IdentitySystemsGrid extends StatelessWidget {
  const _IdentitySystemsGrid();

  @override
  Widget build(BuildContext context) {
    final tiles = <_SystemTileData>[
      const _SystemTileData(
        label: 'Live passport',
        sub: 'Holographic, NFC-grade',
        icon: Icons.book_rounded,
        route: '/passport-live',
        accent: Color(0xFF7C3AED),
      ),
      const _SystemTileData(
        label: 'Passport book',
        sub: 'Stamps & history',
        icon: Icons.menu_book_rounded,
        route: '/passport-book',
        accent: Color(0xFF06B6D4),
      ),
      const _SystemTileData(
        label: 'Vault',
        sub: 'Sealed credentials',
        icon: Icons.shield_moon_rounded,
        route: '/vault',
        accent: Color(0xFF22C55E),
      ),
      const _SystemTileData(
        label: 'Scan',
        sub: 'MRZ + barcode',
        icon: Icons.qr_code_scanner_rounded,
        route: '/scan',
        accent: Color(0xFFF59E0B),
      ),
      const _SystemTileData(
        label: 'Multi-currency',
        sub: 'Live rates · convert',
        icon: Icons.currency_exchange_rounded,
        route: '/multi-currency',
        accent: Color(0xFFEC4899),
      ),
      const _SystemTileData(
        label: 'Intelligence',
        sub: 'Patterns & nudges',
        icon: Icons.insights_rounded,
        route: '/intelligence',
        accent: Color(0xFF3B82F6),
      ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (final t in tiles) _SystemTile(data: t),
      ],
    );
  }
}

class _SystemTileData {
  const _SystemTileData({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.accent,
  });
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final Color accent;
}

class _SystemTile extends StatefulWidget {
  const _SystemTile({required this.data});
  final _SystemTileData data;

  @override
  State<_SystemTile> createState() => _SystemTileState();
}

class _SystemTileState extends State<_SystemTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(widget.data.route);
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: AppTokens.easeOutSoft,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.data.accent.withValues(alpha: 0.20),
                widget.data.accent.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: widget.data.accent.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.data.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child:
                    Icon(widget.data.icon, color: widget.data.accent, size: 20),
              ),
              const SizedBox(height: AppTokens.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.data.sub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 10.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Credentials carousel ───────────────────────────────────────
class _CredentialsGallery extends StatelessWidget {
  const _CredentialsGallery({required this.documents});
  final List<TravelDocument> documents;

  Color _accentFor(String type) {
    switch (type) {
      case 'passport':
        return const Color(0xFF7C3AED);
      case 'visa':
        return const Color(0xFF06B6D4);
      case 'boarding_pass':
        return const Color(0xFFF59E0B);
      case 'travel_insurance':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'passport':
        return Icons.book_rounded;
      case 'visa':
        return Icons.verified_outlined;
      case 'boarding_pass':
        return Icons.airplane_ticket_rounded;
      case 'travel_insurance':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space3),
        itemBuilder: (context, i) {
          final d = documents[i];
          final accent = _accentFor(d.type);
          return _CredentialCard(
            doc: d,
            accent: accent,
            icon: _iconFor(d.type),
            onTap: () {
              HapticFeedback.selectionClick();
              if (d.type == 'passport') {
                context.push('/passport-live');
              } else if (d.type == 'boarding_pass' &&
                  d.tripId != null &&
                  d.legId != null) {
                context.push('/boarding/${d.tripId}/${d.legId}');
              } else if (d.tripId != null) {
                context.push('/trip/${d.tripId}');
              } else {
                context.push('/passport-book');
              }
            },
          );
        },
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.doc,
    required this.accent,
    required this.icon,
    required this.onTap,
  });
  final TravelDocument doc;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.30),
              accent.withValues(alpha: 0.08),
              const Color(0xFF0B0F1F),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Faint diagonal hologram sheen
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                child: CustomPaint(
                  painter: _HoloSheenPainter(accent: accent),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.22),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doc.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(doc.countryFlag, style: const TextStyle(fontSize: 22)),
                  ],
                ),
                const Spacer(),
                Text(
                  doc.number,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      doc.country.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                      child: Text(
                        doc.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Expires ${doc.expiryDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoloSheenPainter extends CustomPainter {
  _HoloSheenPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          Colors.white.withValues(alpha: 0.10),
          accent.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.06),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _HoloSheenPainter old) => old.accent != accent;
}

// ── Tier ladder (now responsive to current score) ──────────────
class _TierLadder extends StatelessWidget {
  const _TierLadder({required this.score});
  final int score;
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
                AnimatedContainer(
                  duration: AppTokens.durationLg,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.$4.withValues(
                      alpha: score >= t.$2 ? 0.30 : 0.12,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.$4.withValues(
                        alpha: score >= t.$2 ? 0.65 : 0.18,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(t.$3, color: t.$4, size: 22),
                ),
                const SizedBox(height: 6),
                Text(t.$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          score >= t.$2 ? FontWeight.w800 : FontWeight.w600,
                    )),
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

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.value,
    required this.weight,
  });
  final String label;
  final double value;
  final double weight;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  'Weight ${(weight * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
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

// ── Security center ────────────────────────────────────────────
class _SecurityCenter extends StatelessWidget {
  const _SecurityCenter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_SecurityItem>[
      _SecurityItem(
        icon: Icons.fingerprint_rounded,
        title: 'Biometric unlock',
        sub: 'Face ID + passcode bound',
        accent: const Color(0xFF22C55E),
        ok: true,
        onTap: () => context.push('/lock'),
      ),
      _SecurityItem(
        icon: Icons.devices_rounded,
        title: 'Trusted devices',
        sub: '2 devices · last sync now',
        accent: const Color(0xFF3B82F6),
        ok: true,
        onTap: () => context.push('/audit-log'),
      ),
      _SecurityItem(
        icon: Icons.shield_outlined,
        title: 'Vault sealed',
        sub: 'Auto-lock after 60s idle',
        accent: const Color(0xFF7C3AED),
        ok: true,
        onTap: () => context.push('/vault'),
      ),
      _SecurityItem(
        icon: Icons.fact_check_outlined,
        title: 'Audit log',
        sub: 'Append-only ledger of access',
        accent: const Color(0xFFF59E0B),
        ok: true,
        onTap: () => context.push('/audit-log'),
      ),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SecurityRow(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _SecurityItem {
  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.sub,
    required this.accent,
    required this.ok,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String sub;
  final Color accent;
  final bool ok;
  final VoidCallback onTap;
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({required this.item});
  final _SecurityItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        item.onTap();
      },
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2, vertical: AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: Icon(item.icon, color: item.accent, size: 20),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.sub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              item.ok ? Icons.check_circle_rounded : Icons.error_outline,
              color:
                  item.ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audit peek (recent identity activity) ──────────────────────
class _AuditPeek extends StatelessWidget {
  Widget _row(BuildContext context, AuditEntry e) {
    final theme = Theme.of(context);
    final dt = DateTime.fromMillisecondsSinceEpoch(e.at);
    final icon = switch (e.kind) {
      'vault_open' => Icons.lock_open_rounded,
      'vault_lock' => Icons.lock_rounded,
      'biometric_pass' => Icons.fingerprint_rounded,
      'biometric_fail' => Icons.no_encryption_gmailerrorred_rounded,
      'currency_change' => Icons.currency_exchange_rounded,
      _ => Icons.bolt_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              '${e.subject} — ${e.detail}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _shortTime(dt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final entries = AuditLog.all().take(4).toList();
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return const PremiumCard(
        padding: EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 18),
            SizedBox(width: AppTokens.space3),
            Expanded(
              child: Text(
                'No activity yet — open the vault or scan a credential to start the trail.',
              ),
            ),
          ],
        ),
      );
    }
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Column(
        children: [
          for (final e in entries) _row(context, e),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/audit-log'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'Open full audit log',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
