import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/lifecycle/lifecycle_provider.dart';
import '../features/security/session_lock_provider.dart';
import '../features/user/user_provider.dart';
import '../features/voice/voice_command_overlay.dart';
import '../features/wallet/wallet_provider.dart';
import '../widgets/atmosphere_layer.dart';
import '../widgets/aurora_layer.dart';
import '../widgets/bible/bible.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

/// Premium app shell. Edge-to-edge, frosted bottom nav with a
/// morphing pill indicator, animated FAB with pulse-glow, scoped
/// status-bar tint that follows brightness, atmosphere backdrop.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _autoLockNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(sessionLockProvider.notifier);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      lock.markInactive();
    }
    if (state == AppLifecycleState.resumed) {
      _hydrate();
      _evaluateAutoLock();
    }
  }

  void _hydrate() {
    ref.read(userProvider.notifier).hydrate();
    ref.read(walletProvider.notifier).hydrate();
    ref.read(lifecycleProvider.notifier).hydrate();
  }

  Future<void> _evaluateAutoLock() async {
    await ref.read(sessionLockProvider.notifier).evaluateResume();
    final locked = ref.read(sessionLockProvider).locked;
    if (!mounted || !locked || _autoLockNavigating) return;
    _autoLockNavigating = true;
    HapticFeedback.mediumImpact();
    context.go('/lock');
    _autoLockNavigating = false;
  }

  static const _tabs = [
    _Tab('/', Icons.cottage_outlined, Icons.cottage_rounded, 'Home'),
    _Tab(
      '/identity',
      Icons.verified_user_outlined,
      Icons.verified_user_rounded,
      'Identity',
    ),
    _Tab(
      '/wallet',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'Wallet',
    ),
    _Tab(
      '/travel',
      Icons.flight_takeoff_outlined,
      Icons.flight_takeoff_rounded,
      'Travel',
    ),
    _Tab(
      '/services',
      Icons.dashboard_outlined,
      Icons.dashboard_rounded,
      'Services',
    ),
    // The Globe tab has been retired — the heavy 3D-globe / 2D-OSM
    // surface was removed app-wide. Its slot is now the cinematic
    // Discover atlas: a typographic destination intelligence feed
    // with no geographic visualisation. The old /map deep link is
    // preserved by the router as a redirect to /discover.
    _Tab('/discover', Icons.travel_explore_outlined,
        Icons.travel_explore_rounded, 'Discover'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final activeIndex = _activeTabIndex(loc);
    final theme = Theme.of(context);
    final glass = GlassExtension.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: AtmosphereLayer()),
            // Bible §4.1 — every screen has a slowly breathing
            // 4-stop gradient. The flavor follows the active tab so
            // each surface inherits its bible-mandated emotional
            // palette (Identity garnet+gold, Wallet treasury green,
            // Travel jet cyan, Globe equator teal). Tones are held
            // under 8 % alpha so the substrate dominates and content
            // remains fully readable.
            Positioned.fill(
              child: IgnorePointer(
                child: _bibleBackdropFor(activeIndex),
              ),
            ),
            // Aurora colour-field layer adds cinematic depth without
            // taxing the GPU — single ticker, blendMode plus.
            Positioned.fill(
              child: IgnorePointer(
                child: AuroraLayer(
                  intensity: glass.reduceTransparency ? 0.0 : 0.85,
                ),
              ),
            ),
            Positioned.fill(child: widget.child),
            // Bible §9.2 — chrome (identity pill, inbox bell, theme
            // cycler) is now embedded *inside each screen's*
            // collapsing top bar (BibleTopBar.actions), not as an
            // absolute floating row that used to clip behind content
            // on narrow Android viewports. Voice orb still floats
            // bottom-left as the persistent assistant entry-point.
            Positioned(
              bottom: 96,
              left: 16,
              child: const VoiceCommandOrb(),
            ),
          ],
        ),
        floatingActionButton: _ScanFab(
          onPressed: () => context.push('/scan'),
          onLongPress: () => _showCommandPalette(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _FrostedNav(
          tabs: _tabs,
          activeIndex: activeIndex,
          glass: glass,
          isDark: isDark,
          onTap: (i) {
            HapticFeedback.selectionClick();
            context.go(_tabs[i].path);
          },
        ),
      ),
    );
  }

  int _activeTabIndex(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      final p = _tabs[i].path;
      if (p == '/' && location == '/') return i;
      if (p != '/' && location.startsWith(p)) return i;
    }
    return 0;
  }

  /// Returns the bible-mandated [LivingGradient] flavor for the
  /// currently active tab. The tab order is Home / Identity / Wallet
  /// / Travel / Services / Discover — each tab gets its own contextual
  /// tone palette per bible §4.1.
  Widget _bibleBackdropFor(int activeIndex) {
    switch (activeIndex) {
      case 1:
        return LivingGradient.identity();
      case 2:
        return LivingGradient.wallet();
      case 5:
        // Discover tab — equator-teal palette inherited from the
        // retired Globe tab so the visual continuity remains, but
        // the gradient is now anchored to a typographic surface,
        // not a 3D sphere.
        return LivingGradient.globe();
      case 0:
      case 3:
      case 4:
      default:
        return LivingGradient.travel();
    }
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _FrostedNav extends StatelessWidget {
  const _FrostedNav({
    required this.tabs,
    required this.activeIndex,
    required this.glass,
    required this.isDark,
    required this.onTap,
  });

  final List<_Tab> tabs;
  final int activeIndex;
  final GlassExtension glass;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final reduce = glass.reduceTransparency;

    final navContent = SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: LayoutBuilder(
          builder: (_, c) {
            // Clamp every responsive calc — on extreme widths (e.g. 0
            // during initial layout, or split-screen ≪ 64 px) negative
            // BoxConstraints would surface as a red runtime crash.
            const fabGap = 84.0;
            const sidePad = 6.0;
            final maxWidth = c.maxWidth.isFinite ? c.maxWidth : 0.0;
            // Symmetric split: half the tabs on each side of the FAB.
            // For an even count this gives a perfect 3-FAB-3 layout.
            final tabCount = tabs.length;
            final centerSlot = tabCount ~/ 2;
            final usable =
                (maxWidth - fabGap - sidePad * 2).clamp(0.0, double.infinity);
            final slot = tabCount == 0 ? 0.0 : usable / tabCount;
            // Pill must never exceed the slot it lives in or it spills
            // over the neighbours and looks broken on narrow phones.
            final pillWidth = math.max(
              28.0,
              math.min(slot - 4.0, slot * 0.78),
            );
            final pillHeight = slot < 56 ? 44.0 : 48.0;
            final pillTop = (76 - pillHeight) / 2;
            final compact = slot < 56;
            final activeBase = sidePad +
                (activeIndex < centerSlot
                    ? activeIndex * slot
                    : activeIndex * slot + fabGap);
            return Stack(
              children: [
                // Morphing pill indicator — gradient + glow with
                // brand-tinted ring; clamped to its slot so it never
                // straddles a neighbour.
                AnimatedPositioned(
                  duration: AppTokens.durationLg,
                  curve: AppTokens.easeOutSoft,
                  left: activeBase + (slot - pillWidth) / 2,
                  top: pillTop,
                  child: Container(
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.30),
                          accent.withValues(alpha: 0.10),
                        ],
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.42),
                        width: 0.7,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 20,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: sidePad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(tabCount + 1, (i) {
                      if (i == centerSlot) {
                        return const SizedBox(width: fabGap);
                      }
                      final tabIndex = i > centerSlot ? i - 1 : i;
                      final tab = tabs[tabIndex];
                      final selected = activeIndex == tabIndex;
                      return SizedBox(
                        width: slot,
                        child: _NavItem(
                          tab: tab,
                          selected: selected,
                          accent: accent,
                          compact: compact,
                          onTap: () => onTap(tabIndex),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final body = Stack(
      children: [
        // Tint layer.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: reduce
                  ? glass.surface.withValues(alpha: 0.96)
                  : (isDark
                      ? Colors.black.withValues(alpha: 0.36)
                      : Colors.white.withValues(alpha: 0.55)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ),
        // Specular top edge — 0.5-pt glint along the top of the
        // chrome that catches light and gives the bar perceived
        // thickness. Apple uses this on every iOS material chrome.
        if (!reduce)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ]
                      : [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.50),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 0.30, 0.70, 1.0],
                ),
              ),
            ),
          ),
        navContent,
      ],
    );

    if (reduce) return body;
    return ClipRect(
      // Apple-grade chrome material: saturation 1.55× *then* blur σ
      // 28. The two-layer ImageFilter is the iOS-17 signature — it
      // saturates content behind the bar before softening it, so
      // colour from the wallpaper / hero card pops. Vanilla blur
      // alone produces the cheap milky look this avoids.
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          inner: _navSaturateMatrix(
            1.55,
            isDark ? 0.88 : 1.10,
          ),
        ),
        child: body,
      ),
    );
  }
}

