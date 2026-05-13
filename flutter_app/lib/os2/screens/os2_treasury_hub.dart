import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../os2_tokens.dart';
import '../primitives/os2_bar.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_dial.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_micro_meter.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_progress_arc.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_status_pill.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Treasury hub.
///
/// Wallet-of-wallets command surface:
///   • Cinematic net-worth hero (Solari ticker + breathing halo);
///   • Currency breakdown bars (EUR, USD, GBP, JPY, INR, vault);
///   • Liquidity + FX confidence dials;
///   • Autosweep & spend rules (toggleable rows);
///   • 30-day cash-flow micro-meter strip;
///   • Recent treasury events timeline.
class Os2TreasuryHub extends ConsumerWidget {
  const Os2TreasuryHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Treasury', color: Os2.inkBright, size: Os2.textXl),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Os2.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Os2Beacon(label: 'TREASURY \u00b7 LIVE',
                        tone: Os2.walletTone),
                    const Spacer(),
                    Os2StatusPill(
                      label: 'AUTOSWEEP',
                      value: 'ARMED',
                      tone: Os2.signalSettled,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _NetWorthHero(),
              ),
              const SizedBox(height: Os2.space4),
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.savings_rounded,
                    label: 'LIQUID',
                    value: '\u20ac42.6K',
                    tone: Os2.signalSettled,
                  ),
                  Os2InfoEntry(
                    icon: Icons.lock_rounded,
                    label: 'VAULT',
                    value: '\u20ac128K',
                    tone: Os2.identityTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.trending_up_rounded,
                    label: '30D',
                    value: '+4.8%',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.currency_exchange_rounded,
                    label: 'FX EDGE',
                    value: '+12 BP',
                    tone: Os2.walletTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.cyclone_rounded,
                    label: 'SWEEP',
                    value: 'IDLE',
                    tone: Os2.inkMid,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _CurrencyBreakdown(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _LiquidityDials(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _CashflowStrip(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _RulesSlab(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _RecentEvents(),
              ),
              const SizedBox(height: Os2.space5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Ribbon(
                  label: 'POSTURE',
                  value: 'HEALTHY \u00b7 OVERHEAD 3.6\u00d7',
                  tone: Os2.signalSettled,
                  trailing: 'STEADY',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetWorthHero extends StatelessWidget {
  const _NetWorthHero();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.walletTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.all(Os2.space4),
      breath: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Os2Text.monoCap('NET WORTH \u00b7 EUR',
                  color: Os2.walletTone, size: 11),
              const Spacer(),
              Os2Text.monoCap('AS OF 16:42',
                  color: Os2.inkLow, size: 11),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Center(
            child: Os2Solari(
              text: '170,642',
              fontSize: 38,
              cellWidth: 24,
              cellHeight: 38,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Center(
            child: Os2Text.caption(
              '\u20ac \u00b7 +\u20ac7,820 over 30d',
              color: Os2.inkMid,
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'LIQUID', value: '\u20ac42.6K'),
              _Stat(label: 'VAULT', value: '\u20ac128K'),
              _Stat(label: 'GROWTH', value: '+4.8%'),
              _Stat(label: 'BURN', value: '\u20ac2.1K/MO'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Os2Text.monoCap(label, color: Os2.inkLow, size: Os2.textMicro),
        const SizedBox(height: 4),
        Os2Text.title(value, color: Os2.inkBright, size: Os2.textRg),
      ],
    );
  }
}

class _CurrencyBreakdown extends StatelessWidget {
  const _CurrencyBreakdown();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.walletTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'CURRENCY MIX',
            tone: Os2.walletTone,
            trailing: '6 CURRENCIES',
          ),
          const SizedBox(height: Os2.space3),
          Os2BarStack(
            tone: Os2.walletTone,
            entries: const [
              Os2BarEntry(label: 'EUR · primary', value: 0.62,
                  trailing: '\u20ac26.4K'),
              Os2BarEntry(label: 'USD · travel', value: 0.42,
                  trailing: '\$11.2K'),
              Os2BarEntry(label: 'GBP · holiday', value: 0.24,
                  trailing: '\u00a35.8K'),
              Os2BarEntry(label: 'JPY · onsen', value: 0.18,
                  trailing: '\u00a51.6M'),
              Os2BarEntry(label: 'INR · family', value: 0.32,
                  trailing: '\u20b9420K'),
              Os2BarEntry(label: 'VAULT · sealed', value: 0.86,
                  trailing: '\u20ac128K'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidityDials extends StatelessWidget {
  const _LiquidityDials();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.travelTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'LIQUIDITY & FX',
            tone: Os2.travelTone,
            trailing: 'LIVE',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Expanded(
                child: Os2Dial(
                  value: 0.87,
                  tone: Os2.signalSettled,
                  label: 'LIQUIDITY',
                  center: Os2Text.monoCap('87%',
                      color: Os2.inkBright, size: 14),
                ),
              ),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Os2Dial(
                  value: 0.62,
                  tone: Os2.walletTone,
                  label: 'FX CONF.',
                  center: Os2Text.monoCap('A+',
                      color: Os2.inkBright, size: 14),
                ),
              ),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Os2Dial(
                  value: 0.36,
                  tone: Os2.identityTone,
                  label: 'BURN',
                  center: Os2Text.monoCap('LOW',
                      color: Os2.inkBright, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2MicroMeter(
            label: 'AUTO',
            value: 0.74,
            tone: Os2.travelTone,
            trailing: '74%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'TAXES',
            value: 0.41,
            tone: Os2.walletTone,
            trailing: '\u20ac1.2K',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'CREDIT',
            value: 0.18,
            tone: Os2.signalSettled,
            trailing: '\u20ac640',
          ),
        ],
      ),
    );
  }
}

class _CashflowStrip extends StatelessWidget {
  const _CashflowStrip();

  @override
  Widget build(BuildContext context) {
    // 30 deterministic micro-bars.
    final flows = List<double>.generate(30, (i) {
      final base = 0.4 + 0.45 * ((i % 6) / 5);
      final shift = ((i * 13) % 17) / 30.0;
      return (base + shift - 0.3).clamp(0.05, 1.0);
    });
    return Os2Slab(
      tone: Os2.signalSettled,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: '30-DAY CASH FLOW',
            tone: Os2.signalSettled,
            trailing: '+\u20ac7,820',
          ),
          const SizedBox(height: Os2.space3),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final v in flows) ...[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Os2.signalSettled.withValues(alpha: 0.85),
                            Os2.signalSettled.withValues(alpha: 0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        heightFactor: v,
                        alignment: Alignment.bottomCenter,
                        child: const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Os2StatusPill(
                label: 'INFLOW',
                value: '\u20ac11.4K',
                tone: Os2.signalSettled,
                dense: true,
              ),
              const SizedBox(width: Os2.space2),
              Os2StatusPill(
                label: 'OUT',
                value: '\u20ac3.6K',
                tone: Os2.walletTone,
                dense: true,
              ),
              const Spacer(),
              Os2Text.monoCap('LAST 30D', color: Os2.inkLow, size: Os2.textMicro),
            ],
          ),
        ],
      ),
    );
  }
}

class _RulesSlab extends StatefulWidget {
  const _RulesSlab();
  @override
  State<_RulesSlab> createState() => _RulesSlabState();
}

class _RulesSlabState extends State<_RulesSlab> {
  bool _sweep = true;
  bool _fxOpt = true;
  bool _spendBudget = true;
  bool _vaultLock = false;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.servicesTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'STANDING PROTOCOLS',
            tone: Os2.servicesTone,
            trailing: '4 RULES',
          ),
          const SizedBox(height: Os2.space3),
          _RuleRow(
            icon: Icons.cyclone_rounded,
            title: 'Auto-sweep idle balances',
            sub: 'EUR → USD on best mid-rate · slip < 8 bp',
            tone: Os2.servicesTone,
            value: _sweep,
            onChange: (v) => setState(() => _sweep = v),
          ),
          const _ThinSep(),
          _RuleRow(
            icon: Icons.swap_horiz_rounded,
            title: 'FX optimization',
            sub: 'Pre-stage USD before travel · 7 days ahead',
            tone: Os2.walletTone,
            value: _fxOpt,
            onChange: (v) => setState(() => _fxOpt = v),
          ),
          const _ThinSep(),
          _RuleRow(
            icon: Icons.donut_small_rounded,
            title: 'Spend budget',
            sub: '\u20ac2.4K / month · breaks alert at 80%',
            tone: Os2.travelTone,
            value: _spendBudget,
            onChange: (v) => setState(() => _spendBudget = v),
          ),
          const _ThinSep(),
          _RuleRow(
            icon: Icons.lock_outline_rounded,
            title: 'Vault auto-lock at 23:00 local',
            sub: 'Bio-only release · 1 hour cooldown',
            tone: Os2.identityTone,
            value: _vaultLock,
            onChange: (v) => setState(() => _vaultLock = v),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.tone,
    required this.value,
    required this.onChange,
  });
  final IconData icon;
  final String title;
  final String sub;
  final Color tone;
  final bool value;
  final void Function(bool) onChange;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () {
        HapticFeedback.selectionClick();
        onChange(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Os2.space2),
        child: Row(
          children: [
            Os2GlyphHalo(icon: icon, tone: tone, size: 36),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.title(title, color: Os2.inkBright, size: Os2.textRg),
                  const SizedBox(height: 2),
                  Os2Text.caption(sub, color: Os2.inkMid),
                ],
              ),
            ),
            const SizedBox(width: Os2.space2),
            Os2ProgressArc(
              value: value ? 1.0 : 0.05,
              tone: value ? tone : Os2.inkLow,
              diameter: 28,
              strokeWidth: 3,
              center: Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                color: value ? tone : Os2.inkLow,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinSep extends StatelessWidget {
  const _ThinSep();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(height: 1, color: Os2.hairlineSoft),
      );
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents();
  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.pulseTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'TREASURY EVENTS',
            tone: Os2.pulseTone,
            trailing: 'LAST 7D',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.pulseTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'Auto-sweep \u00b7 EUR \u2192 USD',
                caption: '\u20ac3.2K \u00b7 slip 4.6 bp \u00b7 settled',
                trailing: '02H',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Recurring \u00b7 hotel deposit',
                caption: 'Soma Suites \u00b7 \u20ac420 \u00b7 cleared',
                trailing: '14H',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'FX optimisation \u00b7 pre-stage',
                caption: 'USD 2.4K queued for travel',
                trailing: '01D',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Identity audit \u00b7 quarterly',
                caption: 'All checks passing',
                trailing: '03D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Vault sync',
                caption: 'Cross-signed \u00b7 8 issuers',
                trailing: '07D',
                state: Os2NodeState.settled,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'CLEARANCE',
            tone: Os2.signalSettled,
            pips: const [
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.active,
              Os2PipState.pending,
              Os2PipState.pending,
            ],
            trailing: '3 / 5 CLEARED',
          ),
        ],
      ),
    );
  }
}
