import 'package:flutter/foundation.dart';

/// Lightweight audio cue system for micro-interactions.
///
/// Provides named cues: scan_start, scan_success, verify_success,
/// payment_received, tier_upgrade, gate_change, etc.
/// All sounds at -36dB, optional, and respect silent mode.
///
/// This is a stub that logs cue names in debug mode.
/// Full implementation would use audioplayers or just_audio.
class AmbientSound {
  AmbientSound._();
  static final _instance = AmbientSound._();
  static AmbientSound get instance => _instance;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// Enable/disable sound system.
  void setEnabled(bool value) => _enabled = value;

  /// Play a named sound cue.
  void play(SoundCue cue) {
    if (!_enabled) return;
    if (kDebugMode) debugPrint('[AmbientSound] 🔊 ${cue.name}');
    // Full impl: audioPlayer.play(AssetSource('sounds/${cue.name}.wav'));
  }

  /// Play the brand chord on app open.
  void playBrandChord() => play(SoundCue.brandChord);

  /// Play mode switch chord.
  void playModeSwitch(String mode) {
    if (kDebugMode) debugPrint('[AmbientSound] mode → $mode');
    play(SoundCue.modeSwitch);
  }
}

/// Named sound cue taxonomy.
enum SoundCue {
  brandChord,
  modeSwitch,
  scanStart,
  scanSuccess,
  scanFail,
  verifySuccess,
  verifyFail,
  paymentReceived,
  paymentSent,
  tierUpgrade,
  gateChange,
  flightOnTime,
  flightDelayed,
  documentAdded,
  documentExpiring,
  notificationPop,
  commandPaletteOpen,
  commandPaletteClose,
  cardFlip,
  passReveal,
}
