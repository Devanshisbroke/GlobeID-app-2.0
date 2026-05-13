import 'package:flutter/material.dart';

import '../../cinematic/ambient/live_activity_preview.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// `/ambient/live-activity` — design preview for the GlobeID iOS
/// Live Activity surface (Dynamic Island).
///
/// Shows all three forms of the Live Activity composed with sample
/// boarding-pass state, plus a labelled hero render inside a
/// `DeviceFrame` so the compact form reads as a real ambient
/// surface, not a stray pill.
class LiveActivityPreviewScreen extends StatelessWidget {
  const LiveActivityPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const model = LiveActivityModel(
      flightCode: 'LH 401',
      gate: 'B27',
      boardingIn: Duration(minutes: 18),
      origin: 'FRA',
      destination: 'OSL',
      seat: '12A',
    );

    return PageScaffold(
      title: 'Live Activity',
      subtitle: 'Dynamic Island · boarding countdown',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: const [
          _SectionHeader(label: 'AMBIENT · DEVICE FRAME'),
          SizedBox(height: Os2.space3),
          DeviceFrame(
            child: LiveActivityPreview(
              model: model,
              form: LiveActivityForm.compact,
            ),
          ),
          SizedBox(height: Os2.space6),
          _SectionHeader(label: 'FORMS · COMPACT'),
          SizedBox(height: Os2.space3),
          _FormTile(
            handle: 'COMPACT',
            description:
                'Dynamic Island width, leading dot, monocap countdown.',
            preview: LiveActivityPreview(
              model: model,
              form: LiveActivityForm.compact,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'MINIMAL',
            description:
                'Gold pill with the GlobeID flight glyph, sized to the trailing affordance.',
            preview: LiveActivityPreview(
              model: model,
              form: LiveActivityForm.minimal,
            ),
          ),
          SizedBox(height: Os2.space4),
          _FormTile(
            handle: 'EXPANDED',
            description:
                'Mini boarding pass. Origin / destination credential type-scale, gate badge in gold, flight & seat handle, tap-to-open hint.',
            preview: LiveActivityPreview(
              model: model,
              form: LiveActivityForm.expanded,
            ),
          ),
          SizedBox(height: Os2.space6),
          _SpecCard(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
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
              Os2Text.monoCap('iOS', color: Os2.inkLow, size: Os2.textTiny),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Center(child: preview),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            description,
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard();
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
            'Implemented on iOS via ActivityKit. The state model below maps 1:1 to the LiveActivityAttributes contract.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          const _SpecRow(name: 'flightCode', type: 'String', sample: 'LH 401'),
          _SpecRow(name: 'gate', type: 'String', sample: 'B27'),
          _SpecRow(
            name: 'boardingIn',
            type: 'Duration',
            sample: '0:18',
          ),
          _SpecRow(name: 'origin', type: 'String (IATA)', sample: 'FRA'),
          _SpecRow(
            name: 'destination',
            type: 'String (IATA)',
            sample: 'OSL',
          ),
          _SpecRow(name: 'seat', type: 'String', sample: '12A'),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.name,
    required this.type,
    required this.sample,
  });
  final String name;
  final String type;
  final String sample;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Os2Text.monoCap(
              name.toUpperCase(),
              color: Os2.inkBright,
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            flex: 2,
            child: Os2Text.caption(type, color: Os2.inkLow, size: Os2.textTiny),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Os2Text.monoCap(
                sample.toUpperCase(),
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
