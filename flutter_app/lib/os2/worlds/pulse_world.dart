import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/user/user_provider.dart';
import '../../features/wallet/wallet_provider.dart';
import '../../features/inbox/inbox_provider.dart';
import '../../features/score/score_provider.dart';
import '../../domain/identity_tier.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_meter.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Pulse world.
///
/// The "system is awake" screen. No card-list. No greeting card. The
/// hierarchy is:
///   1. World header (Mission Control: title, time, beacon)
///   2. Active leg slab (full-bleed, foil + solari boarding ribbon) OR
///      upcoming trip slab (typographic route + countdown)
///   3. Identity tier meter (orbiting halo, score numeral)
///   4. Wallet pulse strip (multi-currency floor)
///   5. Inbox pulse (unread count + last whisper)
///   6. Concierge handoff (jump to services world)
class PulseWorld extends ConsumerWidget {
  const PulseWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final wallet = ref.watch(walletProvider);
    final inboxUnread = ref.watch(inboxUnreadProvider);
    final scoreAsync = ref.watch(scoreProvider);

    final firstName = user.profile.name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? 'Late night'
        : hour < 12
            ? 'Good morning'
            : hour < 17
                ? 'Good afternoon'
                : hour < 22
                    ? 'Good evening'
                    : 'Late night';

