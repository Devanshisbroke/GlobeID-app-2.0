// Bible §9.2 — every screen embeds the GlobeID chrome (identity
// pill, inbox bell, theme cycler) inside its own top bar instead of
// the absolute-positioned floating row that used to clip behind
// content on narrow Android viewports.
//
// `appChromeActions(ref)` returns the chrome row as a list of
// widgets ready to drop into [BibleTopBar.actions]. Screens can
// hide the identity pill on the identity tab itself by passing
// `showIdentity: false`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/app_tokens.dart';
import '../features/inbox/inbox_provider.dart';
import '../features/score/score_provider.dart';
import '../features/settings/theme_prefs_provider.dart';
import '../nexus/nexus_tokens.dart';
import 'pressable.dart';

/// Returns the standard right-aligned chrome (identity quick-pill,
/// inbox bell, theme cycler) as a list of widgets ready for any
/// [BibleTopBar.actions] slot.
List<Widget> appChromeActions(
  BuildContext context, {
  bool showIdentity = true,
}) {
  return [
    if (showIdentity) const IdentityQuickPill(),
    const InboxBellAction(),
    const ThemeCyclerAction(),
  ];
}

/// Live identity score + tier chip. Tap → /identity. Long-press →
/// /passport-book.
class IdentityQuickPill extends ConsumerWidget {
  const IdentityQuickPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scoreAsync = ref.watch(scoreProvider);

    final score = scoreAsync.maybeWhen(
      data: (s) => s.score,
      orElse: () => null,
    );
    final tier = scoreAsync.maybeWhen(
      data: (s) => s.tier,
      orElse: () => 0,
    );

    final tierColor = switch (tier) {
      >= 3 => const Color(0xFFD4AF37),
      2 => const Color(0xFF8B5CF6),
      1 => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface.withValues(alpha: 0.45),
    };
    final tierLabel = switch (tier) {
      >= 3 => 'Elite',
      2 => 'Plus',
      1 => 'Std',
      _ => '—',
    };

    return Tooltip(
      message:
          'Identity ${score ?? '—'} · $tierLabel · tap for vault, hold for stamps',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/identity');
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            context.push('/passport-book');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            // Nexus: flat N.surface + hairline, no BackdropFilter blur.
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: N.surface,
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.45),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          tierColor,
                          tierColor.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    score?.toString() ?? '—',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tierLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Notification bell with unread badge.
class InboxBellAction extends ConsumerWidget {
  const InboxBellAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = GlassExtension.of(context);
    final unread = ref.watch(inboxUnreadProvider);

    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        GoRouter.of(context).push('/inbox');
      },
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: glass.reduceTransparency
              ? glass.surface.withValues(alpha: 0.94)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.58)),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            width: 0.6,
          ),
          boxShadow: AppTokens.shadowSm(),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 17,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
            ),
            if (unread > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.2,
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

/// Theme cycler: tap → cycle modes, long-press → accent picker.
class ThemeCyclerAction extends ConsumerWidget {
  const ThemeCyclerAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePrefsProvider);
    final theme = Theme.of(context);

    final modeIcon = switch (prefs.themeMode) {
      ThemeMode.system => Icons.contrast_rounded,
      ThemeMode.light => Icons.wb_sunny_rounded,
      ThemeMode.dark => Icons.nightlight_round,
    };
    final tooltip = switch (prefs.themeMode) {
      ThemeMode.system => 'Auto theme · tap to switch · hold for accent',
      ThemeMode.light => 'Light mode · tap to switch · hold for accent',
      ThemeMode.dark => 'Dark mode · tap to switch · hold for accent',
    };

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            final next = switch (prefs.themeMode) {
              ThemeMode.system => ThemeMode.light,
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
            };
            ref.read(themePrefsProvider.notifier).setThemeMode(next);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showAccentPicker(context, ref);
          },
          child: ClipOval(
            // Nexus: flat N.surface + hairline.
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: N.surface,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.32),
                  width: 0.6,
                ),
              ),
              child: AnimatedSwitcher(
                duration: AppTokens.durationSm,
                switchInCurve: AppTokens.easeOutSoft,
                child: Icon(
                  modeIcon,
                  key: ValueKey(prefs.themeMode),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the accent-picker bottom sheet.
void showAccentPicker(BuildContext context, WidgetRef ref) {
  final prefs = ref.read(themePrefsProvider);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetCtx) {
      return _AccentPickerSheet(
        current: prefs.accent,
        onPick: (name) {
          HapticFeedback.selectionClick();
          ref.read(themePrefsProvider.notifier).setAccent(name);
        },
      );
    },
  );
}

class _AccentPickerSheet extends StatelessWidget {
  const _AccentPickerSheet({required this.current, required this.onPick});
  final String current;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radius2xl),
        ),
        // Nexus: flat N.surface + hairline.
        child: Container(
          decoration: const BoxDecoration(
            color: N.surface,
            border: Border(
              top: BorderSide(color: N.hairline, width: N.strokeHair),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space5,
            AppTokens.space4,
            AppTokens.space5,
            AppTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTokens.space4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
              ),
              Text(
                'Accent',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to set the brand colour app-wide',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Wrap(
                spacing: AppTokens.space3,
                runSpacing: AppTokens.space3,
                children: AppTokens.accents.map((a) {
                  final selected = a.name == current;
                  return GestureDetector(
                    onTap: () {
                      onPick(a.name);
                      Navigator.of(context).maybePop();
                    },
                    child: AnimatedContainer(
                      duration: AppTokens.durationSm,
                      curve: AppTokens.easeOutSoft,
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: a.heroGradient,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.30),
                          width: selected ? 2.4 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: a.primary.withValues(alpha: 0.36),
                            blurRadius: selected ? 14 : 6,
                            spreadRadius: selected ? 1 : 0,
                          ),
                        ],
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
