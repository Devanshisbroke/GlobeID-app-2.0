import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';

/// VisaLive — a digital twin of a real government-issued visa.
///
/// Surface anatomy:
///
///   • Atmosphere backdrop + drifting stardust (LiveCanvas)
///   • Sealed booklet cover with embossed crest and country flag
///   • Tap-to-open: cover lifts away with a 3D flip; inside is the
///     full visa page with:
///       — VISA TYPE eyebrow + country crest
///       — Photo placeholder + bearer details (NAME, DOB, NATIONALITY)
///       — Issue / expiry strip + days remaining countdown
///       — Holographic OVI seal that shifts hue
///       — Big MRZ-style strip at the foot
///   • Live "DAYS · HOURS · MIN · SEC remaining" ticking countdown
///   • Tilt parallax across the entire booklet
///   • Bottom CTAs — "Open in Wallet" + "Show to officer"
///
/// Lives at `/visa-live/:countryCode` for any sovereign. Falls back to
/// the bearer's current Japan visa when no country code is passed.
class VisaLiveScreen extends ConsumerStatefulWidget {
  const VisaLiveScreen({
    super.key,
    this.countryCode = 'JP',
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.visaType = 'Tourist · Multiple Entry',
    this.tone = const Color(0xFFE11D48),
    this.maxStay = '90 days',
    this.issueDate = '2025-06-12',
    this.expiryDate = '2027-06-11',
    this.holder = 'AARON KUMAR',
    this.dob = '1991-04-22',
    this.nationality = 'IND',
    this.docNumber = 'P9382041',
    this.visaNumber = 'JPN-V-92841',
  });

  final String countryCode;
  final String country;
  final String flag;
  final String visaType;
  final Color tone;
  final String maxStay;
  final String issueDate;
  final String expiryDate;
  final String holder;
  final String dob;
  final String nationality;
  final String docNumber;
  final String visaNumber;

  @override
  ConsumerState<VisaLiveScreen> createState() => _VisaLiveScreenState();
}

