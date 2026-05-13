import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';

/// CountryIntelligenceLive — declassified dossier substrate.
///
/// Anatomy:
///
///   • Atmosphere backdrop in classified-amber
///   • DossierSubstrate (cream vellum, diagonal "DOSSIER" watermark,
///     embossed border, classification strip)
///   • Country meta tile (flag, name, capital, currency, language)
///   • Advisory tier (LOW / MODERATE / HIGH / EXTREME) with tonal disc
///   • Emergency-services strip (police / fire / medical numbers)
///   • Local intelligence list — currency, time zone, plug, language,
///     tipping, water, customs
///   • Bottom CTAs — "Visa" + "Forex"
class CountryIntelligenceLiveScreen extends ConsumerStatefulWidget {
  const CountryIntelligenceLiveScreen({
    super.key,
    this.countryCode = 'JP',
    this.country = 'Japan',
    this.flag = '🇯🇵',
  });
  final String countryCode;
  final String country;
  final String flag;

  @override
  ConsumerState<CountryIntelligenceLiveScreen> createState() =>
      _CountryIntelligenceLiveScreenState();
}

/// Advisory tier — drives the entire dossier's tonal mood.
enum _AdvisoryTier {
  low,
  moderate,
  high,
  extreme,
}

extension _AdvisoryTierTone on _AdvisoryTier {
  Color get tone {
    switch (this) {
      case _AdvisoryTier.low:
        return const Color(0xFF66D29A); // safe green
      case _AdvisoryTier.moderate:
        return const Color(0xFFF59E0B); // amber
      case _AdvisoryTier.high:
        return const Color(0xFFE17A2A); // burnt orange
      case _AdvisoryTier.extreme:
        return const Color(0xFFE15B5B); // urgent red
    }
  }

  String get label {
    switch (this) {
      case _AdvisoryTier.low:
        return 'ADVISORY · LOW';
      case _AdvisoryTier.moderate:
        return 'ADVISORY · MODERATE';
      case _AdvisoryTier.high:
        return 'ADVISORY · HIGH';
      case _AdvisoryTier.extreme:
        return 'ADVISORY · EXTREME';
    }
  }

  String get body {
    switch (this) {
      case _AdvisoryTier.low:
        return 'NORMAL PRECAUTIONS · LOCAL CUSTOMS APPLY';
      case _AdvisoryTier.moderate:
        return 'EXERCISE INCREASED CAUTION';
      case _AdvisoryTier.high:
        return 'RECONSIDER TRAVEL · MONITOR CHANNELS';
      case _AdvisoryTier.extreme:
        return 'DO NOT TRAVEL · CONTACT EMBASSY';
    }
  }
}

extension _AdvisoryTierCadence on _AdvisoryTier {
  /// Tier → cinematic state ladder. Drives breathing cadence on the
  /// advisory chip + OVI seal: low/moderate breathe slowly (calm),
  /// high accelerates, extreme breathes hardest (urgent).
  LiveSurfaceState get liveState {
    switch (this) {
      case _AdvisoryTier.low:
        return LiveSurfaceState.idle;
      case _AdvisoryTier.moderate:
        return LiveSurfaceState.armed;
      case _AdvisoryTier.high:
        return LiveSurfaceState.active;
      case _AdvisoryTier.extreme:
        return LiveSurfaceState.committed;
    }
  }
}

/// Country → local UTC offset in hours (rough; matches the iso
/// list in [_seedAdvisoryFor]). Used by the local-time strip so the
/// dossier feels rooted in the country's actual clock.
int _utcOffsetFor(String iso) {
  switch (iso.toUpperCase()) {
    case 'JP':
      return 9;
    case 'CH':
    case 'FR':
    case 'DE':
    case 'NO':
      return 1;
    case 'SG':
      return 8;
    case 'IS':
    case 'GB':
      return 0;
    case 'US':
      return -5;
    case 'IN':
      return 5;
    case 'AE':
      return 4;
    case 'EG':
      return 2;
    case 'TR':
      return 3;
    case 'PK':
      return 5;
    case 'AF':
      return 4;
    case 'SY':
      return 3;
    case 'YE':
      return 3;
    default:
      return 0;
  }
}

/// Local time-of-day phase — drives the time chip icon, accent tone,
/// and copy. Each phase carries its own atmospheric signal so the
/// dossier reads "alive with the place" rather than out-of-context.
enum _TimePhase { dawn, day, dusk, night }

extension _TimePhaseTokens on _TimePhase {
  String get label {
    switch (this) {
      case _TimePhase.dawn:
        return 'DAWN';
      case _TimePhase.day:
        return 'DAY';
      case _TimePhase.dusk:
        return 'DUSK';
      case _TimePhase.night:
        return 'NIGHT';
    }
  }

