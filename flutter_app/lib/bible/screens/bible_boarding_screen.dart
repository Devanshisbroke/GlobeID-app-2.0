import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_buttons.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';
import '../living/bible_spatial_depth.dart';
import '../materials/bible_foil.dart';
import '../materials/bible_paper.dart';

/// GlobeID — **Boarding Pass Live** (§11.7 _The Cinematic Gate_).
///
/// Registers: Anticipation. Spine: Travel.
///
/// The boarding pass is a paper ticket on Vellum Bone, with a foil
/// chip stripe that tilts under gyro. The barcode breathes (opacity
/// 0.85 ↔ 1.0 over 2.4s). Real boarding-pass apps slam the brightness
/// to max on present-mode — we honour the same affordance via the
/// `brightness override` chip.
class BibleBoardingScreen extends StatefulWidget {
  const BibleBoardingScreen({super.key});

  @override
  State<BibleBoardingScreen> createState() => _BibleBoardingScreenState();
}

class _BibleBoardingScreenState extends State<BibleBoardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _countdown;
  Duration _toBoarding = const Duration(minutes: 23, seconds: 41);

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: B.barcodeBreath,
    )..repeat();
    _countdown = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick)
      ..repeat();
  }

  void _tick() {
    if (_countdown.value > 0.99) {
      setState(() {
        if (_toBoarding.inSeconds > 0) {
          _toBoarding -= const Duration(seconds: 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.anticipation,
      tone: B.jetCyan.withValues(alpha: 0.10),
      density: BDensity.concourse,
      eyebrow: '— boarding pass —',
      title: 'British Airways · BA 005',
      trailing: BibleStatusPill(
        label: 'boarding',
        value: _formatDuration(_toBoarding),
        tone: B.runwayAmber,
        breathing: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PassCard(breath: _breath),
          const SizedBox(height: B.space4),
          _ActionRow(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'gate intelligence',
            title: 'Right now',
          ),
          _GateGrid(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'connections',
            title: 'After landing',
          ),
          _AfterLandingRail(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'journey strip',
            title: 'You are here',
          ),
          _JourneyStrip(),
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m : $s';
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({required this.breath});
  final AnimationController breath;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 540,
      child: BibleSpatialDepth(
        maxTravelPx: 6,
        slots: [
          // Paper booklet substrate.
          BiblePaper(
            radius: 28,
            substrate: B.vellumBone,
            elevation: 1.2,
            padding: EdgeInsets.zero,
            child: const _PaperContents(),
          ),
          // Foil chip stripe across the top.
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                height: 36,
                child: BibleFoil(
                  radius: 18,
                  tone: B.jetCyan,
                  hologram: true,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: BText.eyebrow(
                      'globeid · iata 5.0 boarding · ba 005',
                      color: const Color(0xFF052532),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Barcode breath overlay.
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: breath,
                builder: (_, __) {
                  final phase =
                      math.sin(breath.value * 2 * math.pi) * 0.5 + 0.5;
                  return Opacity(
                    opacity: 0.85 + 0.15 * phase,
                    child: const _Barcode(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperContents extends StatelessWidget {
  const _PaperContents();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(B.space5, 72, B.space5, 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From / To
          Row(
            children: [
              _Airport(
                iata: 'LHR',
                city: 'London',
                time: '09:42',
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 1,
                color: const Color(0x331A1305),
              ),
              const SizedBox(width: B.space2),
              const Icon(
                Icons.flight_rounded,
                size: 20,
                color: Color(0xFF1A1305),
              ),
              const SizedBox(width: B.space2),
              Container(
                width: 60,
                height: 1,
                color: const Color(0x331A1305),
              ),
              const Spacer(),
              _Airport(
                iata: 'NRT',
                city: 'Tokyo',
                time: '07:42 +1',
              ),
            ],
          ),
          const SizedBox(height: B.space5),
          Row(
            children: [
              Expanded(
                child: _BoardField(
                  label: 'passenger',
                  value: 'D · BARAI',
                ),
              ),
              Expanded(
                child: _BoardField(
                  label: 'seat',
                  value: '23A',
                ),
              ),
              Expanded(
                child: _BoardField(
                  label: 'class',
                  value: 'business',
                ),
              ),
            ],
          ),
          const SizedBox(height: B.space3),
          Row(
            children: [
              Expanded(
                child: _BoardField(
                  label: 'gate',
                  value: 'B47',
                ),
              ),
              Expanded(
                child: _BoardField(
                  label: 'boarding',
                  value: '09:12 GMT',
                ),
              ),
              Expanded(
                child: _BoardField(
                  label: 'group',
                  value: '02',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Airport extends StatelessWidget {
  const _Airport({required this.iata, required this.city, required this.time});
  final String iata;
  final String city;
  final String time;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BText.display(iata, size: 32, color: const Color(0xFF1A1305)),
        BText.eyebrow(city, color: const Color(0xFF6A5742)),
        const SizedBox(height: B.space1),
        BText.solari(time, size: 14, color: const Color(0xFF1A1305)),
      ],
    );
  }
}

class _BoardField extends StatelessWidget {
  const _BoardField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BText.eyebrow(label, color: const Color(0xFF6A5742)),
        const SizedBox(height: 2),
        BText.mono(value, color: const Color(0xFF1A1305), size: 14),
      ],
    );
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: B.space2),
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarcodePainter(),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1305);
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final widths = const [1.4, 2.6, 1.0, 3.4, 1.8, 1.0, 2.0];
      final w = widths[i % widths.length];
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w + 1;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BibleCinematicButton(
            label: 'Brightness',
            icon: Icons.brightness_high_rounded,
            tone: B.jetCyan,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: B.space3),
        Expanded(
          child: BibleMagneticButton(
            label: 'Wallet',
            icon: Icons.add_to_home_screen_rounded,
            tone: B.foilGold,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _GateGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _GateTile(
                eyebrow: 'gate',
                value: 'B47',
                caption: 'Terminal 5 · Pier B',
                tone: B.jetCyan,
                icon: Icons.location_on_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _GateTile(
                eyebrow: 'security wait',
                value: '12m',
                caption: 'Fast-track · 4m',
                tone: B.equatorTeal,
                icon: Icons.security_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B.space3),
        Row(
          children: const [
            Expanded(
              child: _GateTile(
                eyebrow: 'aircraft',
                value: 'B777-300ER',
                caption: 'G-STBL · 8y old',
                tone: B.runwayAmber,
                icon: Icons.airplane_ticket_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _GateTile(
                eyebrow: 'turbulence',
                value: 'light',
                caption: 'Above 38k ft · steady',
                tone: B.auroraViolet,
                icon: Icons.air_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GateTile extends StatelessWidget {
  const _GateTile({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.tone,
    required this.icon,
  });
  final String eyebrow;
  final String value;
  final String caption;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: B.space1),
              BText.eyebrow(eyebrow, color: tone),
            ],
          ),
          const SizedBox(height: B.space3),
          BText.solari(value, size: 22, color: B.inkOnDarkHigh),
          const SizedBox(height: B.space1),
          BText.caption(caption, color: B.inkOnDarkMid),
        ],
      ),
    );
  }
}

class _AfterLandingRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _ConnectCard(
            eyebrow: 'ride',
            title: 'Hire booked',
            caption: 'Tokyo Limo · Hiroshi K · ETA 17m',
            tone: B.honeyAmber,
            icon: Icons.local_taxi_rounded,
          ),
          _ConnectCard(
            eyebrow: 'esim',
            title: 'NTT 5G — 8GB',
            caption: 'Auto-activates after landing',
            tone: B.jetCyan,
            icon: Icons.sim_card_rounded,
          ),
          _ConnectCard(
            eyebrow: 'lounge',
            title: 'JAL Sakura',
            caption: 'Reserved pod · 2h slot',
            tone: B.foilGold,
            icon: Icons.weekend_rounded,
          ),
          _ConnectCard(
            eyebrow: 'hotel',
            title: 'Aman Tokyo',
            caption: 'Early check-in confirmed',
            tone: B.velvetMauve,
            icon: Icons.hotel_rounded,
          ),
        ],
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.eyebrow,
    required this.title,
    required this.caption,
    required this.tone,
    required this.icon,
  });
  final String eyebrow;
  final String title;
  final String caption;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: B.space3),
      child: SizedBox(
        width: 240,
        child: BiblePremiumCard(
          tone: tone,
          padding: const EdgeInsets.all(B.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: tone),
                  const SizedBox(width: B.space1),
                  BText.eyebrow(eyebrow, color: tone),
                ],
              ),
              const SizedBox(height: B.space2),
              BText.title(title, size: 14),
              const SizedBox(height: B.space1),
              BText.caption(caption, color: B.inkOnDarkMid, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.jetCyan,
      padding: const EdgeInsets.all(B.space4),
      child: BibleTimeline(
        tone: B.jetCyan,
        nodes: const [
          BibleTimelineNode(
            title: 'Home departure',
            caption: 'Uber · 06:18 GMT',
            trailing: 'done',
            state: BiblePipState.settled,
          ),
          BibleTimelineNode(
            title: 'LHR · check-in',
            caption: 'Online · cleared',
            trailing: 'done',
            state: BiblePipState.settled,
          ),
          BibleTimelineNode(
            title: 'Security · Fast-track',
            caption: '4m wait',
            trailing: 'now',
            state: BiblePipState.active,
          ),
          BibleTimelineNode(
            title: 'Gate B47 boarding',
            caption: '09:12 GMT',
            trailing: '+23m',
          ),
          BibleTimelineNode(
            title: 'Takeoff · LHR',
            caption: '09:42 GMT',
            trailing: '+53m',
          ),
          BibleTimelineNode(
            title: 'Arrival · NRT',
            caption: 'Tomorrow 07:42 JST',
            trailing: '+13h',
          ),
        ],
      ),
    );
  }
}