class _VisaLiveScreenState extends ConsumerState<VisaLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _open;
  late final AnimationController _foil;
  late final AnimationController _stampDrop;
  Offset _tilt = Offset.zero;
  bool _isOpen = false;
  bool _stamped = false;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _stampDrop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _open.dispose();
    _foil.dispose();
    _stampDrop.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (_isOpen) {
      // Closing the booklet — soft close haptic.
      Haptics.close();
      _open.reverse();
      setState(() => _isOpen = false);
    } else {
      // Opening the visa booklet is a hero reveal — pages turning,
      // foil catching light. Signature triple-pulse on the open,
      // then heavy confirm when the consular stamp drops.
      Haptics.signature();
      _open.forward().then((_) {
        if (mounted && !_stamped) {
          _stamped = true;
          _stampDrop.forward();
          Haptics.confirm();
        }
      });
      setState(() => _isOpen = true);
    }
  }

  DateTime get _expiry => DateTime.parse(widget.expiryDate);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: widget.tone,
        statusBar: _StatusStrip(
          country: widget.country,
          flag: widget.flag,
          tone: widget.tone,
          expiry: _expiry,
        ),
        bottomBar: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: _isOpen ? 1.0 : 0.55,
          child: Row(
            children: [
              Expanded(
                child: LiveCta(
                  label: 'Show to officer',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
              const SizedBox(width: N.s3),
              Expanded(
                child: LiveCta(
                  label: 'Wallet',
                  icon: Icons.account_balance_wallet_rounded,
                  secondary: true,
                  onTap: () => context.push('/wallet'),
                ),
              ),
            ],
          ),
        ),
        child: LiveMaterialize(
          child: GestureDetector(
          onTap: _toggleOpen,
          onPanUpdate: (d) {
            setState(() {
              _tilt = Offset(
                (_tilt.dx + d.delta.dx * 0.015).clamp(-0.6, 0.6),
                (_tilt.dy + d.delta.dy * 0.015).clamp(-0.6, 0.6),
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _tilt = Offset.zero);
          },
          onVerticalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -300 && !_isOpen) _toggleOpen();
            if (v > 300 && _isOpen) _toggleOpen();
          },
          child: RepaintBoundary(
            child: AnimatedBuilder(
            animation: _open,
            builder: (_, __) {
              final t = Curves.easeOutCubic.transform(_open.value);
              return TiltParallax(
                tilt: _tilt,
                depth: 6 + 4 * t,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.86,
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backside / page — visible only as the cover opens.
                      Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0014)
                          ..rotateY(0)
                          ..scaleByDouble(
                            0.97 + 0.03 * t,
                            0.97 + 0.03 * t,
                            1.0,
                            1.0,
                          ),
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: _VisaPage(
                            country: widget.country,
                            flag: widget.flag,
                            tone: widget.tone,
                            visaType: widget.visaType,
                            maxStay: widget.maxStay,
                            issueDate: widget.issueDate,
                            expiryDate: widget.expiryDate,
                            holder: widget.holder,
                            dob: widget.dob,
                            nationality: widget.nationality,
                            docNumber: widget.docNumber,
                            visaNumber: widget.visaNumber,
                            stampAnim: _stampDrop,
                            foilAnim: _foil,
                            // Inner page state ladder — ACTIVE while
                            // the consular stamp is still in flight,
                            // COMMITTED once it lands.
                            liveState: _stamped
                                ? LiveSurfaceState.committed
                                : LiveSurfaceState.active,
                          ),
                        ),
                      ),
                      // Cover — flips left on open.
                      Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0016)
                          ..rotateY(-math.pi * 0.92 * t),
                        child: Opacity(
                          opacity: (1 - t * 0.96).clamp(0.0, 1.0),
                          // Breathing tonal halo behind the cover that
                          // shifts cadence with the state ladder —
                          // slow at ARMED, faster at ACTIVE.
                          child: BreathingHalo(
                            tone: widget.tone,
                            maxAlpha: 0.22,
                            expand: 18,
                            state: _isOpen
                                ? LiveSurfaceState.active
                                : LiveSurfaceState.armed,
                            child: _Cover(
                            country: widget.country,
                            flag: widget.flag,
                            tone: widget.tone,
                            foilAnim: _foil,
                            // Cover state ladder — IDLE before user
                            // intent, ARMED once the booklet starts
                            // animating open.
                            liveState: _isOpen
                                ? LiveSurfaceState.active
                                : LiveSurfaceState.armed,
                            tilt: _tilt,
                          ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ),
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// STATUS STRIP — top-pinned readiness ribbon
// ─────────────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.country,
    required this.flag,
    required this.tone,
    required this.expiry,
  });
  final String country;
  final String flag;
  final Color tone;
  final DateTime expiry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE VISA · $country',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                LiveCountdown(
                  target: expiry,
                  builder: (_, d) {
                    final days = d.inDays;
                    final hours = d.inHours % 24;
                    // <14 days reads as urgent red; expired locks
                    // to red. The standard ticker stays in the
                    // country tone otherwise.
                    final urgent = !d.isNegative && days < 14;
                    final tickerColor = d.isNegative
                        ? const Color(0xFFE15B5B)
                        : urgent
                            ? const Color(0xFFE15B5B)
                            : tone.withValues(alpha: 0.92);
                    Widget label = Text(
                      d.isNegative
                          ? 'EXPIRED'
                          : 'VALID · $days D · ${hours.toString().padLeft(2, '0')} H',
                      style: TextStyle(
                        color: tickerColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                    if (urgent || d.isNegative) {
                      // Urgent breathing cadence — auto-pulses
                      // continuously to draw the eye toward the
                      // days-remaining indicator.
                      label = BreathingHalo(
                        tone: const Color(0xFFE15B5B),
                        state: LiveSurfaceState.active,
                        maxAlpha: 0.32,
                        expand: 6,
                        child: label,
                      );
                    }
                    return label;
                  },
                ),
              ],
            ),
          ),
          StatusPill(
            icon: Icons.verified_rounded,
            label: 'SEALED',
            tone: const Color(0xFF10B981),
            dense: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// COVER — sealed booklet with embossed crest and country flag
// ─────────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  const _Cover({
    required this.country,
    required this.flag,
    required this.tone,
    required this.foilAnim,
    this.liveState = LiveSurfaceState.armed,
    this.tilt = Offset.zero,
  });
  final String country;
  final String flag;
  final Color tone;
  final AnimationController foilAnim;
  final LiveSurfaceState liveState;

  /// User pan offset — plumbed through to the cover foil so the
  /// holographic sweep follows the user's tilt the way real
  /// passport-grade security ink catches the light.
  final Offset tilt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Leather-style base — country tone.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.black, tone, 0.50)!,
                  Color.lerp(Colors.black, tone, 0.30)!,
                  Color.lerp(Colors.black, tone, 0.12)!,
                ],
              ),
            ),
          ),
          // Leather grain.
          CustomPaint(painter: _LeatherGrainPainter()),
          // Foil shimmer — passport-grade iridescent + secondary
          // counter-sweep so the booklet cover reads as authentic
          // optically-variable security ink. Tilt-driven so the
          // user's pan steers the highlight bands.
          HolographicFoil(
            style: HolographicFoilStyle.iridescent,
            secondarySweep: true,
            tilt: tilt,
            child: Container(color: Colors.transparent),
          ),
          // Embossed border.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ),
          // Title block.
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GLOBEID · VISA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  country.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    letterSpacing: 2.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AUTHORISED · MULTIPLE ENTRY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.8,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            N.tierGoldHi.withValues(alpha: 0.85),
                            N.tierGold.withValues(alpha: 0.65),
                            N.tierGoldLow.withValues(alpha: 0.85),
                            N.tierGoldHi.withValues(alpha: 0.85),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          flag,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'SEALED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Hint at bottom.
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: foilAnim,
              builder: (_, __) {
                final shimmer =
                    0.6 + 0.4 * (0.5 + 0.5 * math.sin(foilAnim.value * 6.28));
                return Center(
                  child: Text(
                    'TAP TO OPEN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: shimmer),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 4.2,
                    ),
                  ),
                );
              },
            ),
          ),
          // Live state pill — driven by the booklet's actual
          // gesture state. ARMED when closed, ACTIVE while open
          // and animating, COMMITTED on the inner page.
          Positioned(
            top: 20,
            right: 24,
            child: LiveStatusPill(state: liveState),
          ),
        ],
      ),
    );
  }
}

