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
        ],
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
  const _NavRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
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
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
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
