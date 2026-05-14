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

/// Main settings index. Each tile drills into a focused sub-screen
/// under the same /settings/* prefix. Mirrors the visual rhythm of
/// Apple iOS Settings.app: dense rows, subtle dividers, accent
/// chips, no shouting.
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
                    icon: Icons.science_rounded,
                    tone: const Color(0xFFEAB308),
                    label: 'Lab features',
                    sub: 'Experimental · early access',
                    onTap: () => context.push('/settings/lab'),
                  ),
                  _SettingsRow(
                    icon: Icons.auto_awesome_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Premium UI showcase',
                    sub: 'Magnetic · liquid · solari · sensor',
                    onTap: () => context.push('/premium-showcase'),
                  ),
                  _SettingsRow(
                    icon: Icons.flight_takeoff_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Live Activity preview',
                    sub: 'Dynamic Island · boarding countdown',
                    onTap: () => context.push('/ambient/live-activity'),
                  ),
                  _SettingsRow(
                    icon: Icons.widgets_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Home-screen widgets',
                    sub: 'Trip countdown · FX · visa expiry',
                    onTap: () => context.push('/ambient/widgets'),
                  ),
                  _SettingsRow(
                    icon: Icons.watch_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Watch face complications',
                    sub: 'watchOS · Wear OS · boarding glance',
                    onTap: () => context.push('/ambient/watch'),
                  ),
                  _SettingsRow(
                    icon: Icons.tune_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Quick tiles',
                    sub: 'iOS Control Center · Android QS',
                    onTap: () => context.push('/ambient/quick-settings'),
                  ),
                  _SettingsRow(
                    icon: Icons.lock_clock_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Lock screen widgets',
                    sub: 'Accessory · Always-On',
                    onTap: () => context.push('/ambient/lock-screen'),
                  ),
                  _SettingsRow(
                    icon: Icons.dashboard_customize_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Ambient hub',
                    sub: 'Dynamic Island · widgets · watch · lock',
                    onTap: () => context.push('/ambient'),
                  ),
                  _SettingsRow(
                    icon: Icons.currency_exchange_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'FX adapter',
                    sub: 'Frankfurter (ECB) · demo drift · STALE',
                    onTap: () => context.push('/lab/fx-adapter'),
                  ),
                  _SettingsRow(
                    icon: Icons.flight_takeoff_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Flight adapter',
                    sub: 'AeroAPI (FlightAware) · demo phase machine',
                    onTap: () => context.push('/lab/flight-adapter'),
                  ),
                  _SettingsRow(
                    icon: Icons.travel_explore_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Visa adapter',
                    sub: 'PassportIndex matrix · demo snapshot',
                    onTap: () => context.push('/lab/visa-adapter'),
                  ),
                  _SettingsRow(
                    icon: Icons.cloud_upload_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Telemetry sink',
                    sub: 'Buffer · Console · Sentry · fan-out',
                    onTap: () => context.push('/lab/telemetry'),
                  ),
                  _SettingsRow(
                    icon: Icons.history_toggle_off_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Offline-first cache',
                    sub: 'STALE chip ladder · TimestampedCache',
                    onTap: () => context.push('/lab/offline-cache'),
                  ),
                  _SettingsRow(
                    icon: Icons.verified_outlined,
                    tone: const Color(0xFFD4AF37),
                    label: 'Production readiness',
                    sub: 'Phase 10 capstone · live + idle + demo audit',
                    onTap: () => context.push('/lab/production-readiness'),
                  ),
                  _SettingsRow(
                    icon: Icons.menu_book_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Passport opening ceremony',
                    sub: '3s cinematic · foil sweep · bearer reveal',
                    onTap: () => context.push('/lab/passport-ceremony'),
                  ),
                  _SettingsRow(
                    icon: Icons.approval_rounded,
                    tone: const Color(0xFFC8932F),
                    label: 'Visa stamp ceremony',
                    sub: '4-frame · ink load · arc · press · bleed',
                    onTap: () => context.push('/lab/visa-stamp'),
                  ),
                  _SettingsRow(
                    icon: Icons.print_outlined,
                    tone: const Color(0xFFD4AF37),
                    label: 'Boarding PRINTED reveal',
                    sub: 'Roller strikes · 6 px overshoot · ribbon',
                    onTap: () => context.push('/lab/boarding-printed'),
                  ),
                  _SettingsRow(
                    icon: Icons.folder_special_outlined,
                    tone: const Color(0xFFB73E3E),
                    label: 'Country DECLASSIFIED dossier',
                    sub: 'Cover lift · 3 CLASSIFIED strikes · reveal',
                    onTap: () => context.push('/lab/declassified'),
                  ),
                  _SettingsRow(
                    icon: Icons.workspaces_outline,
                    tone: const Color(0xFFD4AF37),
                    label: 'Lounge velvet rope',
                    sub: 'Brass arm · rope lift · member reveal',
                    onTap: () => context.push('/lab/velvet-rope'),
                  ),
                  _SettingsRow(
                    icon: Icons.movie_filter_outlined,
                    tone: const Color(0xFFD4AF37),
                    label: 'Cinematics',
                    sub: 'Five GlobeID-engineered ceremonies',
                    onTap: () => context.push('/cinematics'),
                  ),
                  _SettingsRow(
                    icon: Icons.workspace_premium_outlined,
                    tone: const Color(0xFFD4AF37),
                    label: 'Cold-mount seal',
                    sub: 'Phase 12b · GlobeID seal stamp ceremony',
                    onTap: () => context.push('/lab/seal-coldmount'),
                  ),
                  _SettingsRow(
                    icon: Icons.diamond_outlined,
                    tone: const Color(0xFFE9C75D),
                    label: 'Identity signet',
                    sub: 'Phase 12c · STANDARD · ATELIER · PILOT variants',
                    onTap: () => context.push('/lab/identity-signet'),
                  ),
                  _SettingsRow(
                    icon: Icons.center_focus_strong_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Camera chrome',
                    sub: 'Phase 12d · 5 GlobeID-engineered scan modes',
                    onTap: () => context.push('/lab/camera-chrome'),
                  ),
                  _SettingsRow(
                    icon: Icons.receipt_long_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'Receipts',
                    sub: 'Phase 12e · 5 GlobeID-engineered receipts',
                    onTap: () => context.push('/lab/receipts'),
                  ),
                  _SettingsRow(
                    icon: Icons.workspace_premium_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Brand surface gallery',
                    sub: 'Phase 12 capstone · all 5 brand surfaces',
                    onTap: () => context.push('/lab/brand-gallery'),
                  ),
                  _SettingsRow(
                    icon: Icons.translate_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'Locale gallery',
                    sub: 'Phase 13a · 5 locales · brand chrome stays foil',
                    onTap: () => context.push('/lab/locale-gallery'),
                  ),
                  _SettingsRow(
                    icon: Icons.format_textdirection_r_to_l_rounded,
                    tone: const Color(0xFFC9A961),
                    label: 'RTL audit',
                    sub: 'Phase 13b · brand chrome stays LTR Latin',
                    onTap: () => context.push('/lab/rtl-audit'),
                  ),
                  _SettingsRow(
                    icon: Icons.format_size_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'Dynamic Type audit',
                    sub: 'Phase 13c · body scales · chrome capped at 1.35×',
                    onTap: () => context.push('/lab/dynamic-type'),
                  ),
                  _SettingsRow(
                    icon: Icons.motion_photos_paused_rounded,
                    tone: const Color(0xFFC9A961),
                    label: 'Reduced motion audit',
                    sub: 'Phase 13d · structural · ambient · signature',
                    onTap: () => context.push('/lab/reduced-motion'),
                  ),
                  _SettingsRow(
                    icon: Icons.contrast_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'WCAG contrast audit',
                    sub: 'Phase 13e · foil + chrome + accents vs OLED',
                    onTap: () => context.push('/lab/wcag'),
                  ),
                  _SettingsRow(
                    icon: Icons.tune_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Locale + Accessibility',
                    sub: 'Phase 13f · capstone hub · 5 modules · live status',
                    onTap: () => context.push('/lab/locale-a11y'),
                  ),
                  _SettingsRow(
                    icon: Icons.collections_bookmark_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'Atelier · design system',
                    sub: 'Phase 14a · 19 primitives · 4 domains',
                    onTap: () => context.push('/atelier'),
                  ),
                  _SettingsRow(
                    icon: Icons.timeline_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Motion choreography',
                    sub: 'Phase 14b · 10 durations · 6 curves · live',
                    onTap: () => context.push('/atelier/lab/motion'),
                  ),
                  _SettingsRow(
                    icon: Icons.token_rounded,
                    tone: const Color(0xFFE9C75D),
                    label: 'Brand tokens · export',
                    sub: 'Phase 14c · 67 tokens · JSON',
                    onTap: () => context.push('/atelier/lab/tokens'),
                  ),
                  _SettingsRow(
                    icon: Icons.grid_view_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Visual regression',
                    sub: 'Phase 14d · 8 specimens · canonical sizing',
                    onTap: () => context.push('/atelier/lab/regression'),
                  ),
                  _SettingsRow(
                    icon: Icons.history_edu_rounded,
                    tone: const Color(0xFFD4AF37),
                    label: 'Brand DNA timeline',
                    sub: 'Phase 14e · 14 chapters · invariants',
                    onTap: () => context.push('/atelier/lab/dna-timeline'),
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
