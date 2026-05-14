import 'package:flutter/material.dart';

import '../../cinematic/ambient/lock_screen_preview.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// `/ambient/lock-screen` — preview gallery for the GlobeID lock
/// screen widgets + Always-On surfaces.
class LockScreenPreviewScreen extends StatelessWidget {
  const LockScreenPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const model = LockWidgetModel(
      headline: 'LH 401 · B27',
      subline: 'BOARDING · 0:18',
      tickerDigit: '0:18',
    );

    return PageScaffold(
      title: 'Lock screen',
      subtitle: 'Widgets · Always-On',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: const [
          _Eyebrow('STENCIL · BELOW THE TIME'),
          SizedBox(height: Os2.space3),
          Center(
            child: LockScreenStencil(
              slot: LockSlot.belowTime,
              widget: LockWidgetPreview(
                model: model,
                form: LockWidgetForm.accessoryRectangular,
              ),
            ),
          ),
          SizedBox(height: Os2.space5),
          _Eyebrow('STENCIL · ALWAYS-ON'),
          SizedBox(height: Os2.space3),
          Center(
            child: LockScreenStencil(
              dim: true,
              slot: LockSlot.belowTime,
              widget: LockWidgetPreview(
                model: model,
                form: LockWidgetForm.alwaysOnDim,
              ),
            ),
          ),
          SizedBox(height: Os2.space6),
          _Eyebrow('FAMILIES'),
          SizedBox(height: Os2.space3),
          _FormTile(
            handle: 'CIRCULAR · 38pt',
            description:
                'Round badge above the time. Foil-gold pill with the countdown digit.',
            preview: LockWidgetPreview(
              model: model,
              form: LockWidgetForm.accessoryCircular,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'RECTANGULAR · 158x66',
            description:
                'Standard accessory rectangle: flight + gate row, countdown row, GLOBE·ID watermark.',
            preview: LockWidgetPreview(
              model: model,
              form: LockWidgetForm.accessoryRectangular,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'INLINE',
            description:
                'Single-line accessory above the time. Glyph + flight · gate · countdown.',
            preview: LockWidgetPreview(
              model: model,
              form: LockWidgetForm.accessoryInline,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'ALWAYS-ON · DIM',
            description:
                'Same rectangle, desaturated for the Always-On / low-power vocabulary. Hairline softens, ink mutes by ~30%.',
            preview: LockWidgetPreview(
              model: model,
              form: LockWidgetForm.alwaysOnDim,
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
                'WIDGETKIT',
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
            'iOS — WidgetKit accessory families (`accessoryCircular`, `accessoryRectangular`, `accessoryInline`). Always-On is the same rectangular family rendered with `vibrantRendering(false)` and a dim tint. Android — system AOD complications via `Slice` API.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
