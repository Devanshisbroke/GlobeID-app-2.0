import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/lifecycle/lifecycle_provider.dart';
import '../features/user/user_provider.dart';
import '../features/wallet/wallet_provider.dart';
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
    if (state == AppLifecycleState.resumed) {
      _hydrate();
    }
  }

  void _hydrate() {
    ref.read(userProvider.notifier).hydrate();
    ref.read(walletProvider.notifier).hydrate();
    ref.read(lifecycleProvider.notifier).hydrate();
  }

  static const _tabs = [
    _Tab('/', Icons.cottage_outlined, Icons.cottage_rounded, 'Home'),
    _Tab('/wallet', Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded, 'Wallet'),
    _Tab('/travel', Icons.flight_takeoff_outlined, Icons.flight_takeoff_rounded,
        'Travel'),
    _Tab('/services', Icons.dashboard_outlined, Icons.dashboard_rounded,
        'Services'),
    _Tab('/map', Icons.public_outlined, Icons.public_rounded, 'Globe'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final activeIndex = _activeTabIndex(loc);
    final theme = Theme.of(context);
    final glass = theme.extension<GlassExtension>()!;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            const _Backdrop(),
            Positioned.fill(child: widget.child),
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
}

class _Tab {
  const _Tab(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          AppTokens.canvasDark,
                          Color(0xFF080B15),
                          Color(0xFF03050B),
                        ]
                      : const [
                          AppTokens.canvasLight,
                          Color(0xFFEFF3FA),
                          Color(0xFFE5ECF6),
                        ],
                ),
              ),
            ),
          ),
          // Hero radial bloom — accent-tinted, fades into the canvas.
          Positioned(
            top: -120,
            right: -80,
            child: _Bloom(
              size: 360,
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -100,
            child: _Bloom(
              size: 420,
              color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
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
        height: 72,
        child: LayoutBuilder(builder: (_, c) {
          final fabGap = 64.0;
          final usable = c.maxWidth - fabGap;
          final slot = usable / tabs.length;
          // Compute active pill x.
          final visualIndex =
              activeIndex < 2 ? activeIndex : activeIndex + 1; // skip FAB slot
          final slotForPill = (c.maxWidth) / (tabs.length + 1);
          final pillX = slotForPill * visualIndex;
          return Stack(
            children: [
              // Morphing pill indicator.
              AnimatedPositioned(
                duration: AppTokens.durationMd,
                curve: AppTokens.easeOutSoft,
                left: pillX + slotForPill * 0.18,
                top: 14,
                child: Container(
                  width: slotForPill * 0.64,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 0.6,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(tabs.length + 1, (i) {
                  if (i == 2) return SizedBox(width: fabGap);
                  final tabIndex = i > 2 ? i - 1 : i;
                  final tab = tabs[tabIndex];
                  final selected = activeIndex == tabIndex;
                  return SizedBox(
                    width: slot,
                    child: _NavItem(
                      tab: tab,
                      selected: selected,
                      accent: accent,
                      onTap: () => onTap(tabIndex),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );

    final body = Container(
      decoration: BoxDecoration(
        color: reduce
            ? glass.surface.withValues(alpha: 0.96)
            : (isDark
                ? Colors.black.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.62)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: navContent,
    );

    if (reduce) return body;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: body,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final Color accent;
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
        height: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppTokens.durationXs,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                selected ? tab.activeIcon : tab.icon,
                key: ValueKey(selected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.3,
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
    final accent = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_glow.value);
        return SizedBox(
          width: 70,
          height: 70,
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
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30 + 0.20 * t),
                      blurRadius: 24 + 12 * t,
                      spreadRadius: 1 + 2 * t,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_scanner_rounded,
                      size: 30, color: Colors.white),
                ),
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
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _CommandPalette(),
  );
}

class _CommandItem {
  const _CommandItem(this.label, this.path, this.icon, this.tone);
  final String label;
  final String path;
  final IconData icon;
  final Color tone;
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette();
  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _ctrl = TextEditingController();
  String _q = '';

  static const _all = <_CommandItem>[
    _CommandItem('Scan QR / boarding pass', '/scan',
        Icons.qr_code_scanner_rounded, Color(0xFF06B6D4)),
    _CommandItem('Wallet', '/wallet', Icons.account_balance_wallet_rounded,
        Color(0xFF7C3AED)),
    _CommandItem('Multi-currency', '/multi-currency',
        Icons.currency_exchange_rounded, Color(0xFF10B981)),
    _CommandItem(
        'Travel', '/travel', Icons.flight_takeoff_rounded, Color(0xFFEA580C)),
    _CommandItem(
        'Map / Globe', '/map', Icons.public_rounded, Color(0xFF3B82F6)),
    _CommandItem('Identity', '/identity', Icons.verified_user_rounded,
        Color(0xFFF59E0B)),
    _CommandItem(
        'Vault', '/vault', Icons.shield_moon_rounded, Color(0xFFEA580C)),
    _CommandItem(
        'Copilot', '/copilot', Icons.smart_toy_rounded, Color(0xFF059669)),
    _CommandItem(
        'Planner', '/planner', Icons.event_note_rounded, Color(0xFF7C3AED)),
    _CommandItem(
        'Receipt', '/receipt', Icons.receipt_long_rounded, Color(0xFFE11D48)),
    _CommandItem(
        'Analytics', '/analytics', Icons.insights_rounded, Color(0xFF1D4ED8)),
    _CommandItem('Activity feed', '/feed', Icons.dynamic_feed_rounded,
        Color(0xFF06B6D4)),
    _CommandItem(
        'Timeline', '/timeline', Icons.timeline_rounded, Color(0xFF10B981)),
    _CommandItem('Passport book', '/passport-book', Icons.menu_book_rounded,
        Color(0xFFF59E0B)),
    _CommandItem('Kiosk simulator', '/kiosk-sim',
        Icons.face_retouching_natural_rounded, Color(0xFF7C3AED)),
    _CommandItem(
        'Profile', '/profile', Icons.person_rounded, Color(0xFF06B6D4)),
    _CommandItem(
        'Intelligence', '/intelligence', Icons.bolt_rounded, Color(0xFFEAB308)),
    _CommandItem(
        'Explore', '/explore', Icons.travel_explore_rounded, Color(0xFF3B82F6)),
  ];

  List<_CommandItem> get _filtered {
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
                  fillColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4, vertical: 14),
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
                              horizontal: 8, vertical: 10),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusLg),
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
                              child: Text(c.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            Text(c.path,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontFamily: 'monospace',
                                )),
                          ]),
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
