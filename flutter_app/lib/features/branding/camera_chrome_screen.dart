import 'package:flutter/material.dart';

import '../../cinematic/branding/camera_chrome.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Lab gallery for the [CameraChrome] primitive.
///
/// Renders a stand-in viewfinder (gradient + lab-grid) inside the
/// chrome and lets the operator cycle through the five canonical
/// scan modes — PASSPORT / FACE / QR / NFC / DOCUMENT — so the
/// chrome's tone, aim shape, chip copy and scan-line cadence are
/// all visible side-by-side.
class CameraChromeScreen extends StatefulWidget {
  const CameraChromeScreen({super.key});

  @override
  State<CameraChromeScreen> createState() => _CameraChromeScreenState();
}

class _CameraChromeScreenState extends State<CameraChromeScreen> {
  ScanMode _mode = ScanMode.passport;

  static const _labels = <(ScanMode, String, IconData)>[
    (ScanMode.passport, 'PASSPORT', Icons.menu_book_rounded),
    (ScanMode.face, 'FACE', Icons.face_retouching_natural_outlined),
    (ScanMode.qr, 'QR', Icons.qr_code_2_rounded),
    (ScanMode.nfc, 'NFC', Icons.nfc_rounded),
    (ScanMode.document, 'DOCUMENT', Icons.description_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final spec = ScanModeSpec.of(_mode);
    return PageScaffold(
      title: 'Camera chrome',
      subtitle: 'Phase 12d · GlobeID-engineered viewfinder · 5 scan modes',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          // Viewport.
          Container(
            height: 460,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: spec.tone.withValues(alpha: 0.42)),
            ),
            clipBehavior: Clip.antiAlias,
            child: CameraChrome(
              mode: _mode,
              caseNumber: 'N° SCAN-${_mode.name.toUpperCase()}',
              child: const _LabViewfinder(),
            ),
          ),
          const SizedBox(height: Os2.space5),
          // Mode picker — segmented row.
          Os2Text.monoCap(
            'MODE · PICKER',
            color: spec.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              for (final entry in _labels) ...[
                Expanded(
                  child: _ModePickerTile(
                    mode: entry.$1,
                    label: entry.$2,
                    icon: entry.$3,
                    selected: _mode == entry.$1,
                    onTap: () => setState(() => _mode = entry.$1),
                  ),
                ),
                if (entry.$1 != _labels.last.$1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: Os2.space5),
          // Spec card.
          _SpecCard(spec: spec),
        ],
      ),
    );
  }
}

class _LabViewfinder extends StatelessWidget {
  const _LabViewfinder();

  @override
  Widget build(BuildContext context) {
    // Stand-in for a live camera preview — moody gradient with a
    // faint grid so the chrome reads against texture rather than a
    // flat plane.
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F26), Color(0xFF050912)],
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter()),
        // Stand-in subject "card" in the center to suggest the
        // document the chrome would frame.
        Center(
          child: Container(
            width: 220,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2734).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _ModePickerTile extends StatelessWidget {
  const _ModePickerTile({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final ScanMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = ScanModeSpec.of(mode);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Switch to $label scan mode',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? spec.tone.withValues(alpha: 0.16)
              : const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(Os2.rTile),
          border: Border.all(
            color: selected ? spec.tone : spec.tone.withValues(alpha: 0.28),
            width: selected ? 1.2 : 0.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? spec.tone : Os2.inkMid,
            ),
            const SizedBox(height: 6),
            Os2Text.monoCap(
              label,
              color: selected ? spec.tone : Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.spec});
  final ScanModeSpec spec;

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
            'SPEC · ${spec.label}',
            color: spec.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _Row(label: 'AIM · ASPECT', value: spec.aim.aspect.toStringAsFixed(2)),
          const SizedBox(height: 6),
          _Row(label: 'AIM · WIDTH', value: '${(spec.aim.widthFraction * 100).toStringAsFixed(0)} %'),
          const SizedBox(height: 6),
          _Row(label: 'AIM · SHAPE', value: spec.aim.oval ? 'OVAL · RIM' : 'CORNER · BRACKETS'),
          const SizedBox(height: 6),
          _Row(label: 'SCAN · CADENCE', value: '${spec.scanCadence.inMilliseconds} ms'),
          const SizedBox(height: 6),
          _Row(
            label: 'TONE',
            value: '#${(spec.tone.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Os2Text.monoCap(label, color: Os2.inkMid, size: Os2.textTiny),
        ),
        Os2Text.monoCap(value, color: Os2.inkBright, size: Os2.textTiny),
      ],
    );
  }
}
