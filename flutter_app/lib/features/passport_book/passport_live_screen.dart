import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/document_substrate.dart';
import '../../cinematic/live/live_primitives.dart';
import '../../data/models/user_profile.dart';
import '../../motion/motion.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/pressable.dart';
import '../insights/insights_provider.dart';
import '../user/user_provider.dart';

/// PassportLive — a digital twin of a real biometric passport book.
///
/// Renders an immersive full-screen passport experience:
///
///   • Closed cover with embossed crest + holographic foil sweep
///   • Tap or swipe-up to open: cover lifts away with a 3D flip
///   • Inner pages stack and parallax under your finger
///   • Bio-data page (photo, name, nationality, passport #, MRZ)
///   • Stamp pages where each visit lands as a real ink stamp,
///     with depth shadow and animated ink-down on first reveal
///   • Holographic security mesh layer over every page
///
/// Built with custom painters + AnimatedBuilder + matrix transforms;
/// no extra packages required.
class PassportLiveScreen extends ConsumerStatefulWidget {
  const PassportLiveScreen({super.key});
  @override
  ConsumerState<PassportLiveScreen> createState() => _PassportLiveScreenState();
}

class _PassportLiveScreenState extends ConsumerState<PassportLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _open;
  late final AnimationController _foil;
  late final PageController _pages;
  bool _isOpen = false;
  int _pageIndex = 0;

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
    _pages = PageController();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _open.dispose();
    _foil.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (_isOpen) {
      // Closing the passport — soft close haptic, cover folds back.
      Haptics.close();
      _open.reverse();
    } else {
      // Opening the passport is the hero reveal of the entire Live
      // family — the bearer page (photo, name, DOB, MRZ) materialises.
      // Signature triple-pulse so the moment lands cinematic, not
      // utilitarian.
      Haptics.signature();
      _open.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final loyalty = ref.watch(loyaltyProvider);
    final stamps = loyalty.maybeWhen(
      data: (m) =>
          ((m['stamps'] as List?) ?? const []).cast<Map<String, dynamic>>(),
      orElse: () => const <Map<String, dynamic>>[],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050714),
        body: Stack(
          children: [
            // ── Atmosphere backdrop ─────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF1B1F4A).withValues(alpha: 0.7),
                      const Color(0xFF050714),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            // ── Star dust ───────────────────────────────────────────
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _foil,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _StarDustPainter(t: _foil.value),
                  ),
                ),
              ),
            ),

            // ── Passport book ───────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _toggleOpen,
                onVerticalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -300 && !_isOpen) _toggleOpen();
                  if (v > 300 && _isOpen) _toggleOpen();
                },
                child: AnimatedBuilder(
                  animation: _open,
                  builder: (_, __) {
                    final t = Curves.easeOutCubic.transform(_open.value);
                    final scale = 0.92 + 0.08 * t;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateX(-0.15 * (1 - t))
                        ..scaleByDouble(scale, scale, 1.0, 1.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.86,
                        height: MediaQuery.of(context).size.height * 0.74,
                        child: Stack(
                          children: [
                            // ── Inner pages (revealed on open) ──────────
                            Positioned.fill(
                              child: Opacity(
                                opacity: t,
                                child: _InnerPages(
                                  user: user.profile,
                                  stamps: stamps,
                                  pages: _pages,
                                  onPage: (i) => setState(() => _pageIndex = i),
                                  foil: _foil,
                                ),
                              ),
                            ),
                            // ── Silk bookmark ribbon (only while open) ──
                            // Hangs off the top-right edge of the open
                            // passport, ~6° flutter. Tells the eye this
                            // is a real bound book.
                            if (t > 0.6)
                              Positioned(
                                top: 0,
                                right: 28,
                                child: Opacity(
                                  opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                                  child: const PassportRibbonBookmark(
                                    length: 64,
                                    width: 8,
                                  ),
                                ),
                              ),
                            // ── Cover (flips up on open) ────────────────
                            Positioned.fill(
                              child: Transform(
                                alignment: Alignment.topCenter,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014)
                                  ..rotateX(-math.pi * t),
                                child: Opacity(
                                  opacity: 1 - (t * 0.95).clamp(0.0, 1.0),
                                  child: _Cover(
                                    foil: _foil,
                                    liveState: _isOpen
                                        ? LiveSurfaceState.active
                                        : LiveSurfaceState.armed,
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

            // ── Top chrome ──────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isOpen
                        ? Container(
                            key: const ValueKey('p'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusFull),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              'Page ${_pageIndex + 1} / ${1 + _stampPages(stamps)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('h')),
                  ),
                ],
              ),
            ),

            // ── Bottom hint ─────────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _open,
                builder: (_, __) {
                  return Opacity(
                    opacity: 1 - _open.value,
                    child: Center(
                      child: Pressable(
                        onTap: _toggleOpen,
                        child: AnimatedAppearance(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFD4AF37),
                                Color(0xFFE9C75D),
                              ]),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swipe_up_rounded,
                                    color: Colors.black87, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Tap to open',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _stampPages(List<Map<String, dynamic>> stamps) =>
    (stamps.length / 4).ceil();

// ─────────────────────────────────────────────────────────────────────
// COVER
// ─────────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  const _Cover({
    required this.foil,
    this.liveState = LiveSurfaceState.armed,
  });
  final AnimationController foil;
  final LiveSurfaceState liveState;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Leather base ─────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1A36),
                  Color(0xFF071027),
                  Color(0xFF050B1B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.16),
                  blurRadius: 48,
                  spreadRadius: -8,
                ),
              ],
            ),
          ),
          // ── Foil shimmer sweep ───────────────────────────────────
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: foil,
              builder: (_, __) {
                final t = foil.value;
                return CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: _FoilSweepPainter(t: t),
                );
              },
            ),
          ),
          // ── Texture grain ────────────────────────────────────────
          // Static painter — wrap in RepaintBoundary so it's rasterised
          // once and re-used as a layer for every frame.
          RepaintBoundary(
            child: CustomPaint(
              isComplex: true,
              painter: _GrainPainter(),
            ),
          ),
          // ── Subliminal GLOBE·ID watermark drift ──────────────────
          // 40s drift cycle, alpha 0.04 — subliminal proof of
          // "manufactured by GlobeID" without ever competing with the
          // foil or crest. Below conscious threshold.
          const GlobeIdWatermarkDrift(
            alpha: 0.04,
            fontSize: 56,
          ),
          // ── Crest / title ────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GoldText(
                  text: 'GLOBEID',
                  size: 28,
                  letterSpacing: 6,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 1.2,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                ),
                const SizedBox(height: 24),
                _Crest(foil: foil),
                const SizedBox(height: 24),
                _GoldText(
                  text: 'PASSPORT',
                  size: 22,
                  letterSpacing: 8,
                ),
                const SizedBox(height: 6),
                _GoldText(
                  text: 'GLOBAL · IDENTITY · TRAVEL',
                  size: 9,
                  letterSpacing: 4,
                ),
              ],
            ),
          ),
          // ── Bottom: biometric chip + serial ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biometric chip — pulses on a heart-rate cadence
                    // so the chip reads as a live secure element
                    // rather than a printed icon.
                    const NfcPulse(
                      tone: Color(0xFFD4AF37),
                      size: 32,
                      rings: 2,
                      maxAlpha: 0.45,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFF8E7128),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GoldText(text: 'BIOMETRIC', size: 9, letterSpacing: 3),
                  ],
                ),
              ],
            ),
          ),
          // Live state pill — driven by the actual gesture state.
          // ARMED before user taps; ACTIVE while the passport is
          // open. Signature triple-pulse fires on _toggleOpen.
          Positioned(
            top: 24,
            right: 24,
            child: LiveStatusPill(state: liveState),
          ),
        ],
      ),
    );
  }
}

