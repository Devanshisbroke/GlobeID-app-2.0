import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// `QuickSettingsTilePreview` — design previews for GlobeID one-tap
/// tile surfaces on iOS Control Center and Android Quick Settings.
///
/// Three tile actions ship in the first wave of the Atelier — each
/// is a single-tap shortcut into a high-frequency GlobeID flow:
///   • SCAN        — open the credential scanner viewfinder
///   • VAULT       — open the Identity Vault dashboard
///   • COPILOT     — open the Copilot conversation
///
/// Three tile forms cover both platforms:
///   • iosCompact   — 64pt iOS Control Center mini-tile
///   • iosExpanded  — full Control Center module (302×148)
///   • androidTile  — Android Quick Settings square (88×88) with
///                    primary + secondary label

enum QuickTileAction { scan, vault, copilot }

enum QuickTileForm { iosCompact, iosExpanded, androidTile }

class QuickTileSpec {
  const QuickTileSpec({
    required this.action,
    required this.handle,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final QuickTileAction action;

  /// `SCAN · GLOBE·ID` — primary mono-cap label.
  final String handle;

  /// `Scanner` — short title for the iOS module + Android tile.
  final String label;

  /// `Tap to read any credential` — secondary description used in
  /// the expanded forms.
  final String subtitle;

  final IconData icon;

  static const scan = QuickTileSpec(
    action: QuickTileAction.scan,
    handle: 'SCAN · GLOBE·ID',
    label: 'Scanner',
    subtitle: 'Read any credential',
    icon: Icons.center_focus_strong_rounded,
  );

  static const vault = QuickTileSpec(
    action: QuickTileAction.vault,
    handle: 'VAULT · OPEN',
    label: 'Vault',
    subtitle: 'Identity dashboard',
    icon: Icons.lock_rounded,
  );

  static const copilot = QuickTileSpec(
    action: QuickTileAction.copilot,
    handle: 'COPILOT · ASK',
    label: 'Copilot',
    subtitle: 'Travel intelligence',
    icon: Icons.bolt_rounded,
  );

  static const all = <QuickTileSpec>[scan, vault, copilot];
}

class QuickSettingsTilePreview extends StatelessWidget {
  const QuickSettingsTilePreview({
    super.key,
    required this.spec,
    required this.form,
  });
  final QuickTileSpec spec;
  final QuickTileForm form;

  @override
  Widget build(BuildContext context) {
    switch (form) {
      case QuickTileForm.iosCompact:
        return _IosCompactTile(spec: spec);
      case QuickTileForm.iosExpanded:
        return _IosExpandedTile(spec: spec);
      case QuickTileForm.androidTile:
        return _AndroidTile(spec: spec);
    }
  }
}

class _IosCompactTile extends StatelessWidget {
  const _IosCompactTile({required this.spec});
  final QuickTileSpec spec;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(spec.icon, color: Os2.canvas, size: 30),
      ),
    );
  }
}

class _IosExpandedTile extends StatelessWidget {
  const _IosExpandedTile({required this.spec});
  final QuickTileSpec spec;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 302,
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, color: Os2.canvas, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Os2Text.monoCap(
                  spec.handle,
                  color: Os2.canvas,
                  size: Os2.textTiny,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Os2Text.title(
            spec.label,
            color: Os2.canvas,
            size: Os2.textLg,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Os2Text.monoCap(
            spec.subtitle.toUpperCase(),
            color: Os2.canvas,
            size: Os2.textTiny,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _AndroidTile extends StatelessWidget {
  const _AndroidTile({required this.spec});
  final QuickTileSpec spec;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(spec.icon, color: Os2.goldDeep, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Os2Text.title(
                spec.label,
                color: Os2.inkBright,
                size: Os2.textSm,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Os2Text.monoCap(
                spec.subtitle.toUpperCase(),
                color: Os2.inkLow,
                size: Os2.textTiny,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `IosControlCenterPanel` — wraps a row of compact iOS Control
/// Center tiles in a dark-blur panel + drag handle, so the
/// preview reads as a real Control Center module strip.
class IosControlCenterPanel extends StatelessWidget {
  const IosControlCenterPanel({super.key, required this.tiles});
  final List<Widget> tiles;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Os2.canvas.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Os2.hairlineSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Os2.hairlineSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

/// `AndroidQuickSettingsPanel` — wraps a row of Android Quick
/// Settings tiles in a dark scrim with the system clock + WiFi/
/// cellular eyebrow so the preview reads as a real notification
/// shade.
class AndroidQuickSettingsPanel extends StatelessWidget {
  const AndroidQuickSettingsPanel({super.key, required this.tiles});
  final List<Widget> tiles;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Os2.canvas.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Os2.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                '09:24 · TUE',
                color: Os2.inkBright,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'WIFI · 5G · 92%',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiles,
          ),
        ],
      ),
    );
  }
}
