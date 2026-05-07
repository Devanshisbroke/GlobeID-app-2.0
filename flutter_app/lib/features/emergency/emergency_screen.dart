import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';

/// EmergencySosScreen — civilization-scale safety hub.
///
/// Surfaces local emergency numbers, embassy contact, share-location
/// burst, and a long-press SOS button that "pings" trusted contacts.
/// All data is contextually adapted to the current destination.
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({
    super.key,
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFFDC2626),
  });

  final String country;
  final String flag;
  final Color tone;

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  bool _armed = false;

  static const _hotlines = <(IconData, String, String, String)>[
    (Icons.local_police_rounded, 'Police', '110', 'JPN national line'),
    (Icons.medical_services_rounded, 'Ambulance', '119',
        'Fire & medical dispatch'),
    (Icons.local_fire_department_rounded, 'Fire', '119',
        'Same as ambulance dispatch'),
    (Icons.support_agent_rounded, 'Tourist hotline', '050-3816-2787',
        'JNTO English support'),
  ];

  static const _embassy = <(IconData, String, String)>[
    (Icons.account_balance_rounded, 'Embassy', '+81-3-3224-5000'),
    (Icons.email_rounded, 'Email', 'tokyoacs@state.gov'),
    (Icons.location_on_rounded, 'Address', '1-10-5 Akasaka, Minato-ku'),
    (Icons.access_time_rounded, 'Hours', 'Mon–Fri · 08:30–17:30'),
  ];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageScaffold(
      title: 'Emergency',
      subtitle: 'Live in ${widget.country} ${widget.flag}',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'SAFETY · LIVE',
              title: 'Help in seconds',
              subtitle: 'Local services, embassy, and trusted contacts.',
              tone: widget.tone,
              icon: Icons.shield_rounded,
              flag: widget.flag,
              badges: const [
                HeroBadge(
                    label: 'Long-press SOS', icon: Icons.touch_app_rounded),
                HeroBadge(label: 'Auto-locate', icon: Icons.gps_fixed_rounded),
                HeroBadge(label: 'Multilingual', icon: Icons.translate_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 60),
            child: Center(
              child: GestureDetector(
                onLongPressStart: (_) {
                  HapticFeedback.heavyImpact();
                  setState(() => _armed = true);
                },
                onLongPressEnd: (_) {
                  HapticFeedback.mediumImpact();
                  setState(() => _armed = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: widget.tone,
                      content: const Text(
                        'SOS broadcast to your trusted contacts.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final scale = _armed
                        ? 1.0 + math.sin(_pulse.value * math.pi * 2) * 0.07
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 192,
                        height: 192,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.tone,
                              widget.tone.withValues(alpha: 0.55),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.tone
                                  .withValues(alpha: _armed ? 0.55 : 0.32),
                              blurRadius: _armed ? 50 : 28,
                              spreadRadius: _armed ? 6 : 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.priority_high_rounded,
                                color: Colors.white, size: 56),
                            SizedBox(height: 4),
                            Text('HOLD FOR SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          const SectionHeader(
              title: 'Local hotlines',
              subtitle: 'Tap to dial · stays in your call log'),
          for (var i = 0; i < _hotlines.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.tone.withValues(alpha: 0.16),
                        ),
                        child: Icon(_hotlines[i].$1,
                            color: widget.tone, size: 22),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_hotlines[i].$2,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                            Text(_hotlines[i].$4,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.tone.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                        child: Text(_hotlines[i].$3,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.tone,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space4),
          const SectionHeader(
              title: 'Your embassy',
              subtitle: 'United States Embassy · Tokyo'),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                children: [
                  for (var i = 0; i < _embassy.length; i++) ...[
                    Row(
                      children: [
                        Icon(_embassy[i].$1, color: widget.tone, size: 18),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Text(_embassy[i].$2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              )),
                        ),
                        Text(_embassy[i].$3,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                    if (i != _embassy.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          const SectionHeader(
              title: 'Trusted chain',
              subtitle: 'Who gets pinged when you trigger SOS'),
          AgenticBand(
            title: '',
            chips: const [
              AgenticChip(
                icon: Icons.contact_emergency_rounded,
                label: 'Family · 3',
                eyebrow: 'on call',
                route: '/profile',
                tone: Color(0xFF7C3AED),
              ),
              AgenticChip(
                icon: Icons.location_on_rounded,
                label: 'Share location',
                eyebrow: 'burst',
                route: '/map',
                tone: Color(0xFF10B981),
              ),
              AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Hail safe ride',
                eyebrow: 'transit',
                route: '/services/rides',
                tone: Color(0xFFEA580C),
              ),
              AgenticChip(
                icon: Icons.translate_rounded,
                label: 'Phrasebook',
                eyebrow: 'help',
                route: '/phrasebook',
                tone: Color(0xFFE11D48),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Share live location with family',
            icon: Icons.gps_fixed_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF22D3EE)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              GoRouter.of(context).push('/map');
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}
