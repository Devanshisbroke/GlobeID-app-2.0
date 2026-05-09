import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// A shared-element ribbon that connects two screens during a route
/// push.
///
/// Conceptually a thin Hero connector — wrap a source surface with
/// [CinematicRouteHeroSource] and the destination surface with
/// [CinematicRouteHeroTarget] using the same [tag]. Flutter's Hero
/// machinery handles the morph; we add a colored ribbon flight path
/// that lights up during the transition.
///
/// Use cases:
///   • wallet pass → boarding-live
///   • identity card → passport-book
///   • home flight glance → trip detail
class CinematicRouteHeroSource extends StatelessWidget {
  const CinematicRouteHeroSource({
    super.key,
    required this.tag,
    required this.child,
    this.tone,
  });

  final Object tag;
  final Widget child;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? Theme.of(context).colorScheme.primary;
    return Hero(
      tag: tag,
      flightShuttleBuilder: (_, animation, direction, fromCtx, toCtx) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final t = animation.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.40 * t),
                    blurRadius: 28 + 32 * t,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: direction == HeroFlightDirection.push
                  ? toCtx.widget
                  : fromCtx.widget,
            );
          },
        );
      },
      child: child,
    );
  }
}

class CinematicRouteHeroTarget extends StatelessWidget {
  const CinematicRouteHeroTarget({
    super.key,
    required this.tag,
    required this.child,
  });
  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(tag: tag, child: child);
}
