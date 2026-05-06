import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/boarding_pass.dart';
import '../../domain/mrz_parser.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/scan_overlay.dart';
import '../../widgets/toast.dart';

/// Premium scanner — Google-Lens / Adobe-Scan inspired.
/// Animated viewfinder, mode pill (QR ↔ Passport), result card with
/// classifier-aware actions, torch toggle, camera-flip.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScanMode { qr, mrz }

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _qrCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.pdf417,
    ],
  );

  final TextRecognizer _ocr = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  _ScanResult? _result;
  _ScanMode _mode = _ScanMode.qr;
  bool _torch = false;
  bool _ocrBusy = false;
  final ImagePicker _picker = ImagePicker();

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
    setState(() => _result = _classify(raw));
  }

  Future<void> _captureAndOcr(ImageSource source) async {
    setState(() => _ocrBusy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) {
        if (mounted) setState(() => _ocrBusy = false);
        return;
      }
      final input = InputImage.fromFilePath(picked.path);
      final recognized = await _ocr.processImage(input);
      final raw = recognized.text;
      final mrz = parseMrz(raw);
      if (!mounted) return;
      final fields = mrz.fields;
      final isPassport = mrz.ok && fields != null;
      setState(() {
        _ocrBusy = false;
        _result = _ScanResult(
          kind: _ScanKind.passport,
          title: isPassport ? 'Passport recognised' : 'Text recognised',
          body: isPassport
              ? '${fields.givenNames} ${fields.surname}'.trim()
              : (raw.isEmpty ? 'No text detected' : raw),
          meta: isPassport
              ? '${fields.documentNumber} · ${fields.nationality}'
              : 'Plain OCR',
          ok: isPassport,
          raw: raw,
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() => _ocrBusy = false);
        AppToast.show(
          context,
          title: 'OCR failed',
          message: e.toString(),
          tone: AppToastTone.danger,
        );
      }
    }
  }

  _ScanResult _classify(String raw) {
    final v = verifyBoardingPass(raw);
    if (v.valid && v.payload != null) {
      final p = v.payload!;
      return _ScanResult(
        kind: _ScanKind.boardingPass,
        title: 'Boarding pass verified',
        body: '${p.passenger} · ${p.flightNumber}',
        meta: '${p.fromIata} → ${p.toIata}',
        ok: true,
        raw: raw,
      );
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _ScanResult(
        kind: _ScanKind.url,
        title: 'Link',
        body: raw,
        meta: 'Web URL',
        ok: true,
        raw: raw,
      );
    }
    if (raw.startsWith('WIFI:')) {
      return _ScanResult(
        kind: _ScanKind.wifi,
        title: 'Wi-Fi network',
        body: raw,
        meta: 'Connect',
        ok: true,
        raw: raw,
      );
    }
    if (raw.startsWith('BEGIN:VCARD')) {
      return _ScanResult(
        kind: _ScanKind.contact,
        title: 'Contact card',
        body: raw,
        meta: 'Save to contacts',
        ok: true,
        raw: raw,
      );
    }
    return _ScanResult(
      kind: _ScanKind.text,
      title: 'Scanned',
      body: raw,
      meta: 'Plain text',
      ok: true,
      raw: raw,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_mode == _ScanMode.qr)
              MobileScanner(
                controller: _qrCtrl,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              )
            else
              const _ScannerBackdrop(),
            if (_mode == _ScanMode.mrz)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Point at the passport's bottom MRZ band",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        'Capture a passport photo and OCR will extract the MRZ.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: _ocrBusy
                                ? null
                                : () => _captureAndOcr(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Capture'),
                          ),
                          const SizedBox(width: AppTokens.space2),
                          OutlinedButton.icon(
                            onPressed: _ocrBusy
                                ? null
                                : () => _captureAndOcr(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('From library'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_ocrBusy) ...[
                        const SizedBox(height: AppTokens.space5),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          'Recognising text…',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const _LensDimmer(),
            Positioned.fill(
              child: ScanOverlay(
                aspectRatio: _mode == _ScanMode.qr ? 1.0 : 1.5,
                tone: accent,
                label: _mode == _ScanMode.qr ? 'Scan QR or barcode' : 'MRZ',
              ),
            ),
            Positioned(
              left: AppTokens.space4,
              right: AppTokens.space4,
              bottom: _result == null
                  ? AppTokens.space7
                  : AppTokens.space10 + 138,
              child: _ScanConfidenceRail(
                mode: _mode,
                hasResult: _result != null,
                busy: _ocrBusy,
              ),
            ),
            // Top bar.
            Positioned(
              top: MediaQuery.of(context).padding.top + AppTokens.space3,
              left: AppTokens.space4,
              right: AppTokens.space4,
              child: AnimatedAppearance(
                duration: AppTokens.durationLg,
                offset: -16,
                child: _TopBar(
                  mode: _mode,
                  torch: _torch,
                  onClose: () => Navigator.maybePop(context),
                  onModeChange: (m) {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = m);
                  },
                  onTorch: () async {
                    await _qrCtrl.toggleTorch();
                    setState(() => _torch = !_torch);
                  },
                ),
              ),
            ),
            Positioned(
              left: AppTokens.space4,
              right: AppTokens.space4,
              top: MediaQuery.of(context).padding.top + 86,
              child: _ScannerHint(mode: _mode),
            ),
            // Result card.
            if (_result != null)
              Positioned(
                left: AppTokens.space4,
                right: AppTokens.space4,
                bottom: AppTokens.space9 + 24,
                child: AnimatedAppearance(
                  offset: 24,
                  duration: AppTokens.durationLg,
                  child: _ResultCard(
                    result: _result!,
                    onClear: () => setState(() => _result = null),
                    onDone: () => Navigator.maybePop(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerBackdrop extends StatelessWidget {
  const _ScannerBackdrop();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.22),
          radius: 1.1,
          colors: [
            accent.withValues(alpha: 0.24),
            const Color(0xFF07101E),
            Colors.black,
          ],
        ),
      ),
    );
  }
}

class _LensDimmer extends StatelessWidget {
  const _LensDimmer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.52),
              Colors.black.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.64),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerHint extends StatelessWidget {
  const _ScannerHint({required this.mode});

  final _ScanMode mode;

  @override
  Widget build(BuildContext context) {
    final text = mode == _ScanMode.qr
        ? 'Live classifier: QR · PDF417 · boarding pass · URL · vCard'
        : 'Passport OCR: frame the MRZ band, then capture or import';
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: AppTokens.durationMd,
        child: Text(
          text,
          key: ValueKey(mode),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ScanConfidenceRail extends StatelessWidget {
  const _ScanConfidenceRail({
    required this.mode,
    required this.hasResult,
    required this.busy,
  });

  final _ScanMode mode;
  final bool hasResult;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final chips = mode == _ScanMode.qr
        ? const ['QR', 'Boarding', 'Wallet', 'Identity']
        : const ['MRZ', 'Passport', 'OCR', 'Vault'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space3,
            vertical: AppTokens.space2,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(
                hasResult
                    ? Icons.verified_rounded
                    : busy
                    ? Icons.auto_awesome_rounded
                    : Icons.center_focus_strong_rounded,
                color: hasResult ? Colors.greenAccent : accent,
                size: 18,
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final chip in chips) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusFull,
                            ),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.torch,
    required this.onClose,
    required this.onModeChange,
    required this.onTorch,
  });

  final _ScanMode mode;
  final bool torch;
  final VoidCallback onClose;
  final ValueChanged<_ScanMode> onModeChange;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space3,
            vertical: AppTokens.space2,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Pressable(
                onTap: onClose,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ModePill(value: mode, onChange: onModeChange),
                ),
              ),
              Pressable(
                onTap: onTorch,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    torch
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    color: torch ? Colors.amberAccent : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.value, required this.onChange});
  final _ScanMode value;
  final ValueChanged<_ScanMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in _ScanMode.values)
            _PillSegment(
              label: m == _ScanMode.qr ? 'QR' : 'Passport',
              selected: value == m,
              onTap: () => onChange(m),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.onClear,
    required this.onDone,
  });

  final _ScanResult result;
  final VoidCallback onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      tint: Colors.black,
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: Icon(
                  _iconFor(result.kind),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      result.meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            result.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Scan again'),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              IconButton(
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.raw));
                  HapticFeedback.lightImpact();
                  AppToast.show(
                    context,
                    title: 'Copied',
                    message: 'Scanned payload on clipboard',
                    tone: AppToastTone.success,
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(_ScanKind k) {
    switch (k) {
      case _ScanKind.boardingPass:
        return Icons.flight_takeoff_rounded;
      case _ScanKind.url:
        return Icons.public_rounded;
      case _ScanKind.wifi:
        return Icons.wifi_rounded;
      case _ScanKind.contact:
        return Icons.person_rounded;
      case _ScanKind.text:
        return Icons.text_snippet_rounded;
      case _ScanKind.passport:
        return Icons.badge_outlined;
    }
  }
}

enum _ScanKind { boardingPass, url, wifi, contact, text, passport }

class _ScanResult {
  _ScanResult({
    required this.kind,
    required this.title,
    required this.body,
    required this.meta,
    required this.ok,
    required this.raw,
  });

  final _ScanKind kind;
  final String title;
  final String body;
  final String meta;
  final bool ok;
  final String raw;
}

// Helper kept for potential static OCR analysis.
MrzResult parseMrzText(String raw) => parseMrz(raw);
