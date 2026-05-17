import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// Main settings index. User-facing categories only — every
/// developer / preview / sandbox / ceremony surface lives under
/// `/settings/lab`. Mirrors Apple iOS Settings.app rhythm: dense
/// rows, subtle dividers, accent chips, no shouting.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'Settings',
      subtitle: 'Tune every layer of GlobeID',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.palette_rounded,
                    tone: const Color(0xFF7C3AED),
                    label: 'Appearance',
                    sub: 'Theme · accent · density · motion',
                    onTap: () => context.push('/settings/appearance'),
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_rounded,
                    tone: const Color(0xFFE11D48),
                    label: 'Notifications',
                    sub: 'Alerts · email · push · do not disturb',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  _SettingsRow(
                    icon: Icons.lock_rounded,
                    tone: const Color(0xFFEA580C),
                    label: 'Security & sign-in',
                    sub: 'Biometrics · passcode · sessions',
                    onTap: () => context.push('/settings/security'),
                  ),
                  _SettingsRow(
                    icon: Icons.privacy_tip_rounded,
                    tone: const Color(0xFF06B6D4),
                    label: 'Privacy & data',
                    sub: 'Visibility · sharing · downloads',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  _SettingsRow(
                    icon: Icons.flight_rounded,
                    tone: const Color(0xFF3B82F6),
                    label: 'Travel preferences',
                    sub: 'Cabin · seat · meal · loyalty',
                    onTap: () => context.push('/settings/travel'),
                  ),
                  _SettingsRow(
                    icon: Icons.extension_rounded,
                    tone: const Color(0xFF10B981),
                    label: 'Integrations',
                    sub: 'Calendar · email · eSIM · airlines',
                    onTap: () => context.push('/profile'),
                  ),
                  _SettingsRow(
                    icon: Icons.accessibility_new_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Accessibility',
                    sub: 'Text size · contrast · reduce motion',
                    onTap: () => context.push('/settings/accessibility'),
                  ),
                  _SettingsRow(
                    icon: Icons.dashboard_customize_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Ambient surfaces',
                    sub: 'Live Activity · widgets · watch · lock',
                    onTap: () => context.push('/ambient'),
                  ),
                  _SettingsRow(
                    icon: Icons.science_rounded,
                    tone: const Color(0xFFEAB308),
                    label: 'Lab features',
                    sub: 'Experimental · sandbox · ceremonies · adapters',
                    onTap: () => context.push('/settings/lab'),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    tone: const Color(0xFF8B5CF6),
                    label: 'About',
                    sub: 'Version · open source · credits',
                    onTap: () => context.push('/settings/about'),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Quick toggles', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                children: [
                  _QuickToggle(
                    icon: Icons.do_not_disturb_on_rounded,
                    label: 'Do not disturb',
                    initial: false,
                  ),
                  _QuickToggle(
                    icon: Icons.airplane_ticket_rounded,
                    label: 'Travel mode',
                    initial: true,
                  ),
                  _QuickToggle(
                    icon: Icons.location_on_rounded,
                    label: 'Precise location',
                    initial: true,
                  ),
                  _QuickToggle(
                    icon: Icons.bedtime_rounded,
                    label: 'Auto dark by sun',
                    initial: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.tone,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final Color tone;
  final String label;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Pressable(
      scale: 0.99,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(sub,
                      style: t.textTheme.bodySmall?.copyWith(
                          color:
                              t.colorScheme.onSurface.withValues(alpha: 0.60))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.colorScheme.onSurface.withValues(alpha: 0.32)),
          ],
        ),
      ),
    );
  }
}

class _QuickToggle extends StatefulWidget {
  const _QuickToggle({
    required this.icon,
    required this.label,
    required this.initial,
  });
  final IconData icon;
  final String label;
  final bool initial;
  @override
  State<_QuickToggle> createState() => _QuickToggleState();
}

class _QuickToggleState extends State<_QuickToggle> {
  late bool _v = widget.initial;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(widget.icon,
              size: 20, color: t.colorScheme.onSurface.withValues(alpha: 0.78)),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(widget.label,
                style: t.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Switch.adaptive(
            value: _v,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              setState(() => _v = v);
            },
          ),
        ],
      ),
    );
  }
}
