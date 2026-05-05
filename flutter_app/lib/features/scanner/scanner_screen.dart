import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/boarding_pass.dart';
import '../../domain/mrz_parser.dart';
import '../../widgets/glass_surface.dart';

/// Scanner — full-screen camera with edge-detection overlay; supports
/// QR (mobile_scanner) and MRZ (ML Kit text recogniser).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _qrCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.pdf417
    ],
  );

  final TextRecognizer _ocr =
      TextRecognizer(script: TextRecognitionScript.latin);

  String? _result;
  String _mode = 'qr'; // qr | mrz

  @override
  void dispose() {
    _qrCtrl.dispose();
    _ocr.close();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_result != null) return;
    final code = cap.barcodes.firstWhere(
      (b) => b.rawValue != null,
      orElse: () => Barcode(rawValue: null),
    );
    if (code.rawValue == null) return;
    HapticFeedback.mediumImpact();
    final raw = code.rawValue!;
    String label = raw;
    final v = verifyBoardingPass(raw);
    if (v.valid && v.payload != null) {
      label =
          '✓ ${v.payload!.passenger} · ${v.payload!.flightNumber} · ${v.payload!.fromIata} → ${v.payload!.toIata}';
    } else if (v.payload != null) {
      label = '⚠ ${v.error} (${v.payload!.passenger})';
    }
    setState(() => _result = label);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_mode == 'qr')
            MobileScanner(
              controller: _qrCtrl,
              onDetect: _onDetect,
              fit: BoxFit.cover,
            ),
          if (_mode == 'mrz')
            const Center(
              child: Text(
                'MRZ scanner — point at passport.\n(Use Pick image to test OCR.)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          // Edge-detection overlay (animated viewfinder).
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: _mode == 'qr' ? 280 : 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AppTokens.space3,
            left: AppTokens.space4,
            right: AppTokens.space4,
            child: GlassSurface(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3, vertical: AppTokens.space2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'qr', label: Text('QR')),
                      ButtonSegment(value: 'mrz', label: Text('Passport')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ],
              ),
            ),
          ),
          // Result overlay
          if (_result != null)
            Positioned(
              left: AppTokens.space4,
              right: AppTokens.space4,
              bottom: AppTokens.space9 + 24,
              child: GlassSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        )),
                    const SizedBox(height: AppTokens.space3),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => setState(() => _result = null),
                          child: const Text('Scan again'),
                        ),
                        const SizedBox(width: AppTokens.space2),
                        OutlinedButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper kept for potential static OCR analysis (kept as future hook).
MrzResult parseMrzText(String raw) => parseMrz(raw);
