import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
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

class _CountryIntelligenceLiveScreenState
    extends ConsumerState<CountryIntelligenceLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFFF59E0B);
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              DossierSubstrate(
                tone: tone,
                child: Padding(
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
                                    // Live state pill — country
                                    // intelligence stays LIVE while
                                    // open, signalling the dossier
                                    // is hydrated with real-time
                                    // data, not a static fact sheet.
                                    LiveStatusPill(
                                      state: LiveSurfaceState.active,
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
                      Container(
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
                            Icon(Icons.warning_amber_rounded,
                                color: tone, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'ADVISORY · LOW',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'NORMAL PRECAUTIONS · LOCAL CUSTOMS APPLY',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
