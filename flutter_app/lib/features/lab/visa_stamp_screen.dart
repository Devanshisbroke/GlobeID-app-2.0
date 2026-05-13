import 'package:flutter/material.dart';

import '../../cinematic/ceremony/visa_stamp_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class VisaStampScreen extends StatefulWidget {
  const VisaStampScreen({super.key});
  @override
  State<VisaStampScreen> createState() => _VisaStampScreenState();
}

class _VisaStampScreenState extends State<VisaStampScreen> {
  bool _play = false;
  int _replayKey = 0;
  VisaStampPhase _phase = VisaStampPhase.idle;
  int _toneIdx = 0;
  static const _tones = [
    Color(0xFFC8932F), // gold
    Color(0xFFB73E3E), // entry red
    Color(0xFF2E5A2E), // exit green
    Color(0xFF1F3C70), // schengen navy
  ];
  static const _toneLabels = ['GOLD', 'RED', 'GREEN', 'NAVY'];

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
      title: 'Visa stamp ceremony',
      subtitle: '4-frame · 1.7s · signature haptic on press',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          Container(
            height: 420,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: Center(
              child: VisaStampCeremony(
                key: ValueKey(_replayKey),
                play: _play,
                tone: _tones[_toneIdx],
                onCommitted: () => setState(
                  () => _phase = VisaStampPhase.committed,
                ),
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            children: [
              Pressable(
                onTap: _replay,
                semanticLabel: 'Play visa stamp ceremony',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Os2Text.monoCap(
                    _play ? 'REPLAY · STAMP' : 'PLAY · STAMP',
                    color: Os2.canvas,
                    size: Os2.textTiny,
                  ),
                ),
              ),
              const Spacer(),
              Os2Text.monoCap(
                'PHASE · ${_phase.handle}',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Container(
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
                  'TONE · PICKER',
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: Os2.space3),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _tones.length; i++)
                      Pressable(
                        onTap: () => setState(() => _toneIdx = i),
                        semanticLabel: 'Select ${_toneLabels[i]} tone',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _toneIdx == i
                                ? _tones[i].withValues(alpha: 0.20)
                                : null,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _tones[i].withValues(
                                  alpha: _toneIdx == i ? 0.62 : 0.4),
                            ),
                          ),
                          child: Os2Text.monoCap(
                            _toneLabels[i],
                            color: _tones[i],
                            size: Os2.textTiny,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Os2.space3),
          const _PhaseLadderCard(),
          const SizedBox(height: Os2.space3),
          const _ContractCard(),
        ],
      ),
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
            ('0.00 → 0.23', 'INK · LOAD', '0.39s'),
            ('0.23 → 0.53', 'ARC · SWING', '0.51s'),
            ('0.53 → 0.65', 'PRESS · FLASH', '0.20s · HAPTIC'),
            ('0.65 → 1.00', 'BLEED · SETTLE', '0.60s'),
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
                  SizedBox(
                    width: 124,
                    child: Os2Text.monoCap(
                      entry.$2,
                      color: Os2.inkBright,
                      size: Os2.textTiny,
                    ),
                  ),
                  Os2Text.monoCap(
                    entry.$3,
                    color: Os2.inkLow,
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
            'VisaStampCeremony walks four frames in 1.7s: ink loads on the stamp face, arc swings down on a wrist-rotation, ink press blooms a gold radial flash, ink bleed settles into the final print. Signature haptic fires at the start of the press frame so the user feels the strike. The tone is parameterized (gold / red / green / navy) so different corridors carry different stamp inks.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