  IconData get icon {
    switch (this) {
      case _TimePhase.dawn:
        return Icons.wb_twilight_rounded;
      case _TimePhase.day:
        return Icons.wb_sunny_rounded;
      case _TimePhase.dusk:
        return Icons.brightness_4_rounded;
      case _TimePhase.night:
        return Icons.nightlight_round;
    }
  }

  Color get accent {
    switch (this) {
      case _TimePhase.dawn:
        return const Color(0xFFF5B27A);
      case _TimePhase.day:
        return const Color(0xFFFFD27A);
      case _TimePhase.dusk:
        return const Color(0xFFE17A2A);
      case _TimePhase.night:
        return const Color(0xFF8FA4D8);
    }
  }
}

_TimePhase _phaseForHour(int hour) {
  if (hour >= 5 && hour < 8) return _TimePhase.dawn;
  if (hour >= 8 && hour < 17) return _TimePhase.day;
  if (hour >= 17 && hour < 20) return _TimePhase.dusk;
  return _TimePhase.night;
}

/// Initial tier inference per country. Used as the seed advisory
/// tier so countries render at a believable level on first open.
_AdvisoryTier _seedAdvisoryFor(String iso) {
  switch (iso.toUpperCase()) {
    case 'JP':
    case 'CH':
    case 'SG':
    case 'NO':
    case 'IS':
      return _AdvisoryTier.low;
    case 'US':
    case 'FR':
    case 'DE':
    case 'AE':
    case 'IN':
      return _AdvisoryTier.moderate;
    case 'EG':
    case 'TR':
    case 'PK':
      return _AdvisoryTier.high;
    case 'AF':
    case 'SY':
    case 'YE':
      return _AdvisoryTier.extreme;
    default:
      return _AdvisoryTier.moderate;
  }
}