class _GoldText extends StatelessWidget {
  const _GoldText({
    required this.text,
    required this.size,
    required this.letterSpacing,
  });
  final String text;
  final double size;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Color(0xFFE9C75D),
          Color(0xFFD4AF37),
          Color(0xFFB8902B),
          Color(0xFFE9C75D),
        ],
      ).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size,
          letterSpacing: letterSpacing,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.foil});
  final AnimationController foil;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: foil,
        builder: (_, __) => SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            isComplex: true,
            willChange: true,
            painter: _CrestPainter(t: foil.value),
          ),
        ),
      ),
    );
  }
}

class _CrestPainter extends CustomPainter {
  _CrestPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    // Outer wreath ring.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(t * 2 * math.pi),
        colors: const [
          Color(0xFFE9C75D),
          Color(0xFFB8902B),
          Color(0xFFE9C75D),
          Color(0xFFB8902B),
          Color(0xFFE9C75D),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r - 4, ring);
    // Inner ring.
    canvas.drawCircle(
        c,
        r - 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.6));
    // Globe meridian + parallel lines.
    final mp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85);
    final inner = r - 18;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: inner * 2, height: inner * 2 * 0.45),
      mp,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: inner * 2 * 0.6, height: inner * 2),
      mp,
    );
    canvas.drawCircle(c, inner, mp);
    // 12 spokes.
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      final p1 = Offset(c.dx + math.cos(a) * inner, c.dy + math.sin(a) * inner);
      final p2 = Offset(
        c.dx + math.cos(a) * (inner - 6),
        c.dy + math.sin(a) * (inner - 6),
      );
      canvas.drawLine(p2, p1, mp..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _CrestPainter old) => old.t != t;
}