    // Active leg = current; upcoming = next upcoming sorted by date.
    final records = user.records.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final activeLeg = records.where((r) => r.type == 'current').firstOrNull;
    final nextLeg = records.where((r) => r.type == 'upcoming').firstOrNull;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.pulse,
              title: '$greeting,\n$firstName',
              subtitle: 'Mission control \u00b7 your day in motion',
            ),
            const SizedBox(height: Os2.space4),
            // 1. Active/upcoming trip slab — FOCAL.
            if (activeLeg != null || nextLeg != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _TripFocal(
                  record: activeLeg ?? nextLeg!,
                  isActive: activeLeg != null,
                ),
              ),
              const SizedBox(height: Os2.space5),
            ],
            // 2. Identity tier meter.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _IdentityPulse(
                score: user.profile.identityScore,
                scoreMax: scoreAsync.maybeWhen(
                  data: (s) => 1000,
                  orElse: () => 1000,
                ),
                tier: IdentityTier.forScore(user.profile.identityScore),
              ),
            ),
            const SizedBox(height: Os2.space4),
            // 3. Wallet pulse strip.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _WalletPulse(
                balances: wallet.balances,
                defaultCurrency: wallet.defaultCurrency,
              ),
            ),
            const SizedBox(height: Os2.space4),
            // 4. Inbox + concierge dual-slab.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Row(
                children: [
                  Expanded(child: _InboxPulse(unread: inboxUnread)),
                  const SizedBox(width: Os2.space3),
                  Expanded(child: _ConciergeHandoff()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Trip focal slab

class _TripFocal extends StatelessWidget {
  const _TripFocal({required this.record, required this.isActive});

  final dynamic record; // TravelRecord
  final bool isActive;

  String _airportCode(String s) {
    // Heuristic: pull the first 3-letter uppercase token from a string
    // like "San Francisco (SFO)" or "SFO".
    final upper = s.toUpperCase();
    final m = RegExp(r'\b[A-Z]{3}\b').firstMatch(upper);
    return m?.group(0) ?? s.substring(0, s.length.clamp(0, 3)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final from = _airportCode(record.from as String);
    final to = _airportCode(record.to as String);
    final tone = isActive ? Os2.travelTone : Os2.pulseTone;
    return Os2Magnetic(
      onTap: () =>
          GoRouter.of(context).push('/trip/${record.id as String}'),
      child: Os2Slab(
        tone: tone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rHero,
        padding: const EdgeInsets.all(Os2.space5),
        halo: Os2SlabHalo.edge,
        elevation: Os2SlabElevation.cinematic,
        breath: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Os2Chip(
                  label: isActive ? 'IN FLIGHT' : 'NEXT JOURNEY',
                  tone: tone,
                  icon: Icons.flight_takeoff_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
                const SizedBox(width: Os2.space2),
                if (record.flightNumber != null)
                  Os2Chip(
                    label: record.flightNumber as String,
                    tone: tone,
                    intensity: Os2ChipIntensity.subtle,
                  ),
                const Spacer(),
                Os2Beacon(
                  label: isActive ? 'TRACKING' : 'ON SCHEDULE',
                  tone: isActive ? Os2.signalLive : Os2.signalSettled,
                ),
              ],
            ),
            const SizedBox(height: Os2.space5),
            // Solari route.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Os2Text.caption('FROM', color: Os2.inkLow),
                      const SizedBox(height: 4),
                      Os2Solari(
                        text: from,
                        tone: tone,
                        cellWidth: 28,
                        cellHeight: 40,
                        fontSize: 28,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: tone.withValues(alpha: 0.85),
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Os2Text.caption('TO', color: Os2.inkLow),
                      const SizedBox(height: 4),
                      Os2Solari(
                        text: to,
                        tone: tone,
                        cellWidth: 28,
                        cellHeight: 40,
                        fontSize: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Os2.space4),
            Container(height: 0.6, color: Os2.hairline),
            const SizedBox(height: Os2.space4),
            // Meta row.
            Row(
              children: [
                Expanded(
                  child: _MetaCol(
                    label: 'AIRLINE',
                    value: (record.airline as String),
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'DURATION',
                    value: (record.duration as String),
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'DATE',
                    value: (record.date as String).substring(5).replaceAll('-', '·'),
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

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.caption(label, color: Os2.inkLow),
        const SizedBox(height: 3),
        Os2Text.title(
          value,
          color: Os2.inkBright,
          size: 14,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Identity pulse slab

class _IdentityPulse extends StatelessWidget {
  const _IdentityPulse({
    required this.score,
    required this.scoreMax,
    required this.tier,
  });

  final int score;
  final int scoreMax;
  final IdentityTier tier;

  @override
  Widget build(BuildContext context) {
    final pct = (score / scoreMax).clamp(0.0, 1.0);
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).go('/identity'),
      child: Os2Slab(
        tone: Os2.identityTone,
        radius: Os2.rSlab,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.raised,
        padding: const EdgeInsets.all(Os2.space4),
        breath: true,
        child: Row(
          children: [
            Os2Meter(
              value: pct,
              tone: Os2.identityTone,
              diameter: 96,
              strokeWidth: 5,
              ticks: const [0.25, 0.5, 0.75],
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.headline(
                    '$score',
                    color: Os2.inkBright,
                    size: 26,
                    weight: FontWeight.w900,
                  ),
                  Os2Text.caption(
                    '/$scoreMax',
                    color: Os2.inkLow,
                    size: 9,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Os2.space4),
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
                  const SizedBox(height: Os2.space2),
                  Os2Text.title(
                    'Identity tier',
                    color: Os2.inkBright,
                    size: 16,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.body(
                    '${scoreMax - score} pts to next tier',
                    color: Os2.inkMid,
                    size: 12,
                  ),
                  const SizedBox(height: Os2.space2),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: Os2.identityTone),
                      const SizedBox(width: 4),
                      Os2Text.caption(
                        'OPEN SANCTUM',
                        color: Os2.identityTone,
                      ),
                    ],
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

// ─────────────────────────────────────────────────────── Wallet pulse

class _WalletPulse extends StatelessWidget {
  const _WalletPulse({
    required this.balances,
    required this.defaultCurrency,
  });

  final List<dynamic> balances; // List<WalletBalance>
  final String defaultCurrency;

  @override
  Widget build(BuildContext context) {
    final primary = balances.isEmpty
        ? null
        : balances.firstWhere(
            (b) => (b.currency as String) == defaultCurrency,
            orElse: () => balances.first,
          );
    final total = balances.fold<double>(0, (acc, b) {
      final rate = (b.rate as num).toDouble();
      final amount = (b.amount as num).toDouble();
      return acc + (rate > 0 ? amount / rate : amount);
    });
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).go('/wallet'),
      child: Os2Slab(
        tone: Os2.walletTone,
        radius: Os2.rSlab,
        halo: Os2SlabHalo.edge,
        elevation: Os2SlabElevation.raised,
        breath: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Os2Chip(
                  label: 'TREASURY',
                  tone: Os2.walletTone,
                  icon: Icons.account_balance_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
                const Spacer(),
                Os2Beacon(
                  label: '${balances.length} CCY',
                  tone: Os2.walletTone,
                ),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Os2Text.caption(
              'TOTAL · USD EQUIVALENT',
              color: Os2.inkLow,
            ),
            const SizedBox(height: 4),
            Os2Text.display(
              '\$${_fmt(total)}',
              color: Os2.inkBright,
              size: 34,
              maxLines: 1,
            ),
            if (primary != null) ...[
              const SizedBox(height: Os2.space3),
              Container(height: 0.6, color: Os2.hairline),
              const SizedBox(height: Os2.space3),
              Row(
                children: [
                  Os2Text.body(
                    '${primary.flag as String} ${primary.currency as String}',
                    color: Os2.inkMid,
                    size: 13,
                  ),
                  const Spacer(),
                  Os2Text.title(
                    '${primary.symbol as String}${_fmt((primary.amount as num).toDouble())}',
                    color: Os2.inkBright,
                    size: 15,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
}

// ─────────────────────────────────────────────────────── Inbox pulse

class _InboxPulse extends StatelessWidget {
  const _InboxPulse({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push('/inbox'),
      child: Os2Slab(
        tone: Os2.travelTone,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.all(Os2.space4),
        breath: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread_rounded,
                size: 18, color: Os2.travelTone),
            const SizedBox(height: Os2.space3),
            Os2Text.headline(
              '$unread',
              color: Os2.inkBright,
              size: 30,
            ),
            const SizedBox(height: 2),
            Os2Text.caption('INBOX SIGNALS', color: Os2.inkLow),
          ],
        ),
      ),
    );
  }
}

class _ConciergeHandoff extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push('/services'),
      child: Os2Slab(
        tone: Os2.servicesTone,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.all(Os2.space4),
        breath: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.room_service_rounded,
                size: 18, color: Os2.servicesTone),
            const SizedBox(height: Os2.space3),
            Os2Text.headline(
              'Concierge',
              color: Os2.inkBright,
              size: 18,
              weight: FontWeight.w700,
            ),
            const SizedBox(height: 2),
            Os2Text.caption('OPEN FLOOR', color: Os2.servicesTone),
          ],
        ),
      ),
    );
  }
}
