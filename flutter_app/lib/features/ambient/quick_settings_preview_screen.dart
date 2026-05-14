import 'package:flutter/material.dart';

import '../../cinematic/ambient/quick_settings_preview.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// `/ambient/quick-settings` — preview for the GlobeID one-tap
/// shortcut tiles on iOS Control Center and Android Quick Settings.
class QuickSettingsPreviewScreen extends StatelessWidget {
  const QuickSettingsPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Quick tiles',
      subtitle: 'iOS Control Center · Android Quick Settings',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _Eyebrow('iOS · CONTROL CENTER'),
          const SizedBox(height: Os2.space3),
          IosControlCenterPanel(
            tiles: [
              for (final spec in QuickTileSpec.all)
                QuickSettingsTilePreview(
                  spec: spec,
                  form: QuickTileForm.iosCompact,
                ),
            ],
          ),
          const SizedBox(height: Os2.space4),
          const _Eyebrow('iOS · EXPANDED MODULE'),
          const SizedBox(height: Os2.space3),
          Center(
            child: QuickSettingsTilePreview(
              spec: QuickTileSpec.scan,
              form: QuickTileForm.iosExpanded,
            ),
          ),
          const SizedBox(height: Os2.space6),
          const _Eyebrow('ANDROID · QUICK SETTINGS'),
          const SizedBox(height: Os2.space3),
          AndroidQuickSettingsPanel(
            tiles: [
              for (final spec in QuickTileSpec.all)
                QuickSettingsTilePreview(
                  spec: spec,
                  form: QuickTileForm.androidTile,
                ),
            ],
          ),
          const SizedBox(height: Os2.space6),
          const _IntegrationCard(),
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
            'iOS — Control Center module via the `ControlWidget` API (iOS 18+). Each tile maps to a deep-link intent. Android — `TileService` registered in the manifest with `android.service.quicksettings.action.QS_TILE`, returning the same intents.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          for (final spec in QuickTileSpec.all)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(spec.icon, color: Os2.goldDeep, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Os2Text.monoCap(
                      spec.handle,
                      color: Os2.inkBright,
                      size: Os2.textTiny,
                    ),
                  ),
                  Os2Text.monoCap(
                    _intentFor(spec.action),
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _intentFor(QuickTileAction a) {
    switch (a) {
      case QuickTileAction.scan:
        return 'GLOBEID://SCAN';
      case QuickTileAction.vault:
        return 'GLOBEID://VAULT';
      case QuickTileAction.copilot:
        return 'GLOBEID://COPILOT';
    }
  }
}