class _FoilSweepPainter extends CustomPainter {
  _FoilSweepPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    // A diagonal shimmer band sweeping across the cover.
    final w = size.width;
    final h = size.height;
    final dx = (t * 2 - 1) * w * 1.6;
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFFD4AF37).withValues(alpha: 0.0),
          const Color(0xFFE9C75D).withValues(alpha: 0.32),
          const Color(0xFFD4AF37).withValues(alpha: 0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(dx, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
  }

  @override
  bool shouldRepaint(covariant _FoilSweepPainter old) => old.t != t;
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.012);
    for (var i = 0; i < 400; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────
// INNER PAGES
// ─────────────────────────────────────────────────────────────────────

class _InnerPages extends StatelessWidget {
  const _InnerPages({
    required this.user,
    required this.stamps,
    required this.pages,
    required this.onPage,
    required this.foil,
  });
  final UserProfile user;
  final List<Map<String, dynamic>> stamps;
  final PageController pages;
  final ValueChanged<int> onPage;
  final AnimationController foil;

  @override
  Widget build(BuildContext context) {
    final pageCount = 1 + _stampPages(stamps);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF6E8),
              Color(0xFFF1EAD3),
              Color(0xFFE6DCBF),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
        child: Stack(
          children: [
            // Security mesh underneath.
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: foil,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _SecurityMeshPainter(t: foil.value),
                  ),
                ),
              ),
            ),
            PageView.builder(
              controller: pages,
              onPageChanged: (i) {
                HapticFeedback.lightImpact();
                onPage(i);
              },
              itemCount: pageCount,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return DocumentSubstrate(
                    type: SubstrateType.passport,
                    showMicrotext: true,
                    child: _BioPage(user: user, foil: foil),
                  );
                }
                final start = (i - 1) * 4;
                final slice = stamps
                    .sublist(start, math.min(start + 4, stamps.length))
                    .toList();
                return DocumentSubstrate(
                  type: SubstrateType.passport,
                  child: _StampPage(stamps: slice, pageNum: i + 1),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityMeshPainter extends CustomPainter {
  _SecurityMeshPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = const Color(0xFF2C3E80).withValues(alpha: 0.07);
    const step = 18.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x + t * step, 0),
        Offset(x + size.height + t * step, size.height),
        p,
      );
    }
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x - t * step, 0),
        Offset(x - size.height - t * step, size.height),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityMeshPainter old) => old.t != t;
}

// ── Bio-data page ────────────────────────────────────────────────────

