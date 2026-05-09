import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// EsimScreen — global connectivity activation.
///
/// Country grid → plan picker → instant activation animation.
/// Pure-Dart, deterministic. Wires into Wallet for payment + Travel OS
/// for cross-vertical chaining.
class EsimScreen extends StatefulWidget {
  const EsimScreen({super.key});
  @override
  State<EsimScreen> createState() => _EsimScreenState();
}

class _EsimScreenState extends State<EsimScreen>
    with SingleTickerProviderStateMixin {
  int _country = 0;
  int _plan = 1;

  late final AnimationController _activate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  static const _countries = <_Country>[
    _Country('Japan', '🇯🇵', 'JP', Color(0xFFE11D48)),
    _Country('USA', '🇺🇸', 'US', Color(0xFF1E40AF)),
    _Country('Singapore', '🇸🇬', 'SG', Color(0xFFEA580C)),
    _Country('UAE', '🇦🇪', 'AE', Color(0xFF059669)),
    _Country('UK', '🇬🇧', 'UK', Color(0xFF7E22CE)),
    _Country('France', '🇫🇷', 'FR', Color(0xFF06B6D4)),
    _Country('Germany', '🇩🇪', 'DE', Color(0xFFD97706)),
    _Country('Australia', '🇦🇺', 'AU', Color(0xFF14B8A6)),
  ];

  static const _plans = <_Plan>[
    _Plan('1 GB', '7 days', '\$4.50', 'Light'),
    _Plan('5 GB', '15 days', '\$12.00', 'Most popular'),
    _Plan('20 GB', '30 days', '\$28.00', 'Power'),
    _Plan('Unlimited', '30 days', '\$54.00', 'Flagship'),
  ];

  @override
  void dispose() {
    _activate.dispose();
    super.dispose();
  }

  Future<void> _activateEsim() async {
    HapticFeedback.heavyImpact();
    await _activate.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 48),
            const SizedBox(height: AppTokens.space3),
            Text('eSIM activated',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 6),
            Text(
              '${_countries[_country].name} · ${_plans[_plan].data} · ${_plans[_plan].duration}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _countries[_country].tone;
    return PageScaffold(
      title: 'eSIM',
      subtitle: 'Global connectivity in 30 seconds',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'CONNECTIVITY',
              title: 'Stay connected anywhere',
              subtitle: '180+ countries · LTE / 5G · instant activation',
              icon: Icons.sim_card_rounded,
              tone: tone,
              badges: const [
                HeroBadge(label: 'Instant', icon: Icons.bolt_rounded),
                HeroBadge(label: 'No physical SIM', icon: Icons.eco_rounded),
                HeroBadge(label: '180+', icon: Icons.public_rounded),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              0,
            ),
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 80),
              child: EsimDataWave(
                country: _countries[_country].code,
                dataLabel: _plans[_plan].data,
                duration: _plans[_plan].duration,
                priceLabel: _plans[_plan].price,
                tone: tone,
                percent: (_plan + 1) / _plans.length,
              ),
            ),
          ),
          const SectionHeader(
              title: 'Choose country', subtitle: 'Tap to switch destination'),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 1),
              itemCount: _countries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTokens.space2),
              itemBuilder: (_, i) {
                final c = _countries[i];
                final selected = _country == i;
                return Pressable(
                  scale: 0.96,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _country = i);
                  },
                  child: AnimatedContainer(
                    duration: AppTokens.durationSm,
                    width: 132,
                    padding: const EdgeInsets.all(AppTokens.space3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          c.tone.withValues(alpha: selected ? 0.85 : 0.45),
                          c.tone.withValues(alpha: selected ? 0.45 : 0.20),
                        ],
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: c.tone.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10)),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 28)),
                        const Spacer(),
                        Text(c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            )),
                        Text(c.code,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SectionHeader(
              title: 'Choose plan', subtitle: 'Switch any time'),
          for (var i = 0; i < _plans.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: Pressable(
                scale: 0.99,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _plan = i);
                },
                child: AnimatedContainer(
                  duration: AppTokens.durationSm,
                  padding: const EdgeInsets.all(AppTokens.space3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: _plan == i
                          ? tone.withValues(alpha: 0.55)
                          : theme.colorScheme.outline.withValues(alpha: 0.16),
                      width: _plan == i ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tone.withValues(alpha: 0.18),
                        ),
                        child: Icon(
                          _plan == i
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: tone,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_plans[i].data} · ${_plans[i].duration}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(_plans[i].label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                )),
                          ],
                        ),
                      ),
                      Text(_plans[i].price,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: tone,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space5),
          AgenticBand(
            title: 'After activation',
            chips: [
              AgenticChip(
                icon: Icons.translate_rounded,
                label: 'Translator',
                route: '/copilot',
                tone: tone,
              ),
              const AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Get a ride',
                route: '/services/rides',
                tone: Color(0xFFEA580C),
              ),
              const AgenticChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan to pay',
                route: '/wallet/scan',
                tone: Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedBuilder(
            animation: _activate,
            builder: (_, __) {
              return Stack(
                children: [
                  CinematicButton(
                    label:
                        'Activate ${_countries[_country].name} eSIM · ${_plans[_plan].price}',
                    icon: Icons.bolt_rounded,
                    gradient: LinearGradient(
                      colors: [tone, tone.withValues(alpha: 0.55)],
                    ),
                    onPressed: _activateEsim,
                  ),
                  if (_activate.value > 0 && _activate.value < 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        child: SizedBox(
                          height: 4,
                          child: FractionallySizedBox(
                            widthFactor: _activate.value,
                            alignment: Alignment.centerLeft,
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.space5),
          PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: tone),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Charge to GlobeID wallet',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      Text(
                        'Or split with a travel companion',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onTap: () => GoRouter.of(context).push('/wallet'),
                  child: Icon(Icons.chevron_right_rounded, color: tone),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _Country {
  const _Country(this.name, this.flag, this.code, this.tone);
  final String name;
  final String flag;
  final String code;
  final Color tone;
}

class _Plan {
  const _Plan(this.data, this.duration, this.price, this.label);
  final String data;
  final String duration;
  final String price;
  final String label;
}
