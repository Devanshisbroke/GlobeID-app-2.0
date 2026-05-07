import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'great_circle.dart';
import 'world_outlines.dart';

/// Cinematic globe — pure-Flutter approximation of a 3D Earth.
///
/// Renders:
///   • Deep-space starfield gradient backdrop
///   • Glowing atmosphere halo (multi-ring blur)
///   • Sphere base with vertical / horizontal great-circle grid
///   • Continent silhouettes via low-poly polygons
///   • Day/night terminator (sun-position aware)
///   • Animated great-circle arcs with bead trail
///   • City hub markers with pulse ring
///
/// The renderer is intentionally CPU-side (Canvas + CustomPaint), no
/// shaders or platform views, so it runs on every Android device the
/// host app supports without a native SkSL fallback path.
class CinematicGlobe extends StatefulWidget {
  const CinematicGlobe({
    super.key,
    required this.routes,
    this.autoRotate = true,
    this.showHubs = true,
    this.showLabels = false,
    this.glowColor,
    this.landColor,
    this.padding = 24,
  });

  final List<GlobeRoute> routes;
  final bool autoRotate;
  final bool showHubs;
  final bool showLabels;
  final Color? glowColor;
  final Color? landColor;
  final double padding;

  @override
  State<CinematicGlobe> createState() => _CinematicGlobeState();
}