class _CountryIntelligenceLiveScreenState
    extends ConsumerState<CountryIntelligenceLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;
  late _AdvisoryTier _tier;
  final _pulseController = LiveDataPulseController();

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _tier = _seedAdvisoryFor(widget.countryCode);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Tap-to-escalate — cycles tier up; when at EXTREME wraps back
  /// to LOW. Each escalation fires a tier-keyed haptic so the user
  /// feels the mood shift, plus a one-shot LiveDataPulse on the
  /// entire dossier so the change reads as a real advisory shift.
  ///
  /// Haptic ladder:
  ///   • de-escalate (wrap to LOW)  → selectionClick
  ///   • escalate to MODERATE       → lightImpact
  ///   • escalate to HIGH           → mediumImpact
  ///   • escalate to EXTREME        → Haptics.signature (cinematic)
  void _cycleTier() {
    final next = _AdvisoryTier
        .values[(_tier.index + 1) % _AdvisoryTier.values.length];
    final escalating = next.index > _tier.index;
    if (!escalating) {
      HapticFeedback.selectionClick();
    } else {
      switch (next) {
        case _AdvisoryTier.moderate:
          HapticFeedback.lightImpact();
          break;
        case _AdvisoryTier.high:
          HapticFeedback.mediumImpact();
          break;
        case _AdvisoryTier.extreme:
          // EXTREME earns the signature triple-pulse — same haptic
          // we use for visa stamp commit and NFC tap. The user feels
          // a genuine "this is serious" beat.
          unawaited(Haptics.signature());
          break;
        case _AdvisoryTier.low:
          HapticFeedback.selectionClick();
          break;
      }
    }
    setState(() => _tier = next);
    // Pulse the full dossier substrate so the mood shift is
    // visually broadcast, not just locally on the chip.
    _pulseController.pulse();
  }

  @override
  Widget build(BuildContext context) {
    return _TonalShift(
      tone: _tier.tone,
      builder: (_, tone) => _buildWith(context, tone),
    );
  }

  Widget _buildWith(BuildContext context, Color tone) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(
          tone: tone,
          country: widget.country,
          flag: widget.flag,
        ),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Visa',
                icon: Icons.book_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/visa-live/${widget.countryCode}');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Forex',
                icon: Icons.currency_exchange_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/forex-live');
                },
              ),
            ),
          ],
        ),
        child: LiveMaterialize(
          child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              LiveDataPulse(
                controller: _pulseController,
                tone: tone,
                child: DossierSubstrate(
                tone: tone,
                child: Stack(
                  children: [
                    // Subliminal GLOBE·ID drift behind the dossier
                    // text. Faint enough that it never competes with
                    // the existing diagonal DOSSIER watermark.
                    Positioned.fill(
                      child: GlobeIdWatermarkDrift(
                        tone: tone,
                        alpha: 0.025,
                        fontSize: 42,
                        period: const Duration(seconds: 56),
                      ),
                    ),
                    // Classified stamp — drops in when the advisory
                    // tier is HIGH or EXTREME. Slight angle, faded
                    // red ink, with a stamp-down scale animation so
                    // it lands like a physical seal rather than
                    // fading in.
                    if (_tier == _AdvisoryTier.high ||
                        _tier == _AdvisoryTier.extreme)
                      Positioned(
                        right: 8,
                        bottom: 14,
                        child: _ClassifiedStamp(
                          extreme: _tier == _AdvisoryTier.extreme,
                        ),
                      ),
                    Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.flag, style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.country.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: 2.6,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Live state pill — now keyed
                                    // to the advisory tier so the
                                    // dossier's nervous system reads
                                    // calm at LOW, armed at MODERATE,
                                    // active at HIGH, committed at
                                    // EXTREME. The breathing cadence
                                    // accelerates with the tier.
                                    LiveStatusPill(
                                      state: _tier.liveState,
                                      tone: tone,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'COUNTRY DOSSIER · LIVE INTELLIGENCE',
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // OVI seal pulses softly at heart-rate
                          // cadence — dossier reads as actively
                          // monitored, not statically printed.
                          NfcPulse(
                            tone: tone,
                            size: 50,
                            child: OviSeal(
                              icon: Icons.shield_rounded,
                              tone: tone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Local-time strip — country's actual clock +
                      // time-of-day phase. Lives between the country
                      // meta tile and the advisory chip; gives the
                      // dossier a "rooted in the place" feel.
                      _LocalContextStrip(
                        iso: widget.countryCode,
                        tone: tone,
                      ),
                      const SizedBox(height: 12),
                      // Advisory tier chip — tap to escalate. Tone
                      // and body text shift smoothly between tiers
                      // via the parent _TonalShift wrapper. The chip
                      // breathes harder as the tier escalates
                      // (idle → committed cadence).
                      GestureDetector(
                        onTap: _cycleTier,
                        child: BreathingHalo(
                          tone: tone,
                          state: _tier.liveState,
                          maxAlpha: _tier == _AdvisoryTier.extreme
                              ? 0.42
                              : _tier == _AdvisoryTier.high
                                  ? 0.30
                                  : 0.18,
                          expand: 6,
                          child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: tone.withValues(alpha: 0.16),
                            border: Border.all(
                              color: tone.withValues(alpha: 0.50),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _tier == _AdvisoryTier.extreme
                                    ? Icons.dangerous_rounded
                                    : Icons.warning_amber_rounded,
                                color: tone,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 240),
                                      child: Text(
                                        _tier.label,
                                        key: ValueKey(_tier.label),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 1.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 240),
                                      child: Text(
                                        _tier.body,
                                        key: ValueKey(_tier.body),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 1.0,
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
                      const SizedBox(height: 14),
                      _Field('CAPITAL', 'Tokyo'),
                      _Field('CURRENCY', 'JPY · ¥ 149.32 / USD'),
                      _Field('LANGUAGE', 'Japanese · English signage'),
                      _Field('TIME ZONE', 'JST · UTC+9 · No DST'),
                      _Field('PLUG', 'Type A / B · 100 V · 50–60 Hz'),
                      _Field('TIPPING', 'Not customary'),
                      _Field('WATER', 'Safe to drink'),
                      _Field('CUSTOMS', 'Conservative · respect quiet zones'),
                    ],
                  ),
                ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: N.s4),
              _EmergencyStrip(tone: tone),
              const SizedBox(height: N.s4),
              _TickerCard(
                items: const [
                  'WEATHER · 18°C · SHIBUYA',
                  'EXCHANGE · 1 USD = 149.32 JPY',
                  'METRO · NORMAL OPS',
                  'POLLUTION · GOOD',
                  'HOSPITALS · ST. LUKE’S NEAREST',
                ],
                tone: tone,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tone,
    required this.country,
    required this.flag,
  });
  final Color tone;
  final String country;
  final String flag;
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
                Text(
                  'LIVE INTEL · ${country.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'GLOBEID FOREIGN OPERATIONS',
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
          Text(flag, style: const TextStyle(fontSize: 26)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyStrip extends StatelessWidget {
  const _EmergencyStrip({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final items = [
      _Em('POLICE', '110', Icons.local_police_rounded, Color(0xFF3B82F6)),
      _Em('FIRE', '119', Icons.local_fire_department_rounded,
          Color(0xFFEF4444)),
      _Em('MEDICAL', '119', Icons.medical_services_rounded, Color(0xFF10B981)),
      _Em('EMBASSY', '+81 03', Icons.flag_rounded, tone),
    ];
    return Row(
      children: [
        for (final i in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: i.tone.withValues(alpha: 0.10),
                  border: Border.all(
                    color: i.tone.withValues(alpha: 0.32),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(i.icon, color: i.tone, size: 16),
                    const SizedBox(height: 6),
                    Text(
                      i.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      i.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Em {
  const _Em(this.label, this.value, this.icon, this.tone);
  final String label;
  final String value;
  final IconData icon;
  final Color tone;
}

class _TickerCard extends StatelessWidget {
  const _TickerCard({required this.items, required this.tone});
  final List<String> items;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: tone, size: 14),
          const SizedBox(width: 8),
          Expanded(child: LiveTicker(items: items, tone: Colors.white)),
        ],
      ),
    );
  }
}

/// Smoothly lerps the tone passed to its builder when the target
/// changes. Used by the country dossier so escalating the advisory
/// tier shifts every tone-bound element (header, foil, halos, chip
/// border, OVI ring) over 800 ms instead of snapping.
class _TonalShift extends StatelessWidget {
  const _TonalShift({
    required this.tone,
    required this.builder,
  });

  final Color tone;
  final Widget Function(BuildContext, Color tone) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: ColorTween(end: tone),
      builder: (context, value, _) => builder(context, value ?? tone),
    );
  }
}

/// Local-time strip — country's actual clock + time-of-day phase
/// (DAWN / DAY / DUSK / NIGHT) + a small accent dot. Self-ticking
/// every 30 seconds so the minute roll feels live.
class _LocalContextStrip extends StatefulWidget {
  const _LocalContextStrip({required this.iso, required this.tone});
  final String iso;
  final Color tone;

  @override
  State<_LocalContextStrip> createState() => _LocalContextStripState();
}

class _LocalContextStripState extends State<_LocalContextStrip> {
  Timer? _tick;
  late DateTime _localNow;

  @override
  void initState() {
    super.initState();
    _localNow = _computeLocalNow();
    // 30s tick — granular enough to see the minute roll over
    // without burning frames.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _localNow = _computeLocalNow());
    });
  }

  DateTime _computeLocalNow() {
    final offset = _utcOffsetFor(widget.iso);
    return DateTime.now().toUtc().add(Duration(hours: offset));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phaseForHour(_localNow.hour);
    final hh = _localNow.hour.toString().padLeft(2, '0');
    final mm = _localNow.minute.toString().padLeft(2, '0');
    final offset = _utcOffsetFor(widget.iso);
    final sign = offset >= 0 ? '+' : '−';
    final off = offset.abs();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Phase glyph in its phase accent — dawn amber, day gold,
          // dusk burnt-orange, night cool blue.
          Icon(phase.icon, color: phase.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            phase.label,
            style: TextStyle(
              color: phase.accent.withValues(alpha: 0.95),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 12,
            color: Colors.black.withValues(alpha: 0.16),
          ),
          const SizedBox(width: 10),
          Text(
            'LOCAL · $hh:$mm',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            'UTC $sign${off.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: widget.tone.withValues(alpha: 0.84),
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// CLASSIFIED stamp — drops onto the dossier when advisory tier
/// crosses into HIGH or EXTREME. Stamp-down animation (scale 1.3 →
/// 1.0, opacity 0 → final, slight angle) so it lands as a physical
/// seal rather than a fade. EXTREME paints with a heavier ink and
/// double-stroked border.
class _ClassifiedStamp extends StatefulWidget {
  const _ClassifiedStamp({required this.extreme});
  final bool extreme;

  @override
  State<_ClassifiedStamp> createState() => _ClassifiedStampState();
}

class _ClassifiedStampState extends State<_ClassifiedStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.extreme
        ? const Color(0xFFC8302E)
        : const Color(0xFFB13A36);
    final finalOpacity = widget.extreme ? 0.78 : 0.62;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Stamp-down physics — starts at scale 1.45 with a wrist-flick
        // rotation of -14°, overshoots through 0.94 at t≈0.7 and
        // settles at 1.0 at -7°. Mimics a real rubber stamp pressed
        // down against the paper and bouncing back fractionally.
        final raw = Curves.easeOutCubic.transform(_ctrl.value);
        final overshoot = raw < 0.7
            ? 1.45 - (0.51 * (raw / 0.7))
            : 0.94 + 0.06 * ((raw - 0.7) / 0.3);
        final scale = overshoot;
        final angleDeg = -14 + (7 * raw);
        final opacity = finalOpacity * raw.clamp(0.0, 1.0);

        // Ink-bleed shadow on impact — paints a soft tinted shadow
        // underneath the stamp body that fades in with the opacity.
        return Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: angleDeg * math.pi / 180,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2.6),
                  borderRadius: BorderRadius.circular(6),
                  color: color.withValues(alpha: 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22 * raw),
                      blurRadius: 14,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CLASSIFIED',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 2.6,
                      ),
                    ),
                    if (widget.extreme)
                      Text(
                        '◆ DO NOT TRAVEL ◆',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                          letterSpacing: 2.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
