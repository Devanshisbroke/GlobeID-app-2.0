import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/copilot/copilot_moment_strip.dart';
import '../../domain/identity_tier.dart';
import '../../features/copilot/copilot_hub_models.dart';
import '../../features/identity/identity_intel.dart';
import '../../features/user/user_provider.dart';
import '../../motion/haptic_refresh.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_meter.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Identity world.
///
/// "Foil sanctum" — the most jewel-like surface in the app. Hierarchy:
///   1. World header (Identity · GMT · LIVE).
///   2. Holographic passport hero (foil edge, document chip, photo
///      shimmer column on the right).
///   3. Score constellation (giant meter, tier ladder, "+12 this week").
///   4. Credential gallery — three full-bleed vertical slabs:
///        a. Passport (book number, country, expiry)
///        b. Trusted-traveler / KYC programs
///        c. Issuer cross-signs (verifiable claims count).
///   5. Audit timeline strip (last verification event).
class IdentityWorld extends ConsumerStatefulWidget {
  const IdentityWorld({super.key});

  @override
  ConsumerState<IdentityWorld> createState() => _IdentityWorldState();
}

class _IdentityWorldState extends ConsumerState<IdentityWorld> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final profile = user.profile;
    final tier = IdentityTier.forScore(profile.identityScore);
    final pct = (profile.identityScore / 1000).clamp(0.0, 1.0);
    // Derived identity intelligence from real user data (keys held,
    // attestations count, cross-sign source, trusted programs, most
    // recent verification event, streak, passport expiry, tier
    // ladder) — the legacy world hard-coded "12 keys / FRA T1 12 min
    // ago / 7 streak" regardless of who was looking. Inside-the-app,
    // deterministic, no network call.
    final intel = IdentityIntel.from(
      profile: profile,
      records: user.records,
    );

    return SafeArea(
      bottom: false,
      child: HapticRefresh(
        onRefresh: () => ref.read(userProvider.notifier).hydrate(),
        color: Os2.identityTone,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Os2WorldHeader(
              world: Os2World.identity,
              title: 'Identity',
              subtitle: 'Sovereign credentials \u00b7 foil sanctum',
              beacon: 'VERIFIED',
            ),
            const SizedBox(height: Os2.space3),
            // Copilot moment — identity-context AI suggestion (tier,
            // attestation, score, document renewal).
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Os2.space4),
              child: CopilotMomentStrip(
                contextKinds: {
                  CopilotHubKind.identity,
                  CopilotHubKind.travel,
                },
              ),
            ),
            const SizedBox(height: Os2.space4),
            // 1. Holographic passport hero.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _PassportHero(
                name: profile.name,
                passportNumber: profile.passportNumber,
                flag: profile.nationalityFlag,
                nationality: profile.nationality,
                verifiedStatus: profile.verifiedStatus,
                tierLabel: tier.label,
              ),
            ),
            const SizedBox(height: Os2.space4),
            // 1a. Quick info strip.
            Os2InfoStrip(
              entries: [
                Os2InfoEntry(
                  icon: Icons.workspace_premium_rounded,
                  label: 'TIER',
                  value: tier.label.toUpperCase(),
                  tone: Os2.identityTone,
                ),
                Os2InfoEntry(
                  icon: Icons.verified_rounded,
                  label: 'SCORE',
                  value: '${profile.identityScore} / 1000',
                  tone: Os2.identityTone,
                ),
                Os2InfoEntry(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'TRIPS',
                  value: '${user.records.length}',
                  tone: Os2.travelTone,
                  onTap: () => GoRouter.of(context).push('/trip-pipeline'),
                ),
                Os2InfoEntry(
                  icon: Icons.fingerprint_rounded,
                  label: 'KEYS',
                  value: '${intel.keysHeld}',
                  tone: Os2.identityTone,
                  onTap: () => GoRouter.of(context).push('/vault'),
                ),
                Os2InfoEntry(
                  icon: Icons.shield_rounded,
                  label: 'AUDITS',
                  value: 'CLEAR',
                  tone: Os2.signalSettled,
                  onTap: () => GoRouter.of(context).push('/audit-log'),
                ),
                Os2InfoEntry(
                  icon: Icons.dashboard_customize_rounded,
                  label: 'VAULT',
                  value: 'DASHBOARD',
                  tone: Os2.identityTone,
                  onTap: () =>
                      GoRouter.of(context).push('/vault/dashboard'),
                ),
                Os2InfoEntry(
                  icon: Icons.mark_email_unread_rounded,
                  label: 'INBOX',
                  value: 'SIGNALS',
                  tone: Os2.travelTone,
                  onTap: () => GoRouter.of(context).push('/inbox'),
                ),
                Os2InfoEntry(
                  icon: Icons.assignment_ind_rounded,
                  label: 'VISA',
                  value: 'SCOUT',
                  tone: Os2.signalLive,
                  onTap: () => GoRouter.of(context).push('/visa'),
                ),
              ],
            ),
            const SizedBox(height: Os2.space5),
            // 2. Score constellation.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _ScoreConstellation(
                score: profile.identityScore,
                pct: pct,
                tier: tier,
              ),
            ),
            const SizedBox(height: Os2.space4),
            // 2a. Tier ladder.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _TierLadder(score: profile.identityScore),
            ),
            const SizedBox(height: Os2.space5),
            // 3. Section heading.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: _SectionLabel(label: 'CREDENTIAL GALLERY'),
            ),
            const SizedBox(height: Os2.space3),
            // 4. Credential gallery — vertical full-bleed slabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: [
                  _CredentialSlab(
                    icon: Icons.menu_book_rounded,
                    label: 'PASSPORT BOOK',
                    title: profile.passportNumber.isEmpty
                        ? 'Republic of India'
                        : profile.passportNumber,
                    sub: '${profile.nationalityFlag}  ${profile.nationality} \u00b7 active',
                    tone: Os2.identityTone,
                    onTap: () =>
                        GoRouter.of(context).push('/passport-live'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.verified_user_rounded,
                    label: 'TRUSTED PROGRAMS',
                    title: 'Global Entry \u00b7 PreCheck \u00b7 TSA',
                    sub: intel.trustedProgramsPending > 0
                        ? '${intel.trustedPrograms} enrolled \u00b7 '
                            '${intel.trustedProgramsPending} pending renewal'
                        : '${intel.trustedPrograms} enrolled \u00b7 all current',
                    tone: Os2.identityTone,
                    onTap: () =>
                        GoRouter.of(context).push('/passport-live'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.fingerprint_rounded,
                    label: 'ISSUER CROSS-SIGNS',
                    title: '${intel.attestationsCount} verifiable claims',
                    sub: '${intel.crossSignSource} \u00b7 '
                        '+${math.max(0, intel.attestationsCount - 3)}',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push(
                      '/vault/issuance',
                      extra: <String, dynamic>{
                        'title': profile.passportNumber.isEmpty
                            ? '${profile.nationality} \u00b7 Passport'
                            : '${profile.passportNumber} \u00b7 Passport',
                        'subtitle': 'Bearer \u00b7 ${profile.name}',
                        'issuer': profile.nationality,
                        'blockHeight':
                            12148337 + intel.attestationsCount * 7,
                      },
                    ),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.shield_rounded,
                    label: 'AUDIT LOG',
                    title: 'Last verification \u00b7 '
                        '${intel.lastEventAgo} ago',
                    sub: '${intel.lastEventVenue} \u00b7 success',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push(
                      '/vault/audit/passport',
                      extra: <String, dynamic>{
                        'label': profile.passportNumber.isEmpty
                            ? 'Passport'
                            : profile.passportNumber,
                      },
                    ),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.fact_check_rounded,
                    label: 'ACCESS HISTORY',
                    title: 'System-wide verification log',
                    sub: 'Every issuer touch \u00b7 chronological',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/audit-log'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.menu_book_rounded,
                    label: 'PASSPORT BOOK \u00b7 OS2',
                    title: 'Open cinematic passport book',
                    sub: 'Foil pages \u00b7 stamps \u00b7 visas',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/os2/passport'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.verified_user_rounded,
                    label: 'TRUST HUB',
                    title: 'Cross-sign arcs \u00b7 posture meters',
                    sub: 'Audits \u00b7 sessions \u00b7 keys \u00b7 chain',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/os2/trust'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Os2.space5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: _SectionLabel(label: 'VERIFICATION TIMELINE'),
            ),
            const SizedBox(height: Os2.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _VerificationTimeline(intel: intel),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Tier ladder

class _TierLadder extends StatelessWidget {
  const _TierLadder({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final tiers = IdentityTier.tiers;
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'TIER LADDER',
            tone: Os2.identityTone,
            trailing: '$score / 1000',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              for (var i = 0; i < tiers.length; i++) ...[
                Expanded(
                  child: _TierRung(
                    tier: tiers[i],
                    isCurrent: i == _currentTierIndex,
                    isReached: i <= _currentTierIndex,
                  ),
                ),
                if (i < tiers.length - 1)
                  Container(
                    width: 18,
                    height: 1,
                    color: i < _currentTierIndex
                        ? Os2.identityTone.withValues(alpha: 0.6)
                        : Os2.hairline,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int get _currentTierIndex {
    final tiers = IdentityTier.tiers;
    var idx = 0;
    for (var i = 0; i < tiers.length; i++) {
      if (score >= tiers[i].threshold) idx = i;
    }
    return idx;
  }
}

class _TierRung extends StatelessWidget {
  const _TierRung({
    required this.tier,
    required this.isCurrent,
    required this.isReached,
  });

  final IdentityTier tier;
  final bool isCurrent;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final tone = isReached ? Os2.identityTone : Os2.inkLow;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Os2GlyphHalo(
          icon: isReached
              ? Icons.check_rounded
              : Icons.radio_button_unchecked_rounded,
          tone: tone,
          size: isCurrent ? 32 : 26,
          iconSize: isCurrent ? 16 : 13,
        ),
        const SizedBox(height: 4),
        Os2Text.monoCap(
          tier.label,
          color: isReached ? Os2.inkBright : Os2.inkLow,
          size: 9,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Verification timeline

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.intel});
  final IdentityIntel intel;

  @override
  Widget build(BuildContext context) {
    // Build the streak pip strip from the actual streak length. Last
    // pip is the currently-active verification (not yet settled).
    final pips = <Os2PipState>[
      for (var i = 0; i < intel.streakLength - 1; i++) Os2PipState.settled,
      Os2PipState.active,
    ];
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rCard,
      halo: Os2SlabHalo.none,
      elevation: Os2SlabElevation.flat,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2Ribbon(
            label: 'AUDIT',
            value: 'ALL CHECKS PASSING',
            tone: Os2.signalSettled,
            trailing: '${intel.lastEventAgo.toUpperCase()} AGO',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.identityTone,
            nodes: [
              Os2TimelineNode(
                title: intel.lastEventVenue,
                caption: intel.lastEventCaption,
                trailing: intel.lastEventAgo,
                state: Os2NodeState.settled,
              ),
              const Os2TimelineNode(
                title: 'Issuer cross-sign',
                caption: 'Aadhaar UID gateway · re-attested',
                trailing: '3d',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Trusted-traveler',
                caption: intel.trustedProgramsPending > 0
                    ? 'Renewal queued'
                    : 'All programs current',
                trailing:
                    intel.trustedProgramsPending > 0 ? 'SOON' : 'CURRENT',
                state: intel.trustedProgramsPending > 0
                    ? Os2NodeState.active
                    : Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Document refresh',
                caption: 'Passport expires ${intel.passportExpiryYear} '
                    '· ${intel.passportExpiryWindow}',
                trailing: '${intel.passportExpiryYear}',
                state: Os2NodeState.pending,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'VERIFICATION STREAK',
            tone: Os2.signalSettled,
            trailing: '${intel.streakLength} / ${intel.streakLength}',
            pips: pips,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 1,
          color: Os2.identityTone.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 8),
        Os2Text.caption(label, color: Os2.identityTone),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Holographic passport

class _PassportHero extends StatefulWidget {
  const _PassportHero({
    required this.name,
    required this.passportNumber,
    required this.flag,
    required this.nationality,
    required this.verifiedStatus,
    required this.tierLabel,
  });

  final String name;
  final String passportNumber;
  final String flag;
  final String nationality;
  final String verifiedStatus;
  final String tierLabel;

  @override
  State<_PassportHero> createState() => _PassportHeroState();
}

class _PassportHeroState extends State<_PassportHero>
    with TickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // Settle controller eases the tilt back to neutral when the user
  // releases the pan gesture. Matches the Wallet hero's "Apple Wallet
  // soft hand" feel — pan to tilt, release to settle.
  late final AnimationController _tiltSettle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  Offset _tiltTarget = Offset.zero;
  Offset _tiltCurrent = Offset.zero;
  Size _heroSize = Size.zero;

  void _onPan(DragUpdateDetails d, Size box) {
    if (box == Size.zero) return;
    final dx = ((d.localPosition.dx / box.width) - 0.5) * 2; // -1..1
    final dy = ((d.localPosition.dy / box.height) - 0.5) * 2; // -1..1
    // Cap at ±0.06 rad (~3.4°) — subtle, in-brand.
    setState(() {
      _tiltTarget = Offset(dx.clamp(-1.0, 1.0) * 0.06,
          -dy.clamp(-1.0, 1.0) * 0.06);
      _tiltCurrent = _tiltTarget;
    });
  }

  void _onPanEnd(_) {
    _tiltSettle
      ..stop()
      ..reset();
    final start = _tiltCurrent;
    _tiltSettle.addListener(() {
      final v = Curves.easeOutCubic.transform(_tiltSettle.value);
      setState(() {
        _tiltCurrent = Offset(
          start.dx * (1 - v),
          start.dy * (1 - v),
        );
      });
    });
    _tiltSettle.forward();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _tiltSettle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _heroSize = Size(constraints.maxWidth, 220);
        return GestureDetector(
          onPanUpdate: (d) => _onPan(d, _heroSize),
          onPanCancel: () => _onPanEnd(null),
          onPanEnd: _onPanEnd,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_tiltCurrent.dy)
              ..rotateY(_tiltCurrent.dx),
            child: Os2Magnetic(
              onTap: () => GoRouter.of(context).push('/passport-live'),
              child: Os2Slab(
        tone: Os2.identityTone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rHero,
        halo: Os2SlabHalo.full,
        elevation: Os2SlabElevation.cinematic,
        padding: EdgeInsets.zero,
        breath: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Os2.rHero),
          child: Stack(
            children: [
              // Shimmer sweep — wrapped in a RepaintBoundary so the
              // ticking foil layer never repaints the rest of the
              // hero slab. Critical for 120Hz feel on 6-8GB devices.
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _FoilShimmerPainter(
                            progress: _shimmer.value,
                            tone: Os2.identityTone,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Os2.space5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Os2Chip(
                          label: 'GLOBEID PASSPORT',
                          tone: Os2.identityTone,
                          icon: Icons.workspace_premium_rounded,
                          intensity: Os2ChipIntensity.solid,
                        ),
                        const Spacer(),
                        Os2Beacon(
                          label: widget.verifiedStatus.toUpperCase(),
                          tone: Os2.signalSettled,
                        ),
                      ],
                    ),
                    const SizedBox(height: Os2.space6),
                    Row(
                      children: [
                        Text(
                          widget.flag,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: Os2.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Os2Text.caption('BEARER',
                                  color: Os2.inkLow),
                              const SizedBox(height: 2),
                              Os2Text.headline(
                                widget.name,
                                color: Os2.inkBright,
                                size: 22,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Os2.space4),
                    Container(height: 0.6, color: Os2.hairline),
                    const SizedBox(height: Os2.space4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Os2Text.caption('PASSPORT NO',
                                  color: Os2.inkLow),
                              const SizedBox(height: 4),
                              Os2Solari(
                                text: widget.passportNumber.isEmpty
                                    ? 'GID0000'
                                    : widget.passportNumber,
                                tone: Os2.identityTone,
                                cellWidth: 18,
                                cellHeight: 26,
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Os2Text.caption('TIER', color: Os2.inkLow),
                            const SizedBox(height: 4),
                            Os2Text.title(
                              widget.tierLabel,
                              color: Os2.identityTone,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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

class _FoilShimmerPainter extends CustomPainter {
  _FoilShimmerPainter({required this.progress, required this.tone});
  final double progress;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.35;
    final start = -bandWidth + (size.width + bandWidth * 2) * progress;
    final rect = Rect.fromLTWH(start, 0, bandWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          tone.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.06),
          tone.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _FoilShimmerPainter old) =>
      old.progress != progress || old.tone != tone;
}

// ─────────────────────────────────────────────────────── Score constellation

class _ScoreConstellation extends StatelessWidget {
  const _ScoreConstellation({
    required this.score,
    required this.pct,
    required this.tier,
  });
  final int score;
  final double pct;
  final IdentityTier tier;

  @override
  Widget build(BuildContext context) {
    final nextThreshold = IdentityTier.tiers
        .firstWhere(
          (t) => t.threshold > score,
          orElse: () => IdentityTier.tiers.last,
        )
        .threshold;
    final ptsToNext = (nextThreshold - score).clamp(0, 1000);
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rSlab,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.raised,
      padding: const EdgeInsets.all(Os2.space5),
      breath: true,
      child: Row(
        children: [
          Os2Meter(
            value: pct,
            tone: Os2.identityTone,
            diameter: 140,
            strokeWidth: 6,
            ticks: const [0.5, 0.75, 0.9],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Text.display(
                  '$score',
                  color: Os2.inkBright,
                  size: 38,
                  weight: FontWeight.w900,
                ),
                Os2Text.caption('/1000', color: Os2.inkLow),
              ],
            ),
          ),
          const SizedBox(width: Os2.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Chip(
                  label: tier.label.toUpperCase(),
                  tone: Os2.identityTone,
                  icon: Icons.workspace_premium_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
                const SizedBox(height: Os2.space3),
                Os2Text.title(
                  'Trust score',
                  color: Os2.inkBright,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Os2Text.body(
                  '$ptsToNext pts to next tier',
                  color: Os2.inkMid,
                  size: 12,
                ),
                const SizedBox(height: Os2.space3),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 14, color: Os2.signalSettled),
                    const SizedBox(width: 4),
                    Os2Text.caption(
                      '+12 THIS WEEK',
                      color: Os2.signalSettled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Credential slab

class _CredentialSlab extends StatelessWidget {
  const _CredentialSlab({
    required this.icon,
    required this.label,
    required this.title,
    required this.sub,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final String sub;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: onTap,
      child: Os2Slab(
        tone: tone,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: Os2.space4,
        ),
        breath: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tone.withValues(alpha: 0.32),
                  width: Os2.strokeFine,
                ),
              ),
              child: Icon(icon, color: tone, size: 19),
            ),
            const SizedBox(width: Os2.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.caption(label, color: tone),
                  const SizedBox(height: 4),
                  Os2Text.title(
                    title,
                    color: Os2.inkBright,
                    size: 16,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.body(
                    sub,
                    color: Os2.inkMid,
                    size: 12,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Os2.inkLow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
