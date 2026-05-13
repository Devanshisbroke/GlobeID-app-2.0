import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_tokens.dart';
import '../../cinematic/sheets/apple_sheet.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Local Mode — activated on arrival at a new city.
/// Shows welcome hero, local time, weather, FX, transport, phrasebook quick-access.
class LocalModeSheet extends StatelessWidget {
  const LocalModeSheet({
    super.key,
    this.city = 'Tokyo',
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.controller,
  });
  final String city, country, flag;
  final ScrollController? controller;

  static Future<void> show(BuildContext context,
      {String city = 'Tokyo', String country = 'Japan', String flag = '🇯🇵'}) {
    HapticFeedback.heavyImpact();
    return showAppleSheet<void>(
      context: context,
      eyebrow: 'ARRIVAL · LOCAL MODE',
      title: 'Welcome to $city',
      tone: const Color(0xFF0EA5E9),
      detents: const [0.55, 0.82, 0.95],
      builder: (controller) => LocalModeSheet(
        city: city,
        country: country,
        flag: flag,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space2,
              AppTokens.space5,
              AppTokens.space5,
            ),
            children: [
              // ── Welcome hero ─────────────────────────────────────
              AnimatedAppearance(
                  child: Center(
                      child: Column(children: [
                Text(flag, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: AppTokens.space2),
                Text('Welcome to $city',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                Text(country,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ]))),
              const SizedBox(height: AppTokens.space5),

              // ── Quick stats ──────────────────────────────────────
              AnimatedAppearance(
                  delay: const Duration(milliseconds: 80),
                  child: Row(children: [
                    _LocalStat(
                        icon: Icons.access_time_rounded,
                        label: 'Local Time',
                        value:
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                        color: const Color(0xFF0EA5E9)),
                    const SizedBox(width: 8),
                    _LocalStat(
                        icon: Icons.thermostat_rounded,
                        label: 'Weather',
                        value: '22°C ☀️',
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _LocalStat(
                        icon: Icons.currency_yen_rounded,
                        label: 'FX Rate',
                        value: '¥163.2',
                        color: const Color(0xFF22C55E)),
                  ])),
              const SizedBox(height: AppTokens.space4),

              // ── Transport ────────────────────────────────────────
              AnimatedAppearance(
                  delay: const Duration(milliseconds: 140),
                  child: _LocalSection(
                    title: 'GROUND TRANSPORT',
                    icon: Icons.directions_rounded,
                    children: [
                      _TransportOption(
                          icon: Icons.train_rounded,
                          name: 'Narita Express',
                          detail: '¥3,250 · 60 min · Platform 1'),
                      _TransportOption(
                          icon: Icons.local_taxi_rounded,
                          name: 'Taxi / Ride',
                          detail: '¥22,000 · 75 min · Exit 2'),
                      _TransportOption(
                          icon: Icons.directions_bus_rounded,
                          name: 'Airport Limousine',
                          detail: '¥3,200 · 85 min · Bus Stop 7'),
                    ],
                  )),
              const SizedBox(height: AppTokens.space4),

              // ── Essentials ───────────────────────────────────────
              AnimatedAppearance(
                  delay: const Duration(milliseconds: 200),
                  child: _LocalSection(
                    title: 'ESSENTIALS',
                    icon: Icons.star_rounded,
                    children: [
                      _EssentialRow(
                          icon: Icons.sim_card_rounded,
                          label: 'eSIM',
                          value: 'Tap to activate',
                          color: const Color(0xFF06B6D4),
                          route: '/esim'),
                      _EssentialRow(
                          icon: Icons.translate_rounded,
                          label: 'Phrasebook',
                          value: 'Japanese loaded',
                          color: const Color(0xFF8B5CF6),
                          route: '/phrasebook'),
                      _EssentialRow(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Currency',
                          value: 'JPY preloaded',
                          color: const Color(0xFF22C55E),
                          route: '/multi-currency'),
                      _EssentialRow(
                          icon: Icons.emergency_rounded,
                          label: 'Emergency',
                          value: '110 Police · 119 Fire',
                          color: const Color(0xFFEF4444),
                          route: '/emergency'),
                    ],
                  )),
              const SizedBox(height: AppTokens.space4),

              // ── Local tips ───────────────────────────────────────
              AnimatedAppearance(
                  delay: const Duration(milliseconds: 260),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.lightbulb_rounded,
                                color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 6),
                            Text('Local Tips',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: AppTokens.space3),
                          for (final tip in [
                            'IC card (Suica/Pasmo) works on all trains and convenience stores',
                            'Tipping is not customary and can be considered rude',
                            'Many ATMs close at night — use 7-Eleven or post office ATMs',
                            'Download offline maps — cellular coverage varies in rural areas',
                          ])
                            Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('•',
                                          style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(tip,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.65),
                                                      height: 1.4))),
                                    ])),
                        ]),
                  )),
              const SizedBox(height: AppTokens.space5),

              // ── Enter city button ────────────────────────────────
              AnimatedAppearance(
                  delay: const Duration(milliseconds: 320),
                  child: Pressable(
                    scale: 0.97,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        gradient: LinearGradient(colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: Center(
                          child: Text('Enter $city',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16))),
                    ),
                  )),
            ]);
  }
}

class _LocalStat extends StatelessWidget {
  const _LocalStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
        child: GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      ]),
    ));
  }
}

class _LocalSection extends StatelessWidget {
  const _LocalSection(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text(title,
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      ]),
      const SizedBox(height: AppTokens.space2),
      ...children,
    ]);
  }
}

class _TransportOption extends StatelessWidget {
  const _TransportOption(
      {required this.icon, required this.name, required this.detail});
  final IconData icon;
  final String name, detail;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GlassSurface(
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Row(children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppTokens.space3),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(detail,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                ])),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ]),
        ));
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.route});
  final IconData icon;
  final String label, value, route;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Pressable(
          scale: 0.98,
          onTap: () {
            HapticFeedback.lightImpact();
            GoRouter.of(context).push(route);
          },
          child: GlassSurface(
            padding: const EdgeInsets.all(AppTokens.space3),
            child: Row(children: [
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      color: color.withValues(alpha: 0.12)),
                  child: Icon(icon, color: color, size: 16)),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(value,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ])),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ]),
          ),
        ));
  }
}
