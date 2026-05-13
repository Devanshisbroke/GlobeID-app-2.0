import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/live/live_primitives.dart';
import '../../motion/motion.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toast.dart';

/// CustomsDeclarationScreen — arrival customs form simulator.
///
/// Step rail at top, contextual questions per step, decisions persisted
/// in local state. Final step renders a "ready to submit at the kiosk"
/// QR-style stamp + agentic chain into the kiosk simulator and arrival
/// welcome flow.
class CustomsDeclarationScreen extends StatefulWidget {
  const CustomsDeclarationScreen({
    super.key,
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFF6366F1),
  });

  final String country;
  final String flag;
  final Color tone;

  @override
  State<CustomsDeclarationScreen> createState() =>
      _CustomsDeclarationScreenState();
}

class _CustomsDeclarationScreenState extends State<CustomsDeclarationScreen> {
  int _step = 0;
  final Map<int, bool?> _answers = {};
  final TextEditingController _addr =
      TextEditingController(text: 'Aman Tokyo · 1-5-6 Otemachi');
  final TextEditingController _stay = TextEditingController(text: '9 days');

  // Cinematic seal state — when the user commits the declaration
  // (Save & finish), the review card pulses gold and the QR stamp
  // reveals a "GLOBEID · SEALED" overlay. Signature haptic fires at
  // the commit frame.
  bool _isSealed = false;
  DateTime? _sealedAt;
  final LiveDataPulseController _sealPulse = LiveDataPulseController();

  void _commitSeal() {
    if (_isSealed) return;
    setState(() {
      _isSealed = true;
      _sealedAt = DateTime.now();
    });
    Haptics.signature();
    _sealPulse.pulse();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _addr.addListener(_onTextChanged);
    _stay.addListener(_onTextChanged);
  }

  static const _questions = <(IconData, String, String)>[
    (
      Icons.local_pharmacy_rounded,
      'Carrying medicines?',
      'Includes prescriptions, narcotics or restricted substances.'
    ),
    (
      Icons.eco_rounded,
      'Carrying plants, seeds, or animals?',
      'Including wood products and food items.'
    ),
    (
      Icons.payments_rounded,
      'Carrying cash > ¥1,000,000?',
      'Or equivalent in any currency.'
    ),
    (
      Icons.shopping_bag_rounded,
      'Bringing gifts > ¥200,000?',
      'Per traveller exemption.'
    ),
    (
      Icons.dangerous_rounded,
      'Restricted / prohibited items?',
      'Firearms, swords, drugs, counterfeits.'
    ),
  ];

  @override
  void dispose() {
    _addr
      ..removeListener(_onTextChanged)
      ..dispose();
    _stay
      ..removeListener(_onTextChanged)
      ..dispose();
    _sealPulse.dispose();
    super.dispose();
  }

  bool get _onPersonal => _step == 0;
  bool get _onQuestions => _step >= 1 && _step <= _questions.length;
  bool get _onReview => _step == _questions.length + 1;

