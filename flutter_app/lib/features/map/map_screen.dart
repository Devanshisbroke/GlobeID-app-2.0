import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/airports.dart';
import '../../widgets/animated_appearance.dart';
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
        IgnorePointer(
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
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      color: const Color(0xFF02040A),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          return CustomPaint(
            painter: _GlobePainter(
              t: animation.value,
              routes: routes,
              accent: accent,
              showTraffic: showTraffic,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  const _GlobePainter({
    required this.t,
    required this.routes,
    required this.accent,
    required this.showTraffic,
  });

  final double t;
  final List<_GlobeRoute> routes;
  final Color accent;
  final bool showTraffic;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.47);
    final radius = math.min(size.width, size.height) * 0.37;

    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.18),
        colors: [
          accent.withValues(alpha: 0.20),
          const Color(0xFF07101E),
          const Color(0xFF02040A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    for (var i = 0; i < 120; i++) {
      final r = math.Random(i * 17);
      final p = Offset(
        r.nextDouble() * size.width,
        r.nextDouble() * size.height,
      );
      final twinkle = 0.35 + 0.45 * math.sin((t * math.pi * 2) + i);
      canvas.drawCircle(
        p,
        0.5 + r.nextDouble() * 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.08 * twinkle),
      );
    }

    canvas.drawCircle(
      center,
      radius * 1.14,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.22), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.22)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.34, -0.42),
          colors: [Color(0xFF1EBAE8), Color(0xFF115AA8), Color(0xFF061226)],
          stops: [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final clip = ui.Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clip);
    _drawTerminator(canvas, center, radius);
    _drawContinents(canvas, center, radius);
    _drawGrid(canvas, center, radius);
    canvas.restore();

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius, halo);

    for (final route in routes.take(28)) {
      _drawRoute(canvas, center, radius, route);
    }

    if (showTraffic) _drawTraffic(canvas, center, radius);
  }

  void _drawTerminator(Canvas canvas, Offset center, double radius) {
    final offset = math.sin(t * math.pi * 2) * radius * 0.34;
    final rect = Rect.fromCenter(
      center: center.translate(offset, 0),
      width: radius * 1.75,
      height: radius * 2.28,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.52),
          ],
        ).createShader(rect),
    );
  }

  void _drawContinents(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    for (final spec in const [
      (-0.55, -0.18, 0.34, 0.18, -0.25),
      (-0.24, 0.24, 0.18, 0.34, 0.24),
      (0.22, -0.08, 0.44, 0.22, 0.08),
      (0.46, 0.28, 0.20, 0.15, -0.2),
      (-0.12, -0.48, 0.16, 0.10, 0.1),
    ]) {
      final (x, y, w, h, rot) = spec;
      canvas.save();
      canvas.translate(center.dx + x * radius, center.dy + y * radius);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * radius,
          height: h * radius,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.08);
    for (var i = -2; i <= 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * (0.28 + (2 - i.abs()) * 0.24),
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * (0.34 + (2 - i.abs()) * 0.28),
          height: radius * 2,
        ),
        paint,
      );
    }
  }

  void _drawRoute(
    Canvas canvas,
    Offset center,
    double radius,
    _GlobeRoute route,
  ) {
    final a = _project(route.from.lat, route.from.lng, center, radius);
    final b = _project(route.to.lat, route.to.lng, center, radius);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final lift = (a - b).distance * 0.22 + 28;
    final control = Offset(mid.dx, mid.dy - lift);
    final path = ui.Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
    final color = route.stage == 'past' ? Colors.white54 : accent;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = route.stage == 'active' ? 2.2 : 1.4
        ..color = color.withValues(alpha: route.stage == 'past' ? 0.26 : 0.78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final seed = (route.flightNumber.hashCode % 17) / 17.0;
    final p = _quadratic(a, control, b, (t + seed) % 1);
    canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(p, 6.5, Paint()..color = color.withValues(alpha: 0.18));
  }

  void _drawTraffic(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = accent.withValues(alpha: 0.22);
    for (var i = 0; i < 32; i++) {
      final angle = (t * math.pi * 2) + i * 0.64;
      final band = radius * (0.72 + (i % 5) * 0.055);
      final p = center +
          Offset(math.cos(angle) * band, math.sin(angle * 0.72) * band * 0.42);
      canvas.drawCircle(p, 1.4 + (i % 3) * 0.5, paint);
    }
  }

  Offset _project(double lat, double lng, Offset center, double radius) {
    final spin = (t - 0.18) * 360;
    final lambda = (lng + spin) * math.pi / 180;
    final phi = lat * math.pi / 180;
    return center +
        Offset(math.cos(phi) * math.sin(lambda), -math.sin(phi)) * radius;
  }

  Offset _quadratic(Offset a, Offset c, Offset b, double p) {
    final q = 1 - p;
    return a * (q * q) + c * (2 * q * p) + b * (p * p);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.routes != routes ||
      oldDelegate.accent != accent ||
      oldDelegate.showTraffic != showTraffic;
}
