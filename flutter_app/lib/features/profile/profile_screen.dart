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
import '../../widgets/toast.dart';
import '../settings/theme_prefs_provider.dart';
import '../user/user_provider.dart';

/// Profile + theme studio. Inline accent picker, theme-mode segmented
/// control, density toggle, live preview card. No modals — every change
/// is reflected immediately.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final prefs = ref.watch(themePrefsProvider);
    final theme = Theme.of(context);

    return PageScaffold(
      title: 'Profile',
      subtitle: user.profile.email,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: AppTokens.shadowMd(
                          tint: theme.colorScheme.primary,
                        ),
                      ),
                      child: user.profile.avatarUrl.isEmpty
                          ? const Icon(Icons.person_rounded,
                              color: Colors.white, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.profile.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                        Text(
                            user.profile.passportNumber.isNotEmpty
                                ? 'Passport ${user.profile.passportNumber}'
                                : 'No passport on file',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppTokens.space2),
                        Row(children: [
                          Text(user.profile.nationalityFlag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(user.profile.nationality,
                              style: theme.textTheme.bodySmall),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Appearance', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme mode',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.6,
                      )),
                  const SizedBox(height: AppTokens.space2),
                  _SegmentedThemeMode(
                    value: prefs.themeMode,
                    onChanged: (m) =>
                        ref.read(themePrefsProvider.notifier).setThemeMode(m),
                  ),
                  const SizedBox(height: AppTokens.space5),
                  Text('Accent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.6,
                      )),
                  const SizedBox(height: AppTokens.space2),
                  _AccentRow(
                    selected: prefs.accent,
                    onPick: (a) {
                      ref.read(themePrefsProvider.notifier).setAccent(a);
                      AppToast.show(
                        context,
                        title: 'Accent updated',
                        message: 'Theme refreshed across the app',
                        tone: AppToastTone.info,
                      );
                    },
                  ),
                  const SizedBox(height: AppTokens.space5),
                  Text('Density',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.6,
                      )),
                  const SizedBox(height: AppTokens.space2),
                  _DensityRow(
                    value: prefs.density,
                    onChanged: (d) =>
                        ref.read(themePrefsProvider.notifier).setDensity(d),
                  ),
                ],
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.contrast_rounded,
                    label: 'High contrast',
                    value: prefs.highContrast,
                    onChanged: (_) => ref
                        .read(themePrefsProvider.notifier)
                        .toggleHighContrast(),
                  ),
                  _SwitchRow(
                    icon: Icons.blur_off_rounded,
                    label: 'Reduce transparency',
                    value: prefs.reduceTransparency,
                    onChanged: (_) => ref
                        .read(themePrefsProvider.notifier)
                        .toggleReduceTransparency(),
                  ),
                  _SwitchRow(
                    icon: Icons.bedtime_rounded,
                    label: 'Auto theme by time',
                    value: prefs.autoTheme,
                    onChanged: (_) =>
                        ref.read(themePrefsProvider.notifier).toggleAutoTheme(),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Account', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 280),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _NavRow(
                      icon: Icons.shield_moon_rounded,
                      label: 'Vault',
                      onTap: () => context.push('/vault')),
                  _NavRow(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      onTap: () => context.push('/analytics')),
                  _NavRow(
                      icon: Icons.smart_toy_rounded,
                      label: 'Copilot',
                      onTap: () => context.push('/copilot')),
                  _NavRow(
                      icon: Icons.history_rounded,
                      label: 'Audit log',
                      onTap: () => context.push('/audit-log')),
                ],
              ),
            ),
          ),

          // ── Membership stats strip ────────────────────────────
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 320),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Row(
                children: const [
                  _StatTile(label: 'Member since', value: 'Jan 2022'),
                  _StatDivider(),
                  _StatTile(label: 'Trips', value: '47'),
                  _StatDivider(),
                  _StatTile(label: 'Countries', value: '29'),
                  _StatDivider(),
                  _StatTile(label: 'Tier', value: 'Plus'),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Devices & sessions', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 360),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _DeviceRow(
                      icon: Icons.phone_iphone_rounded,
                      label: 'iPhone 15 Pro · This device',
                      sub: 'Berlin · Just now',
                      isCurrent: true),
                  _DeviceRow(
                      icon: Icons.tablet_mac_rounded,
                      label: 'iPad Air',
                      sub: 'Berlin · 2 days ago'),
                  _DeviceRow(
                      icon: Icons.laptop_mac_rounded,
                      label: 'MacBook Pro',
                      sub: 'Berlin · 4 days ago'),
                  _NavRow(
                      icon: Icons.devices_other_rounded,
                      label: 'Manage all devices',
                      onTap: () => context.push('/audit-log')),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Connected accounts', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 400),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _LinkRow(
                      label: 'Apple',
                      sub: 'Sign-in linked',
                      icon: Icons.apple_rounded,
                      tone: const Color(0xFF111827),
                      connected: true),
                  _LinkRow(
                      label: 'Google',
                      sub: 'Calendar + contacts',
                      icon: Icons.g_mobiledata_rounded,
                      tone: const Color(0xFF4285F4),
                      connected: true),
                  _LinkRow(
                      label: 'Lufthansa Miles & More',
                      sub: '142,310 miles · Senator',
                      icon: Icons.flight_rounded,
                      tone: const Color(0xFF05164D),
                      connected: true),
                  _LinkRow(
                      label: 'British Airways Executive Club',
                      sub: 'Not connected',
                      icon: Icons.flight_takeoff_rounded,
                      tone: const Color(0xFF075AAA),
                      connected: false),
                  _LinkRow(
                      label: 'Marriott Bonvoy',
                      sub: 'Platinum Elite · 92 nights',
                      icon: Icons.hotel_rounded,
                      tone: const Color(0xFF1F2937),
                      connected: true),
                  _LinkRow(
                      label: 'Stripe',
                      sub: 'Default payment method',
                      icon: Icons.credit_card_rounded,
                      tone: const Color(0xFF635BFF),
                      connected: true),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Integrations', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 440),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _NavRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Calendar sync',
                      sub: 'Google + Apple',
                      onTap: () {}),
                  _NavRow(
                      icon: Icons.email_rounded,
                      label: 'Email parsing',
                      sub: 'Auto-detect bookings',
                      onTap: () {}),
                  _NavRow(
                      icon: Icons.contacts_rounded,
                      label: 'Contacts',
                      sub: '184 synced',
                      onTap: () => context.push('/social')),
                  _NavRow(
                      icon: Icons.sim_card_rounded,
                      label: 'eSIM provider',
                      sub: 'Airalo',
                      onTap: () => context.push('/multi-currency')),
                  _NavRow(
                      icon: Icons.wallet_rounded,
                      label: 'Apple Wallet',
                      sub: 'Push 12 passes',
                      onTap: () => context.push('/wallet')),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Billing & subscription', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 480),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GlobeID Plus',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37)
                              .withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                        child: const Text('ACTIVE',
                            style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Renews 14 Mar · €11.99/mo',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65))),
                  const SizedBox(height: AppTokens.space4),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Manage plan')),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () => context.push('/analytics'),
                          child: const Text('See receipts')),
                    ),
                  ]),
                  const SizedBox(height: AppTokens.space2),
                  _NavRow(
                      icon: Icons.payments_rounded,
                      label: 'Payment methods',
                      sub: 'Visa •• 4242 + 2 more',
                      onTap: () => context.push('/wallet')),
                  _NavRow(
                      icon: Icons.local_atm_rounded,
                      label: 'Tax invoices',
                      sub: 'Quarterly summaries',
                      onTap: () => context.push('/analytics')),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Support', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 520),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              child: Column(
                children: [
                  _NavRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help center',
                      onTap: () {}),
                  _NavRow(
                      icon: Icons.chat_rounded,
                      label: 'Contact concierge',
                      sub: '24/7 · avg reply 2 min',
                      onTap: () => context.push('/copilot')),
                  _NavRow(
                      icon: Icons.bug_report_rounded,
                      label: 'Report an issue',
                      onTap: () {}),
                  _NavRow(
                      icon: Icons.policy_rounded,
                      label: 'Privacy & terms',
                      onTap: () {}),
                  _NavRow(
                      icon: Icons.info_outline_rounded,
                      label: 'About GlobeID',
                      sub: 'v1.0.0 · build 2026.05',
                      onTap: () {}),
                ],
              ),
            ),
          ),

          const SectionHeader(title: 'Danger zone', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 560),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.space2, horizontal: AppTokens.space4),
              borderColor: const Color(0xFFE11D48).withValues(alpha: 0.30),
              child: Column(
                children: [
                  _DangerRow(
                      icon: Icons.lock_reset_rounded,
                      label: 'Sign out everywhere',
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        AppToast.show(context,
                            title: 'Signed out',
                            message: 'All other devices revoked',
                            tone: AppToastTone.warning);
                      }),
                  _DangerRow(
                      icon: Icons.cloud_download_rounded,
                      label: 'Export my data',
                      onTap: () {}),
                  _DangerRow(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete account',
                      destructive: true,
                      onTap: () {}),
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

// ── Mega-screen helper widgets ────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: t.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.labelSmall?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.label,
    required this.sub,
    this.isCurrent = false,
  });
  final IconData icon;
  final String label;
  final String sub;
  final bool isCurrent;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: t.colorScheme.onSurface.withValues(alpha: 0.78)),
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
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: const Text('THIS',
                  style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6)),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.sub,
    required this.icon,
    required this.tone,
    required this.connected,
  });
  final String label;
  final String sub;
  final IconData icon;
  final Color tone;
  final bool connected;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Pressable(
      onTap: () => HapticFeedback.lightImpact(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.16),
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
                          color: t.colorScheme.onSurface
                              .withValues(alpha: 0.60))),
                ],
              ),
            ),
            Switch.adaptive(
              value: connected,
              onChanged: (_) => HapticFeedback.lightImpact(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = destructive
        ? const Color(0xFFE11D48)
        : t.colorScheme.onSurface.withValues(alpha: 0.85);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Text(label,
                  style: t.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: color)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.colorScheme.onSurface.withValues(alpha: 0.32)),
          ],
        ),
      ),
    );
  }
}