/// Saturation+brightness colour matrix for the bottom-nav backdrop
/// filter. BT.709 luminance coefficients (same as Safari).
ColorFilter _navSaturateMatrix(double sat, double bri) {
  final invSat = 1 - sat;
  final r = 0.2126 * invSat;
  final g = 0.7152 * invSat;
  final b = 0.0722 * invSat;
  return ColorFilter.matrix(<double>[
    (r + sat) * bri, g * bri, b * bri, 0, 0,
    r * bri, (g + sat) * bri, b * bri, 0, 0,
    r * bri, g * bri, (b + sat) * bri, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? accent
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: SizedBox(
        height: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppTokens.durationSm,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.86, end: 1.0).animate(a),
                  child: c,
                ),
              ),
              child: Container(
                key: ValueKey(selected),
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                alignment: Alignment.center,
                decoration: selected
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.55),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  color: color,
                  size: compact ? 22 : 24,
                ),
              ),
            ),
            SizedBox(height: compact ? 3 : 4),
            AnimatedDefaultTextStyle(
              duration: AppTokens.durationSm,
              curve: AppTokens.easeOutSoft,
              style: TextStyle(
                fontSize: compact ? 9.4 : 10.4,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.3,
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFab extends StatefulWidget {
  const _ScanFab({required this.onPressed, required this.onLongPress});
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab>
    with SingleTickerProviderStateMixin {
  late final _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_glow.value);
        return SizedBox(
          width: 72,
          height: 72,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                widget.onLongPress();
              },
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer ambient halo — a soft accent bloom that
                  // breathes, sized larger than the button so the
                  // FAB reads as a Dynamic-Island-grade live element
                  // rather than a flat circle.
                  Positioned(
                    width: 96 + 8 * t,
                    height: 96 + 8 * t,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.30 + 0.15 * t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accent.withValues(alpha: 0.55),
                                accent.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Body.
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(accent, Colors.white, 0.16)!,
                          accent,
                          Color.lerp(accent, Colors.black, 0.10)!,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        // Cinematic drop.
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35 + 0.15 * t),
                          blurRadius: 26 + 12 * t,
                          spreadRadius: 1 + 2 * t,
                          offset: const Offset(0, 10),
                        ),
                        // Tight inner ring shadow.
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.22 : 0.30,
                        ),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          // Top specular cap — simulates light
                          // catching the lacquered top of the
                          // sphere, the iOS Live Activity touch.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 28,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.45),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 30,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Long-press the FAB to open this premium command palette. Provides
/// instant navigation to common destinations + scoped actions.
void _showCommandPalette(BuildContext context) {
  // Delegates to the full CommandPalette overlay in
  // features/home/command_palette.dart.
  // Imported lazily to avoid a circular dependency with the shell.
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _LegacyCommandPalette(),
  );
}

