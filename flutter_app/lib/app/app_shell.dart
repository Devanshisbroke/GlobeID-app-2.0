import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/lifecycle/lifecycle_provider.dart';
import '../features/security/session_lock_provider.dart';
import '../features/user/user_provider.dart';
import '../features/voice/voice_command_overlay.dart';
import '../features/wallet/wallet_provider.dart';
import '../nexus/nexus_tokens.dart';
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

  // OS 2.0 — five worlds, not six tabs.
  //
  // The previous layout had Home / Identity / Wallet / Travel /
  // Services / Globe split around a centered FAB. Services has been
  // pulled out of the primary dock because (a) it overflowed on
  // Pixel-class viewports, (b) the user explicitly asked for a
  // luxury-OS dock not a generic bottom bar, and (c) the Discover
  // world already exposes service intelligence (hotels, flights,
  // mobility) as rails at the top of the page. Services remains
  // reachable through:
  //   • the dedicated /services deep link
  //   • the FAB long-press command palette
  //   • the Discover atlas service rails
  //   • voice intent ("open services")
  // Globe is gone entirely (see refactor commit).
  static const _tabs = [
    _Tab('/', Icons.cottage_rounded, Icons.cottage_rounded, 'Home',
        BibleTone.foilGold),
    _Tab('/identity', Icons.verified_user_rounded, Icons.verified_user_rounded,
        'Identity', BibleTone.foilGold),
    _Tab(
        '/wallet',
        Icons.account_balance_wallet_rounded,
        Icons.account_balance_wallet_rounded,
        'Wallet',
        BibleTone.treasuryGreen),
    _Tab('/travel', Icons.flight_takeoff_rounded, Icons.flight_takeoff_rounded,
        'Travel', BibleTone.jetCyan),
    _Tab('/discover', Icons.travel_explore_rounded,
        Icons.travel_explore_rounded, 'Discover', BibleTone.equatorTeal),
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
        bottomNavigationBar: _WorldDock(
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
  /// currently active tab. OS 2.0 tab order is Home / Identity /
  /// Wallet / Travel / Discover — each world gets its own contextual
  /// tone palette per bible §4.1.
  Widget _bibleBackdropFor(int activeIndex) {
    switch (activeIndex) {
      case 1: // Identity
        return LivingGradient.identity();
      case 2: // Wallet
        return LivingGradient.wallet();
      case 3: // Travel
        return LivingGradient.travel();
      case 4:
        // Discover — equator-teal palette inherited from the
        // retired Globe tab so the visual continuity remains, but
        // the gradient now anchors a typographic surface, not a
        // 3D sphere.
        return LivingGradient.globe();
      case 0: // Home
      default:
        return LivingGradient.travel();
    }
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.activeIcon, this.label, this.tone);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Tone of the world this tab represents. Drives the active
  /// capsule's tint, halo, and label colour so each world feels
  /// emotionally distinct in the dock — foilGold for Home/Identity,
  /// treasuryGreen for Wallet, jetCyan for Travel, equatorTeal for
  /// Discover.
  final Color tone;
}

/// OS 2.0 floating spatial dock.
///
/// Replaces the previous full-width frosted bottom-nav bar with a
/// **floating capsule** that sits inset 16 dp from each screen edge.
/// Inside the capsule:
///
///   • Inactive tabs are pure 24-pt icons.
///   • The active tab expands into an iOS-18-Photos-style capsule
///     showing icon + label inline, tinted with that world's
///     bible tone (foilGold / treasuryGreen / jetCyan / equatorTeal).
///   • A gently-breathing ambient halo glows behind the active
///     capsule so the active world feels emotionally "lit".
///   • A 6 dp FAB gap is reserved in the middle of the capsule so
///     the centre-docked spotlight FAB nests cleanly into the dock,
///     rather than overlapping it.
///
/// The whole capsule is rendered as a `LiquidGlass` chrome surface
/// (saturate-then-blur material) so it inherits the same Apple-grade
/// material treatment used everywhere else in the app.
class _WorldDock extends StatefulWidget {
  const _WorldDock({
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
  State<_WorldDock> createState() => _WorldDockState();
}

class _WorldDockState extends State<_WorldDock>
    with SingleTickerProviderStateMixin {
  // Slow ambient breath that pulses the active capsule's halo. ~4 s
  // period reads as "alive" without distracting.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // The dock is full-width visually (a single rounded capsule), but
    // sits inset from each screen edge. Outer margin is wrapped here.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          0,
          AppTokens.space4,
          AppTokens.space2,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          // Nexus rule: depth via contrast + hairline, NOT BackdropFilter.
          // Flat N.surface substrate with a 0.5pt hairline border reads
          // floating against the OLED canvas without the every-frame
          // blur cost.
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: N.surface,
              border: Border.all(
                color: N.hairline,
                width: N.strokeHair,
              ),
            ),
            child: LayoutBuilder(
              builder: (_, c) {
                return _DockRow(
                  tabs: widget.tabs,
                  activeIndex: widget.activeIndex,
                  width: c.maxWidth,
                  isDark: isDark,
                  breath: _breath,
                  onTap: widget.onTap,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out the tab row inside the dock capsule with an animated
/// expanded-capsule active state.
class _DockRow extends StatelessWidget {
  const _DockRow({
    required this.tabs,
    required this.activeIndex,
    required this.width,
    required this.isDark,
    required this.breath,
    required this.onTap,
  });

  final List<_Tab> tabs;
  final int activeIndex;
  final double width;
  final bool isDark;
  final Animation<double> breath;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Reserve a centre gap so the docked FAB has room to nest into
    // the capsule without colliding with tab buttons. 80 dp matches
    // the FAB outer halo diameter.
    const fabGap = 80.0;
    final centerSlot = tabs.length ~/ 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(tabs.length + 1, (i) {
          if (i == centerSlot) {
            return const SizedBox(width: fabGap);
          }
          final tabIndex = i > centerSlot ? i - 1 : i;
          final tab = tabs[tabIndex];
          final selected = activeIndex == tabIndex;
          return _DockTab(
            tab: tab,
            selected: selected,
            isDark: isDark,
            breath: breath,
            onTap: () => onTap(tabIndex),
          );
        }),
      ),
    );
  }
}

/// Single dock tab. Inactive = icon. Active = expanded capsule with
/// icon + label inline, tinted with the world's bible tone, behind
/// an ambient breathing halo.
class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.tab,
    required this.selected,
    required this.isDark,
    required this.breath,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final bool isDark;
  final Animation<double> breath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = tab.tone;
    final inactive = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        // Active capsule expands; inactive collapses to icon-only.
        padding: EdgeInsets.symmetric(
          horizontal: selected ? AppTokens.space3 : AppTokens.space2,
          vertical: AppTokens.space2,
        ),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tone.withValues(alpha: 0.28),
                    tone.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(
                  color: tone.withValues(alpha: 0.45),
                  width: 0.7,
                ),
                boxShadow: [
                  // Ambient breathing halo that "lights" the active
                  // world. Reads as an emotional presence cue.
                  BoxShadow(
                    color: tone.withValues(
                      alpha: 0.22 + 0.10 * breath.value,
                    ),
                    blurRadius: 18 + 6 * breath.value,
                    spreadRadius: 0.5,
                  ),
                ],
              )
            : null,
        child: AnimatedBuilder(
          animation: breath,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 22,
                  color: selected ? tone : inactive,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            tab.label,
                            style: TextStyle(
                              color: tone,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// _NavItem (legacy 6-tab column-layout item) was removed when the
// dock was rebuilt as a floating spatial capsule with an expanded
// active capsule. See _DockTab for the new implementation.

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
    final padding = MediaQuery.of(context).viewInsets;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTokens.radius2xl),
      ),
      // Nexus rule: flat N.surface substrate with a hairline border —
      // no BackdropFilter, no every-frame blur.
      child: Container(
        padding: EdgeInsets.only(
          left: AppTokens.space4,
          right: AppTokens.space4,
          top: AppTokens.space3,
          bottom: padding.bottom + AppTokens.space5,
        ),
        decoration: const BoxDecoration(
          color: N.surface,
          border: Border(
            top: BorderSide(color: N.hairline, width: N.strokeHair),
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
    );
  }
}
