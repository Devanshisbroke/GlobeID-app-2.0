import 'package:flutter/material.dart';

import '../../cinematic/ceremony/velvet_rope_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class VelvetRopeScreen extends StatefulWidget {
  const VelvetRopeScreen({super.key});
  @override
  State<VelvetRopeScreen> createState() => _VelvetRopeScreenState();
}

class _VelvetRopeScreenState extends State<VelvetRopeScreen> {
  bool _play = false;
  int _replayKey = 0;
  VelvetRopePhase _phase = VelvetRopePhase.closed;
  int _tierIdx = 0;

  static const _tiers = ['PLATINUM', 'GOLD', 'STAR · ALLIANCE', 'PRIORITY'];

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
      title: 'Lounge admission velvet rope',
      subtitle: '2.8s · rope lift · world dim · member reveal',
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
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: Center(
              child: VelvetRopeCeremony(
                key: ValueKey('$_replayKey-${_tiers[_tierIdx]}'),
                play: _play,
                tier: _tiers[_tierIdx],
                onAdmitted: () => setState(
                  () => _phase = VelvetRopePhase.admitted,
                ),
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            children: [
              Pressable(
                onTap: _replay,
                semanticLabel: 'Play velvet rope ceremony',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Os2Text.monoCap(
                    _play ? 'REPLAY · ADMIT' : 'ADMIT · BEARER',
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
                  'TIER · PICKER',
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: Os2.space2),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _tiers.length; i++)
                      Pressable(
                        onTap: () => setState(() => _tierIdx = i),
                        semanticLabel: 'Pick ${_tiers[i]} tier',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: i == _tierIdx
                                ? Os2.goldDeep.withValues(alpha: 0.18)
                                : Os2.floor2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  i == _tierIdx ? Os2.goldDeep : Os2.hairline,
                            ),
                          ),
                          child: Os2Text.monoCap(
                            _tiers[i],
                            color: i == _tierIdx ? Os2.goldDeep : Os2.inkMid,
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
                  'PHASE · LADDER',
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: Os2.space2),
                for (final entry in const [
                  ('0.00 → 0.16', 'BRASS · ARM', 'Brass stanchions arm in foil-gold'),
                  ('0.16 → 0.55', 'ROPE · LIFT', 'Catenary unfurls · selection haptic'),
                  ('0.55 → 0.75', 'WORLD · DIM', 'Interior fades through OLED scrim'),
                  ('0.75 → 1.00', 'MEMBER · REVEAL', 'Card blooms · signature haptic'),
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
          ),
        ],
      ),
    );
  }
}
