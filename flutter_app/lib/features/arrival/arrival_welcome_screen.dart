import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import 'local_mode_sheet.dart';

/// ArrivalWelcomeScreen — the cinematic moment after the kiosk turns
/// green: a destination welcomes the user with localized phrases,
/// timezone, currency, weather, and an agentic chain of "do this next"
/// chips that bridge to local services (eSIM, ride, copilot, food).
///
/// Pure-Dart, deterministic. Drives a subtle parallax aurora,
/// animated airplane arc, and a "first 90 minutes" quick-action band.
class ArrivalWelcomeScreen extends StatefulWidget {
  const ArrivalWelcomeScreen({
    super.key,
    this.country = 'Japan',
    this.city = 'Tokyo',
    this.flag = 'JP',
    this.currency = 'JPY',
    this.timezone = 'GMT+9',
    this.tone = const Color(0xFFE11D48),
  });

  final String country;
  final String city;
  final String flag;
  final String currency;
  final String timezone;
  final Color tone;

  @override
  State<ArrivalWelcomeScreen> createState() => _ArrivalWelcomeScreenState();
}

class _ArrivalWelcomeScreenState extends State<ArrivalWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Fire arrival chime once after the first frame so the haptic
    // lines up with the visual reveal, not the route push.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HapticPatterns.arrivalChime.play();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Welcome to ${widget.city}',
      subtitle: 'Your ecosystem just adapted · ${widget.country}',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          CinematicReveal(
            tone: widget.tone,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.45,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radius2xl),
                        child: CustomPaint(
                          painter: _ArrivalPainter(
                            tone: widget.tone,
                            progress: _ctrl.value,
                            flag: widget.flag,
                            city: widget.city,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppTokens.space3,
                  right: AppTokens.space3,
                  child: PremiumHud(
                    label: 'ARRIVED',
                    tone: widget.tone,
                    trailing: Text(widget.timezone),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: [
                Expanded(
                    child: _StatTile(
                        icon: Icons.access_time_rounded,
                        label: 'Local time',
                        value: widget.timezone,
                        tone: widget.tone)),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                    child: _StatTile(
                        icon: Icons.currency_exchange_rounded,
                        label: 'Currency',
                        value: widget.currency,
                        tone: widget.tone)),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                    child: _StatTile(
                        icon: Icons.cloud_rounded,
                        label: 'Weather',
                        value: '17° clear',
                        tone: widget.tone)),
              ],
            ),
          ),
          const SectionHeader(
              title: 'Useful phrases', subtitle: 'Tap to hear & save'),
          for (final phrase in const [
            ('こんにちは', 'Konnichiwa', 'Hello'),
            ('ありがとう', 'Arigatou', 'Thank you'),
            ('すみません', 'Sumimasen', 'Excuse me'),
            ('英語を話せますか?', 'Eigo wo hanasemasu ka?', 'Do you speak English?'),
            ('助けてください', 'Tasukete kudasai', 'Please help me'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.tone.withValues(alpha: 0.18),
                      ),
                      child: Icon(Icons.volume_up_rounded,
                          color: widget.tone, size: 16),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(phrase.$1,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.tone,
                              )),
                          Text('${phrase.$2} · ${phrase.$3}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SectionHeader(
            title: 'First 90 minutes',
            subtitle: 'Your ecosystem just queued these up',
          ),
          AgenticBand(
            title: '',
            chips: [
              AgenticChip(
                icon: Icons.sim_card_rounded,
                label: 'Activate eSIM',
                eyebrow: 'now',
                route: '/services',
                tone: const Color(0xFF7E22CE),
              ),
              AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Airport pickup',
                eyebrow: '4 min',
                route: '/services/rides',
                tone: const Color(0xFFEA580C),
              ),
              AgenticChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan to pay',
                eyebrow: 'JPY',
                route: '/wallet/scan',
                tone: const Color(0xFF10B981),
              ),
              AgenticChip(
                icon: Icons.smart_toy_rounded,
                label: 'Ask copilot',
                eyebrow: 'culture',
                route: '/copilot',
                tone: const Color(0xFF6366F1),
              ),
            ],
          ),
          const SectionHeader(
              title: 'Curated for you',
              subtitle: 'Hand-picked for first-time arrivals'),
          for (final c in const [
            (
              Icons.restaurant_rounded,
              'Sukiyabashi Jiro',
              'Ginza · sushi · 4.9'
            ),
            (Icons.hotel_rounded, 'Aman Tokyo', 'Otemachi · 5★ · suite'),
            (
              Icons.local_activity_rounded,
              'TeamLab Borderless',
              'Odaiba · digital art'
            ),
            (Icons.train_rounded, 'JR Pass', '7-day · ¥29,650'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        color: widget.tone.withValues(alpha: 0.18),
                      ),
                      child: Icon(c.$1, color: widget.tone),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$2,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          Text(c.$3, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space3),
          CinematicButton(
            label: 'Browse local mode',
            icon: Icons.location_city_rounded,
            gradient: LinearGradient(
              colors: [
                widget.tone.withValues(alpha: 0.85),
                widget.tone.withValues(alpha: 0.40),
              ],
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              LocalModeSheet.show(
                context,
                city: widget.city,
                country: widget.country,
                flag: widget.flag,
              );
            },
          ),
          const SizedBox(height: AppTokens.space3),
          CinematicButton(
            label: 'Open my Travel OS',
            icon: Icons.hub_rounded,
            gradient: LinearGradient(
              colors: [widget.tone, widget.tone.withValues(alpha: 0.55)],
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      glass: false,
      elevation: PremiumElevation.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
        ],
      ),
    );
  }
}

