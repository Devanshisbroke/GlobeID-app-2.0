import 'package:flutter/material.dart';

import '../../cinematic/ceremony/passport_opening_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class PassportCeremonyScreen extends StatefulWidget {
  const PassportCeremonyScreen({super.key});
  @override
  State<PassportCeremonyScreen> createState() =>
      _PassportCeremonyScreenState();
}

class _PassportCeremonyScreenState extends State<PassportCeremonyScreen> {
  bool _play = false;
  int _replayKey = 0;
  PassportCeremonyPhase _phase = PassportCeremonyPhase.closed;

  void _replay() {
    setState(() {
      _play = false;
      _replayKey++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _play = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Passport opening ceremony',
      subtitle: '3-second cinematic · signature haptic at 0.78',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Os2.rCard),
              child: PassportOpeningCeremony(
                key: ValueKey(_replayKey),
                play: _play,
                bearer: _BearerPage(),
                onSettled: () => setState(
                  () => _phase = PassportCeremonyPhase.settled,
                ),
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          _CtaRow(
            play: _play,
            onPlay: _replay,
            phase: _phase,
          ),
          const SizedBox(height: Os2.space4),
          const _PhaseLadderCard(),
          const SizedBox(height: Os2.space3),
          const _ContractCard(),
        ],
      ),
    );
  }
}

class _BearerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6CF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.32),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'BEARER · PAGE',
            color: const Color(0xFF6A5314),
            size: Os2.textTiny,
          ),
          const SizedBox(height: 18),
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFD9C696),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF6A5314).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 42,
              color: Color(0xFF6A5314),
            ),
          ),
          const SizedBox(height: 18),
          Os2Text.display(
            'DEVANSH',
            color: const Color(0xFF1A1A1F),
            size: Os2.textXl,
          ),
          const SizedBox(height: 2),
          Os2Text.display(
            'BARAI',
            color: const Color(0xFF1A1A1F),
            size: Os2.textLg,
          ),
          const SizedBox(height: 18),
          Os2Text.monoCap(
            'NATIONALITY · INDIAN',
            color: const Color(0xFF6A5314),
            size: Os2.textTiny,
          ),
          const SizedBox(height: 4),
          Os2Text.monoCap(
            'DOB · 08 · JUL · 2003',
            color: const Color(0xFF6A5314),
            size: Os2.textTiny,
          ),
          const Spacer(),
          Os2Text.watermark(
            'GLOBE · ID',
            color: const Color(0xFF6A5314).withValues(alpha: 0.34),
          ),
        ],
      ),
    );
  }
}

class _CtaRow extends StatelessWidget {
  const _CtaRow({
    required this.play,
    required this.onPlay,
    required this.phase,
  });
  final bool play;
  final VoidCallback onPlay;
  final PassportCeremonyPhase phase;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: onPlay,
          semanticLabel: 'Play passport opening ceremony',
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              gradient: Os2.foilGoldHero,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Os2Text.monoCap(
              play ? 'REPLAY · CEREMONY' : 'PLAY · CEREMONY',
              color: Os2.canvas,
              size: Os2.textTiny,
            ),
          ),
        ),
        const Spacer(),
        Os2Text.monoCap(
          'PHASE · ${phase.handle}',
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

class _PhaseLadderCard extends StatelessWidget {
  const _PhaseLadderCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'PHASE · LADDER',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          for (final entry in const [
            ('0.00 → 0.18', 'SUBSTRATE · DAWN'),
            ('0.18 → 0.46', 'FOIL · SWEEP'),
            ('0.46 → 0.66', 'EMBOSS · SETTLE'),
            ('0.66 → 1.00', 'BEARER · REVEAL'),
            ('1.00', 'SETTLED'),
          ]) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Os2Text.monoCap(
                      entry.$1,
                      color: Os2.inkMid,
                      size: Os2.textTiny,
                    ),
                  ),
                  Os2Text.monoCap(
                    entry.$2,
                    color: Os2.inkBright,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'CONTRACT',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'PassportOpeningCeremony plays from 0 → 1 when its play flag flips true. Five visual phases (substrate dawn, foil sweep, emboss settle, bearer reveal, settled) walk in lock-step with the progress value. Signature haptic fires once at the 0.78 lock-in moment so the bearer reveal carries the weight of a real document. The host owns the trigger; this primitive does not assume "first ever open" state.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
