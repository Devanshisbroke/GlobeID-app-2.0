import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';

/// TransitPassesLive — stacked transit-card deck.
///
/// Anatomy:
///
///   • Atmosphere backdrop in indigo-violet (the metro tone)
///   • Card deck: Suica, Pasmo, Tokyo Metro Pass — fans out, swipe to
///     bring one forward. Each rendered with `TransitCardSubstrate`
///     (PETG shine, curved highlight, NFC ring).
///   • Active card lifts with TiltParallax + HolographicFoil.
///   • Balance + last-tap strip beneath the deck.
///   • "TAP" button — triggers ripple + NFC tap pulse animation.
///   • Bottom CTAs — "Top up" + "Open navigation".
class TransitPassesLiveScreen extends ConsumerStatefulWidget {
  const TransitPassesLiveScreen({super.key});

  @override
  ConsumerState<TransitPassesLiveScreen> createState() =>
      _TransitPassesLiveScreenState();
}

class _TransitPassesLiveScreenState
    extends ConsumerState<TransitPassesLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;
  late final AnimationController _tap;
  late final PageController _pages;
  int _index = 0;
  Offset _tilt = Offset.zero;

  static final _cards = [
    _Card('Suica', '¥ 4,820', 'Tap: TOKYO 12:42', Color(0xFF22C55E), '🚇'),
    _Card('Pasmo', '¥ 2,140', 'Tap: SHIBUYA 09:18', Color(0xFFEF4444), '🚉'),
    _Card('Tokyo Metro Pass', '24 h · 18h left', 'Activated 14:02',
        Color(0xFF8B5CF6), '🚆'),
    _Card('Narita Express', 'PASS · NRT → SHN', '14:42 reserved',
        Color(0xFFF59E0B), '🚄'),
  ];

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _pages = PageController(viewportFraction: 0.74);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    _tap.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _cards[_index];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: active.tone,
        statusBar: _Header(tone: active.tone),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Top up',
                icon: Icons.add_circle_outline_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/wallet');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Navigation',
                icon: Icons.alt_route_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/navigation-live');
                },
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            _BalanceRow(card: active),
            const SizedBox(height: N.s4),
            Expanded(
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _tilt = Offset(
                      (_tilt.dx + d.delta.dx * 0.02).clamp(-0.4, 0.4),
                      (_tilt.dy + d.delta.dy * 0.02).clamp(-0.4, 0.4),
                    );
                  });
                },
                onPanEnd: (_) => setState(() => _tilt = Offset.zero),
                child: PageView.builder(
                  controller: _pages,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _cards.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (_, i) {
                    final card = _cards[i];
                    return AnimatedBuilder(
                      animation: _pages,
                      builder: (_, child) {
                        var p = i.toDouble();
                        if (_pages.position.haveDimensions) {
                          p = _pages.page ?? i.toDouble();
                        }
                        final delta = (i - p).abs();
                        final scale = (1.0 - delta * 0.10).clamp(0.82, 1.0);
                        final rot = (i - p) * 0.16;
                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0014)
                                ..rotateY(rot),
                              child: TiltParallax(
                                tilt: _tilt,
                                depth: 6,
                                child: child ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: _TransitCard(card: card, foilAnim: _foil),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: N.s4),
            _TapButton(
              tone: active.tone,
              onTap: () {
                // Simulated NFC tap — the cinematic moment for a
                // transit card. Signature triple-pulse so it lands
                // as a real-world contactless commit.
                Haptics.signature();
                _tap.forward(from: 0);
              },
              anim: _tap,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card {
  const _Card(this.label, this.balance, this.lastTap, this.tone, this.glyph);
  final String label;
  final String balance;
  final String lastTap;
  final Color tone;
  final String glyph;
}

class _Header extends StatelessWidget {
  const _Header({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: N.s3),
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
                const Text(
                  'LIVE TRANSIT · WALLET',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'TAP TO PAY · OFFLINE READY',
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            icon: Icons.nfc_rounded,
            label: 'NFC',
            tone: tone,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.card});
  final _Card card;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(card.glyph, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.lastTap,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            card.balance,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.6,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitCard extends StatelessWidget {
  const _TransitCard({required this.card, required this.foilAnim});
  final _Card card;
  final AnimationController foilAnim;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1.58, // standard credit-card aspect ratio
        child: LiveLift(
          tone: card.tone,
          child: TransitCardSubstrate(
          tone: card.tone,
          child: Stack(
            children: [
              // Transit cards are digital credentials — aurora foil
              // (cyan + violet + gold) makes the active card read as
              // a live NFC chip rather than printed plastic.
              Positioned.fill(
                child: HolographicFoil(
                  duration: const Duration(seconds: 5),
                  style: HolographicFoilStyle.aurora,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 14,
                left: 18,
                child: Row(
                  children: [
                    Text(card.glyph, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 8),
                    Text(
                      card.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              // NFC chip — pulses at heart-rate cadence so the card
              // reads as awake and ready to tap. Lives top-right
              // where a real transit card carries its chip.
              Positioned(
                top: 10,
                right: 10,
                child: NfcPulse(
                  tone: card.tone,
                  size: 44,
                  child: Icon(
                    Icons.contactless_rounded,
                    color: card.tone.withValues(alpha: 0.92),
                    size: 22,
                  ),
                ),
              ),
              // Live state pill — pulses with the cinematic ladder
              // intensity. Lives below the NFC chip on its own row.
              const Positioned(
                top: 56,
                right: 10,
                child: LiveStatusPill(state: LiveSurfaceState.active),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BALANCE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.balance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.6,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 0.5,
                        ),
                      ),
                      child: const Text(
                        'GLOBEID',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _TapButton extends StatelessWidget {
  const _TapButton({
    required this.tone,
    required this.onTap,
    required this.anim,
  });
  final Color tone;
  final VoidCallback onTap;
  final AnimationController anim;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          final t = anim.value;
          return SizedBox(
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple ring.
                Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Container(
                    width: 80 + t * 110,
                    height: 80 + t * 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tone.withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                // Centre button.
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.22),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.60),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.nfc_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
