import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/globe_renderer.dart' as cg;
import '../../domain/airports.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/starfield.dart';
import '../lifecycle/lifecycle_provider.dart';

/// Map v2 — hybrid globe stage with animated great-circle routes,
/// atmospheric lighting, service-level controls, and a 2D OSM fallback.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  bool _show2d = false;
  bool _showTraffic = true;

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = ref.watch(lifecycleProvider);
    final theme = Theme.of(context);
    final markers = <Marker>[];
    final arcs = <List<LatLng>>[];
    final routes = <_GlobeRoute>[];

    for (final t in lifecycle.trips) {
      for (final leg in t.legs) {
        final from = getAirport(leg.from);
        final to = getAirport(leg.to);
        if (from == null || to == null) continue;
        markers.add(_marker(LatLng(from.lat, from.lng), theme));
        markers.add(_marker(LatLng(to.lat, to.lng), theme));
        arcs.add([LatLng(from.lat, from.lng), LatLng(to.lat, to.lng)]);
        routes.add(
          _GlobeRoute(
            from: from,
            to: to,
            stage: t.stage,
            flightNumber: leg.flightNumber,
          ),
        );
      }
    }

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: AppTokens.durationLg,
          switchInCurve: AppTokens.easeOutSoft,
          child: _show2d
              ? _MapFallback(
                  key: const ValueKey('map2d'),
                  markers: markers,
                  arcs: arcs,
                )
              : _GlobeStage(
                  key: const ValueKey('globe3d'),
                  animation: _pulse,
                  routes: routes,
                  showTraffic: _showTraffic,
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.1, -0.08),
                  radius: 1.22,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.36),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: AppTokens.space5,
          right: AppTokens.space5,
          top: MediaQuery.of(context).padding.top + AppTokens.space3,
          child: AnimatedAppearance(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: AppTokens.space3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _show2d ? Icons.map_rounded : Icons.public_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppTokens.space2),
                      Expanded(
                        child: Text(
                          'Globe',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _MapToggleChip(
                        label: _show2d ? '2D' : '${arcs.length} arcs',
                        icon: _show2d ? Icons.layers_rounded : Icons.timeline,
                        onTap: () => setState(() => _show2d = !_show2d),
                      ),
                      const SizedBox(width: AppTokens.space2),
                      _MapToggleChip(
                        label: _showTraffic ? 'Live' : 'Calm',
                        icon: _showTraffic
                            ? Icons.radar_rounded
                            : Icons.visibility_off_rounded,
                        onTap: () =>
                            setState(() => _showTraffic = !_showTraffic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _marker(LatLng p, ThemeData theme) => Marker(
        point: p,
        width: 18,
        height: 18,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 18 + 8 * _pulse.value,
                height: 18 + 8 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(
                    alpha: (1 - _pulse.value) * 0.32,
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow:
                      AppTokens.shadowSm(tint: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({super.key, required this.markers, required this.arcs});

  final List<Marker> markers;
  final List<List<LatLng>> arcs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(20, 0),
        initialZoom: 2,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'io.globeid.app',
        ),
        PolylineLayer(
          polylines: [
            for (final pts in arcs)
              Polyline(
                points: pts,
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _MapToggleChip extends StatelessWidget {
  const _MapToggleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: accent.withValues(alpha: 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobeRoute {
  const _GlobeRoute({
    required this.from,
    required this.to,
    required this.stage,
    required this.flightNumber,
  });

  final Airport from;
  final Airport to;
  final String stage;
  final String flightNumber;
}

class _GlobeStage extends StatelessWidget {
  const _GlobeStage({
    super.key,
    required this.animation,
    required this.routes,
    required this.showTraffic,
  });

  final Animation<double> animation;
  final List<_GlobeRoute> routes;
  final bool showTraffic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final globeRoutes = <cg.GlobeRoute>[];
    for (final r in routes) {
      Color tone;
      switch (r.stage) {
        case 'active':
          tone = theme.colorScheme.primary;
          break;
        case 'past':
          tone = Colors.white.withValues(alpha: 0.55);
          break;
        default:
          tone = theme.colorScheme.tertiary;
      }
      globeRoutes.add(
        cg.GlobeRoute(
          fromLat: r.from.lat,
          fromLng: r.from.lng,
          toLat: r.to.lat,
          toLng: r.to.lng,
          color: tone,
          label: r.flightNumber,
          dashed: r.stage == 'planned',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.18),
          colors: [
            accent.withValues(alpha: 0.22),
            const Color(0xFF050912),
            const Color(0xFF02040A),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: Starfield(density: 0.8)),
          if (showTraffic)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CustomPaint(
                  painter: _GlobeOrbitPainter(
                    t: animation.value,
                    accent: accent,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: cg.CinematicGlobe(
              routes: globeRoutes,
              autoRotate: true,
              showHubs: true,
              showLabels: false,
              glowColor: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobeOrbitPainter extends CustomPainter {
  const _GlobeOrbitPainter({required this.t, required this.accent});
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()..color = accent.withValues(alpha: 0.18);
    for (var i = 0; i < 24; i++) {
      final angle = t * math.pi * 2 + i * 0.65;
      final band = radius * (0.78 + (i % 5) * 0.06);
      final p = center +
          Offset(math.cos(angle) * band, math.sin(angle * 0.7) * band * 0.42);
      canvas.drawCircle(p, 1.0 + (i % 3) * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobeOrbitPainter old) =>
      old.t != t || old.accent != accent;
}