  bool get _allAnswered =>
      _questions.asMap().keys.every((i) => _answers[i] != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageScaffold(
      title: 'Customs declaration',
      subtitle: '${widget.flag} ${widget.country} · arrival form',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'STEP ${_step + 1} / ${_questions.length + 2}',
              title: _onPersonal
                  ? 'Personal'
                  : _onReview
                      ? 'Ready to submit'
                      : _questions[_step - 1].$2,
              subtitle: _onPersonal
                  ? 'Where will you stay and for how long?'
                  : _onReview
                      ? 'Show this stamp at the kiosk on arrival.'
                      : _questions[_step - 1].$3,
              tone: widget.tone,
              icon: Icons.assignment_rounded,
              flag: widget.flag,
              badges: const [
                HeroBadge(label: 'Auto-fill', icon: Icons.bolt_rounded),
                HeroBadge(label: 'Save offline', icon: Icons.cloud_off_rounded),
                HeroBadge(label: 'Bilingual', icon: Icons.translate_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 50),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Form progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / (_questions.length + 2),
                      minHeight: 8,
                      backgroundColor: widget.tone.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(widget.tone),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          if (_onPersonal) _personalCard(theme),
          if (_onQuestions) _questionCard(theme),
          if (_onReview) _reviewCard(theme),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _step--);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: widget.tone.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              if (_step > 0) const SizedBox(width: AppTokens.space2),
              Expanded(
                child: FilledButton.icon(
                  onPressed: !_canAdvance()
                      ? null
                      : () {
                          if (_onReview) {
                            // Cinematic commit — signature haptic
                            // + sealed overlay + gold pulse on the
                            // review card. Toast follows so the
                            // user sees both the cinematic and
                            // the system confirmation.
                            _commitSeal();
                            AppToast.show(
                              context,
                              title: 'Form saved offline',
                              message: 'Show kiosk on arrival.',
                              tone: AppToastTone.success,
                            );
                          } else {
                            HapticFeedback.lightImpact();
                          }
                          setState(() {
                            if (_onReview) {
                              // already toasted above
                            } else {
                              _step++;
                            }
                          });
                        },
                  icon: Icon(_onReview
                      ? Icons.qr_code_2_rounded
                      : Icons.arrow_forward_rounded),
                  label: Text(_onReview
                      ? (_isSealed ? 'Sealed · GlobeID' : 'Save & finish')
                      : _onPersonal
                          ? 'Start questions'
                          : 'Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.tone,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          const SectionHeader(
              title: 'After arrival',
              subtitle: 'Most travellers chain into these next'),
          AgenticBand(
            title: '',
            chips: [
              AgenticChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Test the kiosk',
                eyebrow: 'sim',
                route: '/kiosk-sim',
                tone: widget.tone,
              ),
              const AgenticChip(
                icon: Icons.flight_land_rounded,
                label: 'Arrival welcome',
                eyebrow: 'after',
                route: '/arrival',
                tone: Color(0xFF7C3AED),
              ),
              const AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Airport pickup',
                eyebrow: 'transit',
                route: '/services/rides',
                tone: Color(0xFFEA580C),
              ),
              const AgenticChip(
                icon: Icons.translate_rounded,
                label: 'Phrasebook',
                eyebrow: 'language',
                route: '/phrasebook',
                tone: Color(0xFFE11D48),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }

  bool _canAdvance() {
    if (_onPersonal) {
      return _addr.text.trim().isNotEmpty && _stay.text.trim().isNotEmpty;
    }
    if (_onQuestions) {
      return _answers[_step - 1] != null;
    }
    return _allAnswered;
  }

  Widget _personalCard(ThemeData theme) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where will you stay?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _addr,
            decoration: InputDecoration(
              hintText: 'Hotel · address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              prefixIcon: Icon(Icons.hotel_rounded, color: widget.tone),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Text('How long?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _stay,
            decoration: InputDecoration(
              hintText: 'Length of stay',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              prefixIcon:
                  Icon(Icons.calendar_today_rounded, color: widget.tone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(ThemeData theme) {
    final i = _step - 1;
    final q = _questions[i];
    final ans = _answers[i];
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.tone.withValues(alpha: 0.18),
            ),
            child: Icon(q.$1, color: widget.tone, size: 28),
          ),
          const SizedBox(height: AppTokens.space3),
          Text(q.$2,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text(q.$3,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              )),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  label: 'No',
                  icon: Icons.close_rounded,
                  selected: ans == false,
                  tone: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _answers[i] = false);
                  },
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: _ChoiceButton(
                  label: 'Yes',
                  icon: Icons.check_rounded,
                  selected: ans == true,
                  tone: const Color(0xFFEA580C),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _answers[i] = true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ThemeData theme) {
    final flagged = _answers.values.where((v) => v == true).length;
    return LiveDataPulse(
      controller: _sealPulse,
      tone: const Color(0xFFD4AF37),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Lock-in shake — fires once when _isSealed flips
                // from false → true. The TweenAnimationBuilder is
                // keyed by the seal state so it re-runs only on the
                // transition. Three damped wobbles + a slight scale
                // overshoot sell the "stamp slams down on paper"
                // moment that lands at the same time as the
                // signature haptic.
                TweenAnimationBuilder<double>(
                  key: ValueKey('customs-seal-shake-$_isSealed'),
                  tween: Tween(begin: _isSealed ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) {
                    final shakeT = (1.0 - v);
                    final wobbleX =
                        math.sin(shakeT * math.pi * 6) * 5 * shakeT;
                    final scale = _isSealed
                        ? (v < 0.4
                            ? 1.0 + 0.16 * (v / 0.4)
                            : 1.16 - 0.16 * ((v - 0.4) / 0.6))
                        : 1.0;
                    return Transform.translate(
                      offset: Offset(wobbleX, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isSealed
                          ? [
                              const Color(0xFFD4AF37),
                              const Color(0xFFE9C75D).withValues(alpha: 0.72),
                            ]
                          : [
                              widget.tone,
                              widget.tone.withValues(alpha: 0.55),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSealed
                                ? const Color(0xFFD4AF37)
                                : widget.tone)
                            .withValues(alpha: 0.32),
                        blurRadius: 28,
                        spreadRadius: -8,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSealed
                            ? Icons.verified_rounded
                            : Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 84,
                      ),
                      Text(
                        _isSealed
                            ? 'GLOBE·ID · SEALED'
                            : 'Ready · stamp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      // SEALED · hh:mm receipt caption — mono-cap
                      // tabular figures, only paints once the seal
                      // commits. Mirrors the visa stamp caption so
                      // the cinematic commits across alive surfaces
                      // share a consistent paper-trail feel.
                      if (_isSealed && _sealedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'SEALED · '
                          '${_sealedAt!.hour.toString().padLeft(2, '0')}'
                          ':${_sealedAt!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 1.6,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ),
                if (_isSealed)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: NfcPulse(
                      tone: const Color(0xFFD4AF37),
                      child: Icon(
                        Icons.nfc_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppTokens.space4),
          Text('Summary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 6),
          _summaryRow('Address', _addr.text),
          _summaryRow('Stay', _stay.text),
          _summaryRow('Flagged',
              '$flagged of ${_questions.length} questions answered yes'),
          if (flagged > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.space3),
              child: Container(
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Officer may pull you aside for a closer look. '
                        'Have receipts handy.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                )),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tone,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? tone : tone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border:
              Border.all(color: tone.withValues(alpha: selected ? 1.0 : 0.4)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.32),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : tone, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : tone,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                )),
          ],
        ),
      ),
    );
  }
}