/// Lean fallback palette kept for backward compat — the new one
/// lives in [CommandPalette] (features/home/command_palette.dart)
/// and is invoked via [CommandPalette.show(context)].
class _LegacyCommandPalette extends StatefulWidget {
  const _LegacyCommandPalette();
  @override
  State<_LegacyCommandPalette> createState() => _LegacyCommandPaletteState();
}

class _LegacyCommandPaletteState extends State<_LegacyCommandPalette> {
  final _ctrl = TextEditingController();
  String _q = '';

  static const _all =
      <({String label, String path, IconData icon, Color tone})>[
    (
      label: 'Scan QR / boarding pass',
      path: '/scan',
      icon: Icons.qr_code_scanner_rounded,
      tone: Color(0xFF06B6D4)
    ),
    (
      label: 'Wallet',
      path: '/wallet',
      icon: Icons.account_balance_wallet_rounded,
      tone: Color(0xFF7C3AED)
    ),
    (
      label: 'Multi-currency',
      path: '/multi-currency',
      icon: Icons.currency_exchange_rounded,
      tone: Color(0xFF10B981)
    ),
    (
      label: 'Travel',
      path: '/travel',
      icon: Icons.flight_takeoff_rounded,
      tone: Color(0xFFEA580C)
    ),
    (
      label: 'Discover',
      path: '/discover',
      icon: Icons.travel_explore_rounded,
      tone: Color(0xFF06B6D4)
    ),
    (
      label: 'Identity',
      path: '/identity',
      icon: Icons.verified_user_rounded,
      tone: Color(0xFFF59E0B)
    ),
    (
      label: 'Vault',
      path: '/vault',
      icon: Icons.shield_moon_rounded,
      tone: Color(0xFFEA580C)
    ),
    (
      label: 'Copilot',
      path: '/copilot',
      icon: Icons.smart_toy_rounded,
      tone: Color(0xFF059669)
    ),
    (
      label: 'Planner',
      path: '/planner',
      icon: Icons.event_note_rounded,
      tone: Color(0xFF7C3AED)
    ),
    (
      label: 'Travel OS',
      path: '/travel-os',
      icon: Icons.hub_rounded,
      tone: Color(0xFF8B5CF6)
    ),
    (
      label: 'Analytics',
      path: '/analytics',
      icon: Icons.insights_rounded,
      tone: Color(0xFF1D4ED8)
    ),
    (
      label: 'Passport book',
      path: '/passport-book',
      icon: Icons.menu_book_rounded,
      tone: Color(0xFFF59E0B)
    ),
    (
      label: 'Intelligence',
      path: '/intelligence',
      icon: Icons.bolt_rounded,
      tone: Color(0xFFEAB308)
    ),
    (
      label: 'Settings',
      path: '/settings',
      icon: Icons.tune_rounded,
      tone: Color(0xFF6366F1)
    ),
    (
      label: 'Inbox',
      path: '/inbox',
      icon: Icons.notifications_rounded,
      tone: Color(0xFFE11D48)
    ),
    (
      label: 'Emergency',
      path: '/emergency',
      icon: Icons.emergency_rounded,
      tone: Color(0xFFEF4444)
    ),
    (
      label: 'Phrasebook',
      path: '/phrasebook',
      icon: Icons.translate_rounded,
      tone: Color(0xFF06B6D4)
    ),
    (
      label: 'Discover',
      path: '/discover',
      icon: Icons.travel_explore_rounded,
      tone: Color(0xFF06B6D4)
    ),
    (
      label: 'Profile',
      path: '/profile',
      icon: Icons.person_rounded,
      tone: Color(0xFF06B6D4)
    ),
  ];

  List<({String label, String path, IconData icon, Color tone})> get _filtered {
    if (_q.trim().isEmpty) return _all;
    final lq = _q.toLowerCase();
    return _all.where((c) => c.label.toLowerCase().contains(lq)).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final padding = MediaQuery.of(context).viewInsets;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTokens.radius2xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: AppTokens.space4,
            right: AppTokens.space4,
            top: AppTokens.space3,
            bottom: padding.bottom + AppTokens.space5,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Type a command or destination…',
                  prefixIcon: const Icon(Icons.bolt_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.06,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          context.push(c.path);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.radiusLg,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      c.tone.withValues(alpha: 0.32),
                                      c.tone.withValues(alpha: 0.10),
                                    ],
                                  ),
                                ),
                                child: Icon(c.icon, color: c.tone, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                c.path,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
