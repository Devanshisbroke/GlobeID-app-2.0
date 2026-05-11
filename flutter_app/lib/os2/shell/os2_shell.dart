import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../os2_tokens.dart';
import 'os2_dock.dart';

/// OS 2.0 — Shell.
///
/// Replaces `AppShell` for the six world routes. Renders the active
/// world's child in a portal-style stack with:
///   • the OLED canvas as the bottom layer;
///   • an ambient world-tone halo bleeding from the top edge (so the
///     viewer reads "you are in the Wallet world" before parsing any
///     copy);
///   • the active child;
///   • the floating spatial dock at the bottom, with the dock's tone
///     synced to the active world.
///
/// Status bar is auto-set to the canvas tone so the entire screen
/// reads as a single OLED slab.
class Os2Shell extends StatelessWidget {
  const Os2Shell({super.key, required this.child});

  final Widget child;

  Os2World _activeWorld(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (final w in Os2World.values) {
      if (w.route == location ||
          (w.route != '/' && location.startsWith(w.route))) {
        return w;
      }
    }
    return Os2World.pulse;
  }

  void _navigate(BuildContext context, Os2World w) {
    final current = _activeWorld(context);
    if (current == w) return;
    context.go(w.route);
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeWorld(context);
    final tone = active.tone;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Os2.canvas,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Os2.canvas,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Os2.canvas,
        extendBody: true,
        body: Stack(
          children: [
            // World-tone halo (top vignette).
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: Os2.mCruise,
                  curve: Os2.cTakeoff,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -1.3),
                      radius: 1.0,
                      colors: [
                        tone.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Active world.
            Positioned.fill(child: child),
          ],
        ),
        bottomNavigationBar: Os2Dock(
          active: active,
          onSelect: (w) => _navigate(context, w),
        ),
      ),
    );
  }
}