class _LeatherGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);
    final paint = Paint();
    for (var i = 0; i < 850; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      paint.color = (rng.nextBool() ? Colors.white : Colors.black)
          .withValues(alpha: rng.nextDouble() * 0.08);
      canvas.drawCircle(Offset(x, y), 0.4 + rng.nextDouble() * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────
// VISA PAGE — full open-book interior on visa paper
// ─────────────────────────────────────────────────────────────────────

class _VisaPage extends StatelessWidget {
  const _VisaPage({
    required this.country,
    required this.flag,
    required this.tone,
    this.liveState = LiveSurfaceState.active,
    required this.visaType,
    required this.maxStay,
    required this.issueDate,
    required this.expiryDate,
    required this.holder,
    required this.dob,
    required this.nationality,
    required this.docNumber,
    required this.visaNumber,
    required this.stampAnim,
    required this.foilAnim,
  });
  final String country;
  final String flag;
  final Color tone;
  final String visaType;
  final String maxStay;
  final String issueDate;
  final String expiryDate;
  final String holder;
  final String dob;
  final String nationality;
  final String docNumber;
  final String visaNumber;
  final AnimationController stampAnim;
  final AnimationController foilAnim;
  final LiveSurfaceState liveState;

  String _mrz1() {
    final hLast = holder.split(' ').last;
    final hFirst = holder.split(' ').first;
    return 'V<$nationality${hLast.toUpperCase()}<<${hFirst.toUpperCase()}<<<<<<<<<<<<<';
  }

  String _mrz2() {
    final exp = expiryDate.replaceAll('-', '').substring(2);
    return '$docNumber<5${nationality}9104221M$exp<<<<<<<<<<<<<<06';
  }

  @override
  Widget build(BuildContext context) {
    return VisaSubstrate(
      tone: tone,
      crestGlyph: flag,
      cornerCode: 'GBL · $country',
      child: Stack(
        children: [
          // Subliminal GLOBE·ID watermark drift behind the visa
          // page — 38 s cycle, alpha 0.03, fontSize matched to the
          // visa page proportions.
          Positioned.fill(
            child: GlobeIdWatermarkDrift(
              tone: tone,
              alpha: 0.03,
              fontSize: 48,
              period: const Duration(seconds: 38),
            ),
          ),
          // Header — VISA TYPE strip.
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VISA TYPE',
                      style: TextStyle(
                        color: tone.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visaType.toUpperCase(),
                      style: TextStyle(
                        color: Color.lerp(Colors.black, tone, 0.85)!,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  flag,
                  style: const TextStyle(fontSize: 26),
                ),
              ],
            ),
          ),
          // Photo block + bearer fields.
          Positioned(
            top: 58,
            left: 14,
            right: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoPanel(tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'SURNAME / NOM',
                        value: holder.split(' ').last,
                        tone: tone,
                      ),
                      const SizedBox(height: 6),
                      _Field(
                        label: 'GIVEN NAMES / PRÉNOMS',
                        value: holder.split(' ').first,
                        tone: tone,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              label: 'DOB',
                              value: dob,
                              tone: tone,
                            ),
                          ),
                          Expanded(
                            child: _Field(
                              label: 'NATIONALITY',
                              value: nationality,
                              tone: tone,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Issue / expiry / max stay.
          Positioned(
            top: 178,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tone.withValues(alpha: 0.22),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'ISSUED',
                      value: issueDate,
                      tone: tone,
                    ),
                  ),
                  Expanded(
                    child: _Field(
                      label: 'EXPIRES',
                      value: expiryDate,
                      tone: tone,
                    ),
                  ),
                  Expanded(
                    child: _Field(
                      label: 'MAX STAY',
                      value: maxStay,
                      tone: tone,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Holographic OVI stamp — drops in once.
          Positioned(
            top: 230,
            right: 24,
            child: AnimatedBuilder(
              animation: stampAnim,
              builder: (_, __) {
                final t = Curves.easeOutBack.transform(stampAnim.value);
                return Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: -math.pi / 14,
                      child: NfcPulse(
                        tone: tone,
                        size: 70,
                        rings: 2,
                        maxAlpha: 0.42,
                        child: OviSeal(
                          icon: Icons.verified_rounded,
                          tone: tone,
                          size: 70,
                          label: 'SEALED',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Visa number + holo foil strip.
          Positioned(
            bottom: 70,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'VISA NO.',
                    value: visaNumber,
                    tone: tone,
                  ),
                ),
                Expanded(
                  child: _Field(
                    label: 'DOC NO.',
                    value: docNumber,
                    tone: tone,
                  ),
                ),
                Expanded(
                  child: HolographicFoil(
                    duration: const Duration(seconds: 4),
                    style: HolographicFoilStyle.iridescent,
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tone.withValues(alpha: 0.42),
                            N.tierGold.withValues(alpha: 0.40),
                            tone.withValues(alpha: 0.42),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // MRZ strip.
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: MrzStrip(
              lines: [_mrz1(), _mrz2()],
              tone: Colors.black.withValues(alpha: 0.9),
            ),
          ),
          // Cinematic state pill — visa booklet promotes from
          // ARMED on the cover to ACTIVE on first open, then
          // COMMITTED once the consular stamp drops on the page.
          Positioned(
            top: 12,
            right: 14,
            child: LiveStatusPill(state: liveState),
          ),
        ],
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({required this.tone});
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Color.lerp(Colors.white, tone, 0.20)!,
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Silhouette portrait.
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(Colors.black, tone, 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                ClipPath(
                  clipper: _ShoulderClipper(),
                  child: Container(
                    width: 56,
                    height: 38,
                    color: Color.lerp(Colors.black, tone, 0.55),
                  ),
                ),
              ],
            ),
          ),
          // CHIP corner.
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 14,
              height: 10,
              decoration: BoxDecoration(
                color: N.tierGold,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          // Radial holographic security overlay on the photo —
          // concentrated highlight that orbits the photo center,
          // hero-grade optically-variable layer over the bearer.
          Positioned.fill(
            child: IgnorePointer(
              child: HolographicFoil(
                duration: const Duration(seconds: 7),
                style: HolographicFoilStyle.iridescent,
                radial: true,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoulderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.45);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.15,
      size.width * 0.5,
      size.height * 0.1,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.15,
      size.width,
      size.height * 0.45,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.tone,
  });
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tone.withValues(alpha: 0.65),
            fontWeight: FontWeight.w900,
            fontSize: 7,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: Color.lerp(Colors.black, tone, 0.85)!,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
