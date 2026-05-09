import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/globe_renderer.dart';
import '../../widgets/pressable.dart';

/// Compact inline globe widget for the home screen.
///
/// Displays the user's next trip route as a glowing arc on a small
/// auto-rotating globe. Tappable → navigates to /globe-cinematic.
/// Purely decorative and informational — no interaction beyond tap.
class HomeMiniGlobe extends StatelessWidget {
  const HomeMiniGlobe({
    super.key,
    this.height = 180,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.routeLabel = 'Next trip',
    this.routeColor,
  });

  final double height;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final String routeLabel;
  final Color? routeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = routeColor ?? theme.colorScheme.primary;

    final routes = <GlobeRoute>[];
    if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
      routes.add(GlobeRoute(
        fromLat: fromLat!,
        fromLng: fromLng!,
        toLat: toLat!,
        toLng: toLng!,
        color: accent,
        label: routeLabel,
      ));
    }

    return Pressable(
      onTap: () => context.push('/globe-cinematic'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CinematicGlobe(
                routes: routes,
                showHubs: true,
                showLabels: false,
                autoRotate: true,
                padding: 12,
                glowColor: accent,
              ),
            ),
            // Bottom gradient caption.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space6,
                  AppTokens.space4,
                  AppTokens.space3,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Explore globe',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.55), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
