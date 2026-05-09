import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/globe_camera_controller.dart';
import '../../cinematic/globe_interaction_overlay.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// CinematicGlobeScreen — Google Earth-inspired immersive globe.
///
/// • Atmospheric halo + fresnel rim
/// • Continent silhouettes (deterministic painter)
/// • Animated great-circle arcs between cities
/// • Contextual destination cards (selected → camera follows)
/// All custom-painted with no external shaders.
class CinematicGlobeScreen extends StatefulWidget {
  const CinematicGlobeScreen({super.key});
  @override
  State<CinematicGlobeScreen> createState() => _CinematicGlobeScreenState();
}

class _CinematicGlobeScreenState extends State<CinematicGlobeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  /// Cassini-style camera with auto-orbit + fly-to. Ticked every frame
  /// so its yaw/pitch smoothly settles toward the selected destination.
  final GlobeCameraController _camera = GlobeCameraController();

  int _selected = 1;

  static const _destinations = <_Dest>[
    _Dest(
        city: 'Tokyo',
        country: 'Japan',
        flag: '🇯🇵',
        lat: 35.68,
        lng: 139.76,
        tone: Color(0xFFE11D48)),
    _Dest(
        city: 'Reykjavík',
        country: 'Iceland',
        flag: '🇮🇸',
        lat: 64.13,
        lng: -21.94,
        tone: Color(0xFF06B6D4)),
    _Dest(
        city: 'Marrakech',
        country: 'Morocco',
        flag: '🇲🇦',
        lat: 31.63,
        lng: -7.99,
        tone: Color(0xFFD97706)),
    _Dest(
        city: 'Queenstown',
        country: 'New Zealand',
        flag: '🇳🇿',
        lat: -45.03,
        lng: 168.66,
        tone: Color(0xFF10B981)),
  ];

  @override
  void initState() {
    super.initState();
    _camera.flyTo(
      lat: _destinations[_selected].lat,
      lng: _destinations[_selected].lng,
    );
    _ctrl.addListener(_camera.tick);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_camera.tick);
    _camera.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Cinematic globe',
      subtitle: 'Atmospheric · animated arcs · contextual destinations',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: AspectRatio(
              aspectRatio: 0.96,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CinematicGlobePainter(
                              progress: _ctrl.value,
                              destinations: _destinations,
                              selected: _selected,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GlobeInteractionOverlay(
                            currentLat: _destinations[_selected].lat,
                            currentLng: _destinations[_selected].lng,
                            currentZoom: 1.0 + _selected * 0.4,
                            selectedCity: GlobeCityInfo(
                              name: _destinations[_selected].city,
                              country: _destinations[_selected].country,
                              flag: _destinations[_selected].flag,
                              timezone: '—',
                              temperature: '—',
                              condition: '—',
                              lat: _destinations[_selected].lat,
                              lng: _destinations[_selected].lng,
                              tone: _destinations[_selected].tone,
                            ),
                            onTimeChanged: (_) =>
                                HapticFeedback.selectionClick(),
                            onLayerToggled: (_, __) =>
                                HapticFeedback.lightImpact(),
                            onCityTapped: (_) {
                              HapticFeedback.lightImpact();
                              context.push('/cities');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          const SectionHeader(
              title: 'Pinned destinations', subtitle: 'Tap to fly the camera'),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 1),
              itemCount: _destinations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTokens.space2),
              itemBuilder: (_, i) {
                final d = _destinations[i];
                final selected = _selected == i;
                return Pressable(
                  scale: 0.96,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selected = i);
                    _camera.flyTo(
                      lat: d.lat,
                      lng: d.lng,
                      zoom: 1.4,
                    );
                  },
                  child: AnimatedContainer(
                    duration: AppTokens.durationSm,
                    width: 168,
                    padding: const EdgeInsets.all(AppTokens.space3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          d.tone.withValues(alpha: selected ? 0.85 : 0.50),
                          d.tone.withValues(alpha: selected ? 0.45 : 0.22),
                        ],
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: d.tone.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.flag, style: const TextStyle(fontSize: 22)),
                        const Spacer(),
                        Text(d.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            )),
                        Text(d.country,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AgenticBand(
            title: 'Plan trip to ${_destinations[_selected].city}',
            chips: [
              AgenticChip(
                icon: Icons.flight_rounded,
                label: 'Find flights',
                route: '/services/flights',
                tone: _destinations[_selected].tone,
              ),
              const AgenticChip(
                icon: Icons.hotel_rounded,
                label: 'Browse hotels',
                route: '/services/hotels',
                tone: Color(0xFF7E22CE),
              ),
              const AgenticChip(
                icon: Icons.assignment_ind_rounded,
                label: 'Visa & docs',
                route: '/identity',
                tone: Color(0xFF10B981),
              ),
              const AgenticChip(
                icon: Icons.smart_toy_rounded,
                label: 'Cultural copilot',
                route: '/copilot',
                tone: Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why this destination?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 6),
                Text(
                  _destinations[_selected].pitch,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.78),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Open Travel OS',
            icon: Icons.hub_rounded,
            gradient: LinearGradient(
              colors: [
                _destinations[_selected].tone,
                _destinations[_selected].tone.withValues(alpha: 0.55),
              ],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              GoRouter.of(context).push('/travel-os');
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _Dest {
  const _Dest({
    required this.city,
    required this.country,
    required this.flag,
    required this.lat,
    required this.lng,
    required this.tone,
  });
  final String city;
  final String country;
  final String flag;
  final double lat;
  final double lng;
  final Color tone;

  String get pitch {
    switch (city) {
      case 'Tokyo':
        return 'Cherry-blossom corridors, Michelin-starred ramen, Ginza, '
            'and the calm precision of JR Pass mornings.';
      case 'Reykjavík':
        return 'Aurora season, geothermal lagoons, and cinematic '
            'midnight-sun arcs across volcanic moonscapes.';
      case 'Marrakech':
        return 'Riad rooftops, spice souks, the Atlas mountains, '
            'and the slow rhythm of mint tea at dusk.';
      case 'Queenstown':
        return 'Lake Wakatipu fjords, Milford Sound flights, '
            'wineries, and a southern sky pin-sharp with stars.';
    }
    return '';
  }
}

class _CinematicGlobePainter extends CustomPainter {
  const _CinematicGlobePainter({
    required this.progress,
    required this.destinations,
    required this.selected,
  });
  final double progress;
  final List<_Dest> destinations;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    // Space background
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF0B1024), Color(0xFF02030A)],
        ).createShader(Offset.zero & size),
    );

    // Stars
    final rng = math.Random(11);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 0; i < 220; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), rng.nextDouble() * 1.3 + 0.2, star);
    }

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.42;

    // Atmosphere halo
    canvas.drawCircle(
      Offset(cx, cy),
      r + 18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF06B6D4).withValues(alpha: 0.45),
            const Color(0xFF06B6D4).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r + 30)),
    );

    // Globe core gradient
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFF1E40AF), Color(0xFF0B1024)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Continents (deterministic spots)
    final contRng = math.Random(31);
    final cont = Paint()
      ..color = const Color(0xFF065F46).withValues(alpha: 0.85);
    for (var i = 0; i < 18; i++) {
      // Random points within unit sphere, projected via simple sin/cos
      final phi = contRng.nextDouble() * math.pi * 2;
      final theta = contRng.nextDouble() * math.pi - math.pi / 2;
      final rotated = phi + progress * math.pi * 2;
      // Only draw front hemisphere
      final fx = math.cos(theta) * math.sin(rotated);
      final fy = math.sin(theta);
      final fz = math.cos(theta) * math.cos(rotated);
      if (fz < 0) continue;
      final px = cx + fx * r;
      final py = cy + fy * r;
      final size = (contRng.nextDouble() * 12 + 6) * (0.6 + fz * 0.6);
      canvas.drawCircle(Offset(px, py), size, cont);
    }

    // Meridians
    final meridian = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i <= 6; i++) {
      final t = i / 6;
      final w = math.sin(t * math.pi) * r;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 2, height: r * 2),
        meridian,
      );
    }
    for (var i = 1; i <= 4; i++) {
      final h = (i / 5) * r;
      canvas.drawLine(
        Offset(cx - r * math.sqrt(1 - (h / r) * (h / r)), cy + h),
        Offset(cx + r * math.sqrt(1 - (h / r) * (h / r)), cy + h),
        meridian,
      );
      canvas.drawLine(
        Offset(cx - r * math.sqrt(1 - (h / r) * (h / r)), cy - h),
        Offset(cx + r * math.sqrt(1 - (h / r) * (h / r)), cy - h),
        meridian,
      );
    }

    // Fresnel rim highlight
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.55),
    );

    // Animated arcs between consecutive destinations
    for (var i = 0; i < destinations.length; i++) {
      final a = destinations[i];
      final b = destinations[(i + 1) % destinations.length];
      _drawArc(canvas, cx, cy, r, a, b, progress, isHighlight: i == selected);
    }

    // City pins
    for (var i = 0; i < destinations.length; i++) {
      final d = destinations[i];
      final pos = _project(d, cx, cy, r);
      if (pos == null) continue;
      final isSel = i == selected;
      final color = d.tone;
      canvas.drawCircle(
        pos,
        isSel ? 9 : 5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        pos,
        isSel ? 6 : 3.4,
        Paint()..color = color,
      );
      if (isSel) {
        // Pulse ring
        final pulse = ((progress * 4) % 1.0);
        canvas.drawCircle(
          pos,
          12 + pulse * 14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color.withValues(alpha: (1 - pulse) * 0.7),
        );
      }
    }

    // Bottom info
    final tp = TextPainter(
      text: TextSpan(
        text: 'GlobeID · Earth',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(16, size.height - 24));
  }

  Offset? _project(_Dest d, double cx, double cy, double r) {
    final phi = d.lng * math.pi / 180;
    final theta = d.lat * math.pi / 180;
    final rotated = phi + progress * math.pi * 2;
    final fx = math.cos(theta) * math.sin(rotated);
    final fy = -math.sin(theta);
    final fz = math.cos(theta) * math.cos(rotated);
    if (fz < 0) return null;
    return Offset(cx + fx * r, cy + fy * r);
  }

  void _drawArc(
      Canvas canvas, double cx, double cy, double r, _Dest a, _Dest b, double t,
      {required bool isHighlight}) {
    final pa = _project(a, cx, cy, r);
    final pb = _project(b, cx, cy, r);
    if (pa == null || pb == null) return;
    final mid = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2);
    final dist = (pa - pb).distance;
    final lift = math.min(60.0, dist * 0.55);
    final apex = Offset(mid.dx, mid.dy - lift);
    final path = Path()
      ..moveTo(pa.dx, pa.dy)
      ..quadraticBezierTo(apex.dx, apex.dy, pb.dx, pb.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlight ? 1.8 : 1.0
        ..color = isHighlight
            ? a.tone.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.32),
    );
    // Particle along arc
    final pos = ((t * 2) + (isHighlight ? 0.0 : 0.4)) % 1.0;
    final p = Offset(
      _bezier(pa.dx, apex.dx, pb.dx, pos),
      _bezier(pa.dy, apex.dy, pb.dy, pos),
    );
    canvas.drawCircle(
      p,
      isHighlight ? 3.4 : 2.2,
      Paint()..color = isHighlight ? a.tone : Colors.white,
    );
  }

  double _bezier(double a, double b, double c, double t) {
    final u = 1 - t;
    return u * u * a + 2 * u * t * b + t * t * c;
  }

  @override
  bool shouldRepaint(covariant _CinematicGlobePainter old) =>
      old.progress != progress || old.selected != selected;
}