class _BioPage extends StatelessWidget {
  const _BioPage({required this.user, required this.foil});
  final UserProfile user;
  final AnimationController foil;

  @override
  Widget build(BuildContext context) {
    final mrz = _mrz(user);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BioField(label: 'Type', value: 'P'),
              const SizedBox(width: 14),
              _BioField(
                label: 'Country',
                value: user.nationality.isEmpty
                    ? 'GLB'
                    : _iso3From(user.nationality),
              ),
              const Spacer(),
              _BioField(
                label: 'No.',
                value: user.passportNumber.isEmpty
                    ? 'GID-0001'
                    : user.passportNumber,
                accent: const Color(0xFFB8902B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Holographic photo.
              Container(
                width: 92,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFB8902B).withValues(alpha: 0.5),
                    width: 1,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF152042), Color(0xFF0B1330)],
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Text(
                        user.name.isEmpty
                            ? '👤'
                            : user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: foil,
                        builder: (_, __) => CustomPaint(
                          isComplex: true,
                          willChange: true,
                          painter: _PhotoHologramPainter(t: foil.value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BioField(
                      label: 'Surname',
                      value: _surname(user.name).toUpperCase(),
                    ),
                    const SizedBox(height: 8),
                    _BioField(
                      label: 'Given names',
                      value: _given(user.name).toUpperCase(),
                    ),
                    const SizedBox(height: 8),
                    _BioField(
                      label: 'Nationality',
                      value: user.nationality.isEmpty
                          ? 'GLOBAL'
                          : user.nationality.toUpperCase(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const _BioField(label: 'Sex', value: 'X'),
                        const SizedBox(width: 14),
                        _BioField(
                          label: 'DOB',
                          value: _dob(user.userId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // ── Holographic GlobeID strip ───────────────────────────────
          AnimatedBuilder(
            animation: foil,
            builder: (_, __) => Container(
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment(-1 + foil.value * 2, 0),
                  end: Alignment(1 + foil.value * 2, 0),
                  colors: const [
                    Color(0xFFD4AF37),
                    Color(0xFFE9C75D),
                    Color(0xFFE9F1F9),
                    Color(0xFFB8902B),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '◆ GLOBEID · GLOBAL · BIOMETRIC ◆',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── MRZ band ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD0AA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mrz
                  .map(
                    (line) => Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: Colors.black87,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoHologramPainter extends CustomPainter {
  _PhotoHologramPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal hologram lines that drift.
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.16);
    for (var i = 0; i < 14; i++) {
      final y = (i * 12 + t * 36) % (size.height + 30) - 16;
      canvas.drawLine(Offset(-8, y), Offset(size.width + 8, y - 18), p);
    }
    // Soft rainbow flash sweep.
    final shader = LinearGradient(
      colors: [
        Colors.transparent,
        const Color(0xFFFF8FE0).withValues(alpha: 0.16),
        const Color(0xFF8FE5FF).withValues(alpha: 0.18),
        Colors.transparent,
      ],
      stops: const [0, 0.45, 0.55, 1],
      begin: Alignment(-1 + t * 2, -1),
      end: Alignment(0 + t * 2, 1),
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _PhotoHologramPainter old) => old.t != t;
}

class _BioField extends StatelessWidget {
  const _BioField({
    required this.label,
    required this.value,
    this.accent,
  });
  final String label;
  final String value;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF6E5C2A),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: accent ?? const Color(0xFF1B1F4A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}

// ── Stamp page ───────────────────────────────────────────────────────

class _StampPage extends StatelessWidget {
  const _StampPage({required this.stamps, required this.pageNum});
  final List<Map<String, dynamic>> stamps;
  final int pageNum;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              'PAGE $pageNum',
              style: const TextStyle(
                color: Color(0xFF6E5C2A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Center(
            child: Wrap(
              spacing: 18,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                for (final s in stamps) _Stamp(data: s),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Text(
              '◆ GLOBEID PASSPORT  ·  PAGE $pageNum  ·  AUTHORISED INK',
              style: TextStyle(
                color: const Color(0xFF6E5C2A).withValues(alpha: 0.85),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatefulWidget {
  const _Stamp({required this.data});
  final Map<String, dynamic> data;
  @override
  State<_Stamp> createState() => _StampState();
}

class _StampState extends State<_Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _ink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(
        milliseconds: 100 + (widget.data.hashCode.abs() % 6) * 80,
      ),
      () {
        if (mounted) _ink.forward();
      },
    );
  }

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final country =
        ((widget.data['country'] as String?) ?? 'WORLD').toUpperCase();
    final code = ((widget.data['airport'] ?? widget.data['code']) as String?) ??
        country.substring(0, math.min(3, country.length));
    final issued = (widget.data['issuedAt'] as String?) ?? '';
    final tone = _stampTone(country);
    final rot = ((country.hashCode % 12) - 6) * math.pi / 180;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ink,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_ink.value);
          return Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: 0.6 + 0.4 * t,
              child: Opacity(
                opacity: t,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tone, width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: tone.withValues(alpha: 0.34),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tone.withValues(alpha: 0.65),
                            width: 1.0,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            code,
                            style: TextStyle(
                              color: tone,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            country.length > 9
                                ? country.substring(0, 9)
                                : country,
                            style: TextStyle(
                              color: tone,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(width: 24, height: 1, color: tone),
                          const SizedBox(height: 2),
                          if (issued.isNotEmpty)
                            Text(
                              issued,
                              style: TextStyle(
                                color: tone.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                        ],
                      ),
                      // Speckle ink texture.
                      CustomPaint(
                        size: const Size(108, 108),
                        painter:
                            _InkSpecklePainter(seed: country.hashCode),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InkSpecklePainter extends CustomPainter {
  _InkSpecklePainter({required this.seed});
  final int seed;
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final p = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (var i = 0; i < 28; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4;
      canvas.drawCircle(Offset(dx, dy), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _InkSpecklePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────
// STAR DUST
// ─────────────────────────────────────────────────────────────────────

class _StarDustPainter extends CustomPainter {
  _StarDustPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final tw = (math.sin(t * 2 * math.pi + i) + 1) / 2;
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.05 + 0.18 * tw);
      canvas.drawCircle(Offset(x, y), 0.7 + tw * 0.6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────

String _surname(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return name;
  return parts.last;
}

String _given(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return name;
  return parts.sublist(0, parts.length - 1).join(' ');
}

String _iso3From(String s) {
  final clean = s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  if (clean.length >= 3) return clean.substring(0, 3);
  return 'GLB';
}

String _dob(String userId) {
  // Deterministic DOB seeded by userId.
  var h = 0;
  for (final c in userId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final d = 1 + (h % 28);
  final m = 1 + ((h ~/ 28) % 12);
  final y = 1985 + ((h ~/ (28 * 12)) % 18);
  return '${d.toString().padLeft(2, '0')} '
      '${_monAbbr(m)} '
      '$y';
}

String _monAbbr(int m) {
  const xs = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return xs[(m - 1).clamp(0, 11)];
}

List<String> _mrz(UserProfile u) {
  final country = u.nationality.isEmpty ? 'GLB' : _iso3From(u.nationality);
  final num = u.passportNumber.isEmpty ? 'GID0001' : u.passportNumber;
  final surname = _surname(u.name).toUpperCase().replaceAll(' ', '<');
  final given = _given(u.name).toUpperCase().replaceAll(' ', '<');
  final l1 = 'P<$country$surname<<$given'.padRight(44, '<').substring(0, 44);
  final l2 = '${num.padRight(9, '<').substring(0, 9)}'
          '0$country'
          '${_dob(u.userId).replaceAll(' ', '').substring(0, 6)}'
          '0X3001017<<<<<<<<<<<<<<<06'
      .padRight(44, '<')
      .substring(0, 44);
  return [l1, l2];
}

Color _stampTone(String country) {
  // Hash country to a stamp ink colour.
  var h = 0;
  for (final c in country.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  const palette = [
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];
  return palette[h % palette.length];
}
