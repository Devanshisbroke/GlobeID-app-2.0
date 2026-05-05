import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../settings/theme_prefs_provider.dart';
import '../user/user_provider.dart';

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
        children: [
          GlassSurface(
            child: Row(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                    child: user.profile.avatarUrl.isEmpty
                        ? Icon(Icons.person_rounded,
                            color: theme.colorScheme.primary, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.profile.name,
                          style: theme.textTheme.titleLarge),
                      Text(user.profile.passportNumber.isNotEmpty
                          ? 'Passport ${user.profile.passportNumber}'
                          : 'No passport on file'),
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
          const SectionHeader(title: 'Theme', dense: true),
          GlassSurface(
            child: Column(
              children: [
                _row(
                  context,
                  Icons.brightness_6_rounded,
                  'Theme mode',
                  prefs.themeMode.name,
                  onTap: () => _showThemeMode(context, ref),
                ),
                _row(
                  context,
                  Icons.palette_rounded,
                  'Accent',
                  prefs.accent,
                  onTap: () => _showAccent(context, ref),
                ),
                _switchRow(
                  context,
                  Icons.contrast_rounded,
                  'High contrast',
                  prefs.highContrast,
                  (_) => ref
                      .read(themePrefsProvider.notifier)
                      .toggleHighContrast(),
                ),
                _switchRow(
                  context,
                  Icons.blur_off_rounded,
                  'Reduce transparency',
                  prefs.reduceTransparency,
                  (_) => ref
                      .read(themePrefsProvider.notifier)
                      .toggleReduceTransparency(),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Account', dense: true),
          GlassSurface(
            child: Column(children: [
              _row(context, Icons.shield_moon_rounded, 'Vault', '',
                  onTap: () => context.push('/vault')),
              _row(context, Icons.bar_chart_rounded, 'Analytics', '',
                  onTap: () => context.push('/analytics')),
              _row(context, Icons.smart_toy_rounded, 'Copilot', '',
                  onTap: () => context.push('/copilot')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext c, IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    final theme = Theme.of(c);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppTokens.space3),
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            if (value.isNotEmpty)
              Text(value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(BuildContext c, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    final theme = Theme.of(c);
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

  void _showThemeMode(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in ThemeMode.values)
              ListTile(
                title: Text(m.name),
                onTap: () {
                  ref.read(themePrefsProvider.notifier).setThemeMode(m);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAccent(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(AppTokens.space5),
          crossAxisCount: 4,
          shrinkWrap: true,
          children: [
            for (final a in AppTokens.accents)
              GestureDetector(
                onTap: () {
                  ref.read(themePrefsProvider.notifier).setAccent(a.name);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [a.shade400, a.shade600],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
