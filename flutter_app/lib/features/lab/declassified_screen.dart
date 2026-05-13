import 'package:flutter/material.dart';

import '../../cinematic/ceremony/declassified_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class DeclassifiedScreen extends StatefulWidget {
  const DeclassifiedScreen({super.key});
  @override
  State<DeclassifiedScreen> createState() => _DeclassifiedScreenState();
}

class _DeclassifiedScreenState extends State<DeclassifiedScreen> {
  bool _play = false;
  int _replayKey = 0;
  DeclassifiedPhase _phase = DeclassifiedPhase.idle;
  int _countryIdx = 0;

  static const _countries = [
    ('ITALY', 'GREEN · LEVEL · 1'),
    ('JAPAN', 'GREEN · LEVEL · 1'),
    ('TÜRKIYE', 'AMBER · LEVEL · 2'),
    ('MYANMAR', 'RED · LEVEL · 4'),
  ];

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
    final country = _countries[_countryIdx];
    return PageScaffold(
      title: 'Country dossier "DECLASSIFIED"',
      subtitle: '3.2s · cover lift · three CLASSIFIED strikes · reveal',
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
            height: 480,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: Center(
              child: DeclassifiedCeremony(
                key: ValueKey('$_replayKey-${country.$1}'),
                play: _play,
                country: country.$1,
                dossierLines: [
                  'CASE · OFFICER · TRAVEL · DESK',
                  'BEARER · CLEARED · FOR · ENTRY',
                  'ADVISORY · ${country.$2}',
                ],
                onDeclassified: () => setState(
                  () => _phase = DeclassifiedPhase.declassified,
                ),
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            children: [
              Pressable(
                onTap: _replay,
                semanticLabel: 'Play declassified ceremony',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Os2Text.monoCap(
                    _play ? 'REPLAY · DECLASSIFY' : 'DECLASSIFY · DOSSIER',
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
                  'COUNTRY · PICKER',
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: Os2.space2),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _countries.length; i++)
                      Pressable(
                        onTap: () => setState(() => _countryIdx = i),
                        semanticLabel: 'Pick ${_countries[i].$1}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: i == _countryIdx
                                ? Os2.goldDeep.withValues(alpha: 0.18)
                                : Os2.floor2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: i == _countryIdx
                                  ? Os2.goldDeep
                                  : Os2.hairline,
                            ),
                          ),
                          child: Os2Text.monoCap(
                            _countries[i].$1,
                            color: i == _countryIdx
                                ? Os2.goldDeep
                                : Os2.inkMid,
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
                  ('0.00 → 0.18', 'COVER · LIFT', 'Folder cover hinges off the dossier'),
                  ('0.18 → 0.40', 'STAMP · ONE', 'Top-left CLASSIFIED · overshoot 1.45 → 1.0'),
                  ('0.40 → 0.55', 'STAMP · TWO', 'Top-right CLASSIFIED · overshoot · signature haptic'),
                  ('0.55 → 0.70', 'STAMP · THREE', 'Bottom-centre CLASSIFIED · overshoot'),
                  ('0.70 → 1.00', 'DOSSIER · REVEAL', 'Body fades in · green CLEARED dot'),
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
