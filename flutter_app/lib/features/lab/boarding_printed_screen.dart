import 'package:flutter/material.dart';

import '../../cinematic/ceremony/boarding_printed_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class BoardingPrintedScreen extends StatefulWidget {
  const BoardingPrintedScreen({super.key});
  @override
  State<BoardingPrintedScreen> createState() => _BoardingPrintedScreenState();
}

class _BoardingPrintedScreenState extends State<BoardingPrintedScreen> {
  bool _play = false;
  int _replayKey = 0;
  BoardingPrintedPhase _phase = BoardingPrintedPhase.idle;

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
      title: 'Boarding "PRINTED" reveal',
      subtitle: '2.4s · five roller strikes + signature on settle',
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
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: Center(
              child: BoardingPrintedCeremony(
                key: ValueKey(_replayKey),
                play: _play,
                onPresented: () => setState(
                  () => _phase = BoardingPrintedPhase.presented,
                ),
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            children: [
              Pressable(
                onTap: _replay,
                semanticLabel: 'Play boarding printed ceremony',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Os2Text.monoCap(
                    _play ? 'REPLAY · PRINT' : 'PRINT · BOARDING · PASS',
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
            ('0.00 → 0.20', 'SLOT · ARM', 'Gold underline ramps in'),
            ('0.20 → 0.85', 'EXTRUDE', '5 roller strikes · 0.30/0.45/0.60/0.72/0.82'),
            ('0.85 → 0.95', 'SETTLE', '6 px overshoot · signature haptic'),
            ('0.95 → 1.00', 'RIBBON', 'PRINTED · BARAI/D · LH1842 ribbon'),
          ]) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 96),
                    child: Os2Text.monoCap(
                      entry.$3,
                      color: Os2.inkLow,
                      size: Os2.textTiny,
                    ),
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
            'BoardingPrintedCeremony walks four phases in 2.4s: slot arms with a gold underline, pass extrudes upward from the slot while five evenly-spaced selection haptics fire to mimic a roller printer, pass overshoots 6 px then settles with a signature haptic, and the PRINTED ribbon drops in below. The phase mapping is pure (boardingPrintedPhaseFor(t)) so the choreography can be unit-tested without driving a real controller.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
