import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';

/// Mask helper — replaces every non-whitespace character with a
/// mid-dot, preserving spaces / separators so the masked silhouette
/// still has the right shape.
String maskValue(String value, {String fallback = '— — — —'}) {
  if (value.trim().isEmpty) return fallback;
  final buf = StringBuffer();
  for (final ch in value.split('')) {
    if (ch == ' ' || ch == '·' || ch == '-' || ch == '/') {
      buf.write(ch);
    } else {
      buf.write('·');
    }
  }
  return buf.toString();
}

/// Authenticator surface used by [BiometricRevealGate]. The default
/// uses `local_auth` on the host platform; tests can inject a
/// stubbed authenticator to exercise UI states without hitting the
/// platform channel.
abstract class BiometricAuthenticator {
  Future<bool> authenticate({required String reason});
}

class LocalAuthAuthenticator implements BiometricAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

/// `BiometricRevealGate` — wraps a sensitive value (passport
/// number, DOB, address) in a tap-to-reveal surface.
///
/// Default state shows a masked silhouette + mono-cap
/// `TAP TO REVEAL · BIOMETRIC GATED` hint. On tap the gate prompts
/// the host platform for biometrics (Face ID / Touch ID / passcode).
/// On success the blur lifts over 320 ms and the value is revealed
/// for [autoLockAfter] before re-hiding itself.
///
/// Visually consistent with every other GlobeID surface — gold
/// hairline frame, OLED tile, mono-cap chrome. No new visual
/// language is introduced.
class BiometricRevealGate extends StatefulWidget {
  const BiometricRevealGate({
    super.key,
    required this.label,
    required this.value,
    this.authenticator,
    this.reason = 'Reveal sensitive credential field',
    this.autoLockAfter = const Duration(seconds: 30),
    this.dense = false,
  });

  /// Field label, e.g. `Passport number`.
  final String label;

  /// The raw value to reveal once authenticated.
  final String value;

  /// Authenticator override (tests inject a stub here). Defaults
  /// to a `LocalAuthAuthenticator` built lazily on first tap.
  final BiometricAuthenticator? authenticator;

  /// Prompt copy shown by the host biometric UI.
  final String reason;

  /// How long the revealed value stays visible before re-hiding.
  /// Set to `Duration.zero` to never auto-lock (not recommended).
  final Duration autoLockAfter;

  /// When true, the surface uses a denser padding ladder. Used
  /// inside grouped detail rows.
  final bool dense;

  @override
  State<BiometricRevealGate> createState() => _BiometricRevealGateState();
}

class _BiometricRevealGateState extends State<BiometricRevealGate> {
  bool _revealed = false;
  bool _busy = false;
  Timer? _lockTimer;
  late final BiometricAuthenticator _auth =
      widget.authenticator ?? LocalAuthAuthenticator();

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    if (_revealed) {
      // Tapping a revealed value re-locks it immediately.
      HapticFeedback.selectionClick();
      setState(() => _revealed = false);
      _lockTimer?.cancel();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    final ok = await _auth.authenticate(reason: widget.reason);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _revealed = ok;
    });
    if (ok) {
      Haptics.signature();
      if (widget.autoLockAfter > Duration.zero) {
        _lockTimer?.cancel();
        _lockTimer = Timer(widget.autoLockAfter, () {
          if (mounted) setState(() => _revealed = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = maskValue(widget.value);
    final padV = widget.dense ? Os2.space2 : Os2.space3;
    return Pressable(
      scale: 0.99,
      semanticLabel:
          _revealed ? 'Lock ${widget.label}' : 'Reveal ${widget.label}',
      semanticHint: _revealed
          ? 'tap to re-hide the value'
          : 'requires biometric authentication',
      onTap: _onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: padV,
        ),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: _revealed
                ? Os2.goldDeep.withValues(alpha: 0.46)
                : Os2.hairline,
          ),
        ),
        child: Row(
          children: [
            _GateGlyph(revealed: _revealed, busy: _busy),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.monoCap(
                    widget.label.toUpperCase(),
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(height: 4),
                  _RevealText(
                    masked: masked,
                    revealed: widget.value,
                    isOpen: _revealed,
                  ),
                  const SizedBox(height: 4),
                  Os2Text.monoCap(
                    _revealed
                        ? 'REVEALED · TAP TO LOCK'
                        : 'TAP TO REVEAL · BIOMETRIC GATED',
                    color: _revealed
                        ? Os2.goldDeep
                        : Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateGlyph extends StatelessWidget {
  const _GateGlyph({required this.revealed, required this.busy});
  final bool revealed;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final tone = revealed ? Os2.goldDeep : Os2.inkMid;
    final icon = busy
        ? Icons.lock_clock_rounded
        : revealed
            ? Icons.lock_open_rounded
            : Icons.fingerprint_rounded;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.14),
        border: Border.all(color: tone.withValues(alpha: 0.42)),
      ),
      child: Icon(icon, size: 16, color: tone),
    );
  }
}

class _RevealText extends StatelessWidget {
  const _RevealText({
    required this.masked,
    required this.revealed,
    required this.isOpen,
  });
  final String masked;
  final String revealed;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isOpen ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        final blur = (1.0 - t) * 6.0;
        final showRevealed = t > 0.5;
        final text = showRevealed ? revealed : masked;
        return ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Os2Text.credential(
              text,
              color: isOpen ? Os2.inkBright : Os2.inkMid,
              size: Os2.textLg,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }
}