class _SegmentedThemeMode extends StatelessWidget {
  const _SegmentedThemeMode({required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const modes = [
      (ThemeMode.system, 'Auto', Icons.auto_awesome_rounded),
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        children: [
          for (final m in modes)
            Expanded(
              child: Pressable(
                scale: 0.97,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(m.$1);
                },
                child: AnimatedContainer(
                  duration: AppTokens.durationMd,
                  curve: AppTokens.easeOutSoft,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: m.$1 == value
                        ? LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.8),
                              accent.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.$3,
                          size: 16,
                          color: m.$1 == value
                              ? Colors.white
                              : theme.colorScheme.onSurface),
                      const SizedBox(width: 4),
                      Text(m.$2,
                          style: TextStyle(
                            color: m.$1 == value
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.selected, required this.onPick});
  final String selected;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppTokens.accents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = AppTokens.accents[i];
          final isSelected = a.name == selected;
          return Pressable(
            scale: 0.92,
            onTap: () {
              HapticFeedback.lightImpact();
              onPick(a.name);
            },
            child: AnimatedContainer(
              duration: AppTokens.durationMd,
              curve: AppTokens.easeOutSoft,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [a.shade400, a.shade600],
                ),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? AppTokens.shadowLg(tint: a.shade600)
                    : AppTokens.shadowSm(tint: a.shade600),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _DensityRow extends StatelessWidget {
  const _DensityRow({required this.value, required this.onChanged});
  final AppDensity value;
  final ValueChanged<AppDensity> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const items = [
      (AppDensity.compact, 'Compact'),
      (AppDensity.comfortable, 'Comfortable'),
      (AppDensity.spacious, 'Spacious'),
    ];
    return Wrap(
      spacing: 8,
      children: [
        for (final i in items)
          Pressable(
            scale: 0.96,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(i.$1);
            },
            child: AnimatedContainer(
              duration: AppTokens.durationMd,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: value == i.$1
                    ? accent.withValues(alpha: 0.18)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                border: Border.all(
                  color: value == i.$1
                      ? accent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                i.$2,
                style: TextStyle(
                  color: value == i.$1 ? accent : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.sub,
  });
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  if (sub != null)
                    Text(sub!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55))),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