class _ArrivalPainter extends CustomPainter {
  const _ArrivalPainter({
    required this.tone,
    required this.progress,
    required this.flag,
    required this.city,
  });
  final Color tone;
  final double progress;
  final String flag;
  final String city;

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tone.withValues(alpha: 0.22),
          const Color(0xFF0F172A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Stars
    final rng = math.Random(7);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 60; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height * 0.65;
      canvas.drawCircle(Offset(dx, dy), rng.nextDouble() * 1.4 + 0.2, star);
    }

    // Sun / aurora glow
    final sun = Paint()
      ..shader = RadialGradient(colors: [
        tone.withValues(alpha: 0.55),
        tone.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.7, size.height * 0.35), radius: 140));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.35), 140, sun);

    // Flight arc
    final start = Offset(size.width * 0.05, size.height * 0.78);
    final end = Offset(size.width * 0.95, size.height * 0.42);
    final mid = Offset(
      size.width * 0.5,
      size.height * 0.28,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Animated plane along the curve
    final t = progress;
    final ip = Offset(
      _bezier(start.dx, mid.dx, end.dx, t),
      _bezier(start.dy, mid.dy, end.dy, t),
    );
    final tangent = Offset(
      _bezier(start.dx, mid.dx, end.dx, t + 0.01) - ip.dx,
      _bezier(start.dy, mid.dy, end.dy, t + 0.01) - ip.dy,
    );
    final angle = math.atan2(tangent.dy, tangent.dx);

    canvas.save();
    canvas.translate(ip.dx, ip.dy);
    canvas.rotate(angle);
    final plane = Path()
      ..moveTo(-12, 0)
      ..lineTo(8, -5)
      ..lineTo(8, 5)
      ..close();
    canvas.drawPath(plane, Paint()..color = Colors.white);
    canvas.restore();

    // City label
    final tp = TextPainter(
      text: TextSpan(
        text: '$flag · $city',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(
        canvas, Offset(size.width * 0.5 - tp.width / 2, size.height * 0.78));
  }

  double _bezier(double a, double b, double c, double t) {
    final u = 1 - t;
    return u * u * a + 2 * u * t * b + t * t * c;
  }

  @override
  bool shouldRepaint(covariant _ArrivalPainter old) =>
      old.progress != progress || old.tone != tone || old.city != city;
}
