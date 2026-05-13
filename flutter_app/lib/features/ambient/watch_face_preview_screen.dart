import 'package:flutter/material.dart';

import '../../cinematic/ambient/watch_face_preview.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// `/ambient/watch` — preview gallery for the GlobeID watchOS
/// & Wear OS face complications. Shows the round watch case + an
/// anchored complication, then the 4 form factors at their full
/// dimensions.
class WatchFacePreviewScreen extends StatelessWidget {
  const WatchFacePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const model = WatchComplicationModel(
      flightCode: 'LH 401',
      gate: 'B27',
      boardingIn: Duration(minutes: 18),
      origin: 'FRA',
      destination: 'OSL',
      trustScore: 842,
    );

    return PageScaffold(
      title: 'Watch face',
      subtitle: 'watchOS · Wear OS · complications',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: const [
          _Eyebrow('STENCIL · MODULAR LARGE'),
          SizedBox(height: Os2.space3),
          Center(
            child: WatchFaceStencil(
              anchor: WatchAnchor.center,
              complication: WatchComplicationPreview(
                model: model,
                form: WatchComplicationForm.modularLarge,
              ),
            ),
          ),
          SizedBox(height: Os2.space6),
          _Eyebrow('FORMS'),
          SizedBox(height: Os2.space3),
          _FormTile(
            handle: 'CIRCULAR · 50pt',
            description:
                'Single-glyph face complication — gold pill with the boarding countdown. Lives in the corner of an Infograph face.',
            preview: WatchComplicationPreview(
              model: model,
              form: WatchComplicationForm.circular,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'INLINE',
            description:
                'Inline bezel complication — flight code · gate · countdown on a single row, fits the curved bezel of an Infograph face.',
            preview: WatchComplicationPreview(
              model: model,
              form: WatchComplicationForm.inline,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'MODULAR · SMALL',
            description:
                'Square stack — eyebrow + countdown + gate handle. Standard 84pt complication slot.',
            preview: WatchComplicationPreview(
              model: model,
              form: WatchComplicationForm.modularSmall,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'MODULAR · LARGE',
            description:
                'Full-width modular face — eyebrow + countdown chip + origin → destination headline + flight code.',
            preview: WatchComplicationPreview(
              model: model,
              form: WatchComplicationForm.modularLarge,
            ),
          ),
          SizedBox(height: Os2.space6),
          _IntegrationCard(),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Os2Text.monoCap(label, color: Os2.goldDeep, size: Os2.textTiny);
  }
}

class _FormTile extends StatelessWidget {
  const _FormTile({
    required this.handle,
    required this.description,
    required this.preview,
  });
  final String handle;
  final String description;
  final Widget preview;
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
          Row(
            children: [
              Os2Text.monoCap(
                handle,
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'WATCHKIT',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Center(child: preview),
          const SizedBox(height: Os2.space3),
          Os2Text.body(description, color: Os2.inkMid, size: Os2.textSm),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard();
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
            'NATIVE · INTEGRATION',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'iOS — ClockKit (`CLKComplicationFamily.circularSmall`, `.utilitarianLarge`, `.modularSmall`, `.modularLarge`). Android — Wear OS `ComplicationData` with the same four shapes mapped to `SmallImage`, `LongText`, `RangedValue` data types. Updates: boarding push every 60s in the 90 min window before scheduled departure, idle 6 h refresh otherwise.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
