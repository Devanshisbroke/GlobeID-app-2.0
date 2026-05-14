import 'package:flutter/material.dart';

import '../../cinematic/branding/identity_signet.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Lab gallery showcasing the three GlobeID identity-signet
/// variants — STANDARD · FOIL, ATELIER · STEALTH, PILOT · NAVY.
///
/// Renders each variant at four canonical sizes (iOS app-icon
/// ladder — 29 pt, 60 pt, 87 pt, 120 pt) so the user can compare
/// how each variant reads from a settings cell up to a home-screen
/// tile. Companion to the cold-mount seal (12b); together they form
/// the manufactured-credential brand chrome.
class IdentitySignetScreen extends StatefulWidget {
  const IdentitySignetScreen({super.key});

  @override
  State<IdentitySignetScreen> createState() => _IdentitySignetScreenState();
}

class _IdentitySignetScreenState extends State<IdentitySignetScreen> {
  SignetVariant _active = SignetVariant.standard;

  static const _sizes = <(String, double)>[
    ('29 pt · SETTINGS', 29),
    ('60 pt · INBOX', 60),
    ('87 pt · WALLET', 87),
    ('120 pt · HOMESCREEN', 120),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = SignetPalette.of(_active);
    return PageScaffold(
      title: 'Identity signet',
      subtitle: 'Phase 12c · ATELIER variant + three-tier signet ladder',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _Hero(variant: _active, palette: palette),
          const SizedBox(height: Os2.space5),
          // Variant picker.
          Os2Text.monoCap(
            'VARIANT · PICKER',
            color: palette.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              for (final variant in SignetVariant.values) ...[
                Expanded(
                  child: _VariantTile(
                    variant: variant,
                    selected: _active == variant,
                    onTap: () => setState(() => _active = variant),
                  ),
                ),
                if (variant != SignetVariant.values.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: Os2.space5),
          // Size ladder.
          Os2Text.monoCap(
            'SIZE · LADDER',
            color: palette.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Container(
            padding: const EdgeInsets.all(Os2.space4),
            decoration: BoxDecoration(
              color: Os2.floor1,
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 28,
              runSpacing: 18,
              children: [
                for (final size in _sizes)
                  Column(
                    children: [
                      IdentitySignet(variant: _active, size: size.$2),
                      const SizedBox(height: 6),
                      Os2Text.monoCap(
                        size.$1,
                        color: Os2.inkMid,
                        size: Os2.textTiny,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: Os2.space5),
          // Palette card.
          _PaletteCard(palette: palette),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.variant, required this.palette});
  final SignetVariant variant;
  final SignetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        gradient: variant == SignetVariant.pilot
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1B33), Color(0xFF050912)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
              ),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: palette.tone.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: palette.tone.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Os2Text.monoCap(
            'SIGNET · ${variant.name.toUpperCase()}',
            color: palette.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: 12),
          IdentitySignet(variant: variant, size: 152),
          const SizedBox(height: 14),
          Os2Text.monoCap(
            palette.name,
            color: Os2.inkBright,
            size: Os2.textXs,
          ),
          const SizedBox(height: 6),
          Os2Text.monoCap(
            _description(variant),
            color: Os2.inkMid,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }

  String _description(SignetVariant variant) {
    switch (variant) {
      case SignetVariant.standard:
        return 'FOIL · GOLD · SEAL · ON · OLED · BLACK';
      case SignetVariant.atelier:
        return 'STEALTH · HAIRLINE · NO · FILL · MAX · DISCRETION';
      case SignetVariant.pilot:
        return 'PILOT · NAVY · SUBSTRATE · CHAMPAGNE · MONOGRAM';
    }
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.variant,
    required this.selected,
    required this.onTap,
  });
  final SignetVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SignetPalette.of(variant);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Pick ${palette.name} signet',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Os2.space3),
        decoration: BoxDecoration(
          color: selected
              ? palette.tone.withValues(alpha: 0.16)
              : const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(Os2.rTile),
          border: Border.all(
            color: selected ? palette.tone : palette.tone.withValues(alpha: 0.3),
            width: selected ? 1.2 : 0.6,
          ),
        ),
        child: Column(
          children: [
            IdentitySignet(variant: variant, size: 48),
            const SizedBox(height: 8),
            Os2Text.monoCap(
              palette.name,
              color: selected ? palette.tone : Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.palette});
  final SignetPalette palette;

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
            'PALETTE · ${palette.name}',
            color: palette.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _ColorRow(label: 'TONE · ACCENT', color: palette.tone),
          const SizedBox(height: 8),
          _ColorRow(label: 'INK · MONOGRAM', color: palette.ink),
          const SizedBox(height: 8),
          _ColorRow(label: 'SUBSTRATE · FILL', color: palette.substrate),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Os2.hairline),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Os2Text.monoCap(
            label,
            color: Os2.inkBright,
            size: Os2.textTiny,
          ),
        ),
        Os2Text.monoCap(
          hex,
          color: Os2.inkMid,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}