class _CinematicGlobeState extends State<CinematicGlobe>
    with TickerProviderStateMixin {
  // Tickers: one for the slow auto-rotation, one for arc beads / pulse.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  // User drag state.
  double _userYaw = 0.0;
  double _userPitch = -0.18; // slight downward tilt looks more cinematic.

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = widget.glowColor ?? theme.colorScheme.primary;
    final land = widget.landColor ?? const Color(0xFF1A2540);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) {
        setState(() {
          _userYaw += d.delta.dx * 0.005;
          _userPitch =
              (_userPitch - d.delta.dy * 0.005).clamp(-1.1, 1.1);
        });
      },
      // Isolated repaint layer keeps the heavy globe painter off the
      // main scaffold's compositor pass — surrounding chrome stays
      // smooth while the globe ticks every frame.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _pulse]),
          builder: (_, __) {
            final autoYaw = widget.autoRotate && !reduce
                ? _spin.value * 2 * math.pi
                : 0.0;
            return CustomPaint(
              size: Size.infinite,
              isComplex: true,
              willChange: true,
              painter: _GlobePainter(
                yaw: autoYaw + _userYaw,
                pitch: _userPitch,
                pulseT: reduce ? 0 : _pulse.value,
                routes: widget.routes,
                glowColor: glow,
                landColor: land,
                showHubs: widget.showHubs,
                showLabels: widget.showLabels,
                padding: widget.padding,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One rendered great-circle route on the globe.
class GlobeRoute {
  const GlobeRoute({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final Color color;
  final String label;
  final bool dashed;
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({
    required this.yaw,
    required this.pitch,
    required this.pulseT,
    required this.routes,
    required this.glowColor,
    required this.landColor,
    required this.showHubs,
    required this.showLabels,
    required this.padding,
  });

  final double yaw;
  final double pitch;
  final double pulseT;
  final List<GlobeRoute> routes;
  final Color glowColor;
  final Color landColor;
  final bool showHubs;
  final bool showLabels;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - padding;
    final cam = GlobeCamera(
      size: radius * 2,
      rotationY: yaw,
      rotationX: pitch,
    );

    // Twinkling starfield occupies the *full* canvas, painted before
    // we translate to the globe center. This makes deep space feel
    // alive even when the globe is small.
    _paintStars(canvas, size);

    canvas.save();
    canvas.translate(cx, cy);

    _paintAtmosphere(canvas, radius);
    _paintSphere(canvas, radius);
    _paintGrid(canvas, cam, radius);
    _paintLand(canvas, cam, radius);
    _paintTerminator(canvas, cam, radius);
    _paintCityLights(canvas, cam, radius);
    _paintRoutes(canvas, cam, radius);
    if (showHubs) _paintHubs(canvas, cam, radius);
    _paintRim(canvas, radius);

    canvas.restore();
  }

  void _paintStars(Canvas canvas, Size size) {
    // Deterministic stars seeded from screen geometry; twinkle phase
    // driven by pulseT.
    final rng = math.Random(73);
    for (var i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final base = 0.2 + rng.nextDouble() * 0.6;
      final phase = rng.nextDouble() * 2 * math.pi;
      final tw = (math.sin(pulseT * 2 * math.pi + phase) + 1) / 2;
      final radius = 0.4 + rng.nextDouble() * 1.4;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: base * (0.5 + 0.5 * tw)),
      );
    }
    // A handful of brighter "anchor" stars with a soft halo.
    final rng2 = math.Random(37);
    for (var i = 0; i < 12; i++) {
      final x = rng2.nextDouble() * size.width;
      final y = rng2.nextDouble() * size.height;
      final phase = rng2.nextDouble() * 2 * math.pi;
      final tw = (math.sin(pulseT * 2 * math.pi + phase) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        2.2 + tw * 1.4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.30 + 0.40 * tw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    }
  }

  void _paintCityLights(Canvas canvas, GlobeCamera cam, double r) {
    // Tiny warm glints clustered along the night side of major hubs.
    final sunYaw = -yaw * 0.5 + math.pi * 0.2;
    final sun = Vector3(math.cos(sunYaw), 0.25, math.sin(sunYaw))
      ..normalize();
    for (final h in WorldOutlines.hubs) {
      final v = GreatCircle.toCartesian(h.lat, h.lng);
      final rotated = cam.apply(v);
      if (rotated.z < 0) continue;
      // Compute night-ness: dot with sun direction. If on day side,
      // skip; if on night side, render warm glints.
      final dotSun = v.dot(sun);
      if (dotSun > 0.05) continue;
      final off = _project(rotated, r);
      final flicker = (math.sin(pulseT * 6 * math.pi + h.lat * 0.3) + 1) / 2;
      canvas.drawCircle(
        off,
        1.6 + flicker * 1.0,
        Paint()
          ..color = const Color(0xFFFFD27D)
              .withValues(alpha: 0.6 + 0.3 * flicker)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  // ── Layers ────────────────────────────────────────────────────────

  void _paintAtmosphere(Canvas canvas, double r) {
    // Outer halo — radial glow that fades out beyond the sphere.
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r * 1.6,
        [
          glowColor.withValues(alpha: 0.30),
          glowColor.withValues(alpha: 0.0),
        ],
        const [0.55, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset.zero, r * 1.55, halo);

    // Inner rim glow.
    final rim = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r * 1.05,
        [
          glowColor.withValues(alpha: 0.0),
          glowColor.withValues(alpha: 0.55),
          glowColor.withValues(alpha: 0.0),
        ],
        const [0.85, 0.97, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, r * 1.05, rim);
  }

  void _paintSphere(Canvas canvas, double r) {
    // Deep ocean base with subtle vertical lighting.
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -r),
        Offset(0, r),
        const [Color(0xFF0A1224), Color(0xFF050912)],
      );
    canvas.drawCircle(Offset.zero, r, base);

    // Specular highlight — top-left, faint, gives 3D read.
    final spec = Paint()
      ..shader = ui.Gradient.radial(
        Offset(-r * 0.35, -r * 0.45),
        r * 0.9,
        [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(Offset.zero, r, spec);
  }

  void _paintGrid(Canvas canvas, GlobeCamera cam, double r) {
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.06);

    // Latitude rings every 15°.
    for (var lat = -75.0; lat <= 75.0; lat += 15) {
      final p = Path();
      var first = true;
      for (var lng = -180.0; lng <= 180.0; lng += 6) {
        final v = GreatCircle.toCartesian(lat, lng);
        final rotated = cam.apply(v);
        if (rotated.z < 0) continue;
        final off = _project(rotated, r);
        if (first) {
          p.moveTo(off.dx, off.dy);
          first = false;
        } else {
          p.lineTo(off.dx, off.dy);
        }
      }
      canvas.drawPath(p, grid);
    }

    // Longitude meridians every 15°.
    for (var lng = -180.0; lng < 180.0; lng += 15) {
      final p = Path();
      var first = true;
      for (var lat = -90.0; lat <= 90.0; lat += 4) {
        final v = GreatCircle.toCartesian(lat, lng);
        final rotated = cam.apply(v);
        if (rotated.z < 0) continue;
        final off = _project(rotated, r);
        if (first) {
          p.moveTo(off.dx, off.dy);
          first = false;
        } else {
          p.lineTo(off.dx, off.dy);
        }
      }
      canvas.drawPath(p, grid);
    }
  }

  void _paintLand(Canvas canvas, GlobeCamera cam, double r) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = landColor;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.18);

    for (final outline in WorldOutlines.all) {
      final segments = <List<Offset>>[];
      var current = <Offset>[];
      for (final p in outline) {
        final v = GreatCircle.toCartesian(p[0], p[1]);
        final rotated = cam.apply(v);
        if (rotated.z < 0) {
          // Vertex on the far hemisphere — break path.
          if (current.length >= 2) segments.add(current);
          current = <Offset>[];
          continue;
        }
        current.add(_project(rotated, r));
      }
      if (current.length >= 2) segments.add(current);

      for (final seg in segments) {
        if (seg.length < 3) continue;
        final path = Path()..moveTo(seg.first.dx, seg.first.dy);
        for (var i = 1; i < seg.length; i++) {
          path.lineTo(seg[i].dx, seg[i].dy);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  void _paintTerminator(Canvas canvas, GlobeCamera cam, double r) {
    // Approximate sun direction — synced loosely with yaw so the
    // terminator drifts as the user spins.
    final sunYaw = -yaw * 0.5 + math.pi * 0.2;
    final sun = Vector3(math.cos(sunYaw), 0.25, math.sin(sunYaw))
      ..normalize();

    // Render a soft night-side wash.
    final night = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.save();
    canvas.clipPath(night);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-sun.x * r, -sun.y * r) * -1,
        Offset(sun.x * r, sun.y * r) * -1,
        [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.55),
        ],
        const [0.45, 1.0],
      );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * 3, height: r * 3),
      paint,
    );
    canvas.restore();
  }

  void _paintRoutes(Canvas canvas, GlobeCamera cam, double r) {
    for (final route in routes) {
      final samples = GreatCircle.samplePoints(
        latA: route.fromLat,
        lngA: route.fromLng,
        latB: route.toLat,
        lngB: route.toLng,
        count: 80,
        altitudeBoost: 0.18,
      );

      final visiblePts = <Offset>[];
      for (final p in samples) {
        final rotated = cam.apply(p);
        if (rotated.z < 0) {
          if (visiblePts.length >= 2) {
            _drawArcPath(canvas, visiblePts, route, r);
          }
          visiblePts.clear();
          continue;
        }
        visiblePts.add(_project(rotated, r * 1.0));
      }
      if (visiblePts.length >= 2) {
        _drawArcPath(canvas, visiblePts, route, r);
      }

      // Bead — a glowing dot that travels along the arc.
      final bead = (pulseT * samples.length).floor()
          .clamp(0, samples.length - 1);
      final v = samples[bead];
      final rotated = cam.apply(v);
      if (rotated.z >= 0) {
        final off = _project(rotated, r * 1.0);
        final paint = Paint()
          ..color = route.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(off, 5.5, paint);
        canvas.drawCircle(off, 2.2, Paint()..color = Colors.white);
      }

      // Endpoint markers.
      for (final v in [samples.first, samples.last]) {
        final rotated = cam.apply(v);
        if (rotated.z >= 0) {
          final off = _project(rotated, r * 1.0);
          final ring = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = route.color.withValues(alpha: 0.85);
          canvas.drawCircle(off, 4.5, ring);
          canvas.drawCircle(
            off,
            2,
            Paint()..color = Colors.white,
          );
        }
      }
    }
  }

  void _drawArcPath(
      Canvas canvas, List<Offset> pts, GlobeRoute route, double r) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = route.color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    if (route.dashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path src, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    const period = dashLen + gapLen;
    // Animate the dash phase so the arc 'flows' along its direction.
    final phase = (pulseT * period * 2) % period;
    for (final metric in src.computeMetrics()) {
      var dist = -phase;
      while (dist < metric.length) {
        final start = dist.clamp(0.0, metric.length);
        final next = (dist + dashLen).clamp(0.0, metric.length);
        if (next > start) {
          canvas.drawPath(metric.extractPath(start, next), paint);
        }
        dist = dist + period;
      }
    }
  }

  void _paintHubs(Canvas canvas, GlobeCamera cam, double r) {
    final pulseScale = (math.sin(pulseT * 2 * math.pi) + 1) / 2;
    for (final h in WorldOutlines.hubs) {
      final v = GreatCircle.toCartesian(h.lat, h.lng);
      final rotated = cam.apply(v);
      if (rotated.z < 0) continue;
      final off = _project(rotated, r);
      final ringR = 4.0 + pulseScale * 6.0;
      canvas.drawCircle(
        off,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = glowColor.withValues(alpha: 0.45 * (1 - pulseScale))
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        off,
        2.4,
        Paint()..color = glowColor,
      );
      canvas.drawCircle(
        off,
        1.0,
        Paint()..color = Colors.white,
      );
      if (showLabels) {
        final tp = TextPainter(
          text: TextSpan(
            text: h.code,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, off + const Offset(6, -4));
      }
    }
  }

  void _paintRim(Canvas canvas, double r) {
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(Offset.zero, r, rim);
  }

  Offset _project(Vector3 rotated, double r) =>
      Offset(rotated.x * r, -rotated.y * r);

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.pulseT != pulseT ||
      old.routes != routes ||
      old.showHubs != showHubs ||
      old.glowColor != glowColor;
}
