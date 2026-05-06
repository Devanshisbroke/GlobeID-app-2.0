import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';

@immutable
class SessionLockState {
  const SessionLockState({
    required this.locked,
    required this.enabled,
    required this.lastActiveAt,
    required this.timeout,
    required this.reason,
  });

  final bool locked;
  final bool enabled;
  final DateTime? lastActiveAt;
  final Duration timeout;
  final String? reason;

  static const Object _unset = Object();

  SessionLockState copyWith({
    bool? locked,
    bool? enabled,
    DateTime? lastActiveAt,
    Duration? timeout,
    Object? reason = _unset,
  }) =>
      SessionLockState(
        locked: locked ?? this.locked,
        enabled: enabled ?? this.enabled,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        timeout: timeout ?? this.timeout,
        reason: identical(reason, _unset) ? this.reason : reason as String?,
      );

  Map<String, dynamic> toJson() => {
        'locked': locked,
        'enabled': enabled,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'timeoutSeconds': timeout.inSeconds,
        'reason': reason,
      };

  static SessionLockState fromJson(Map<String, dynamic> json) {
    final rawLastActiveAt = json['lastActiveAt'] as String?;
    final timeoutSeconds = json['timeoutSeconds'] as int?;
    return SessionLockState(
      locked: (json['locked'] as bool?) ?? false,
      enabled: (json['enabled'] as bool?) ?? true,
      lastActiveAt:
          rawLastActiveAt == null ? null : DateTime.tryParse(rawLastActiveAt),
      timeout: Duration(seconds: timeoutSeconds ?? 180),
      reason: json['reason'] as String?,
    );
  }

  static const initial = SessionLockState(
    locked: false,
    enabled: true,
    lastActiveAt: null,
    timeout: Duration(minutes: 3),
    reason: null,
  );
}

class SessionLockController extends Notifier<SessionLockState> {
  static const _key = 'sessionLockStore';

  @override
  SessionLockState build() {
    final json = Preferences.instance.readJson(_key);
    if (json != null) {
      try {
        return SessionLockState.fromJson(json);
      } catch (_) {/* keep unlocked fallback */}
    }
    return SessionLockState.initial;
  }

  Future<void> markInactive() async {
    state = state.copyWith(lastActiveAt: DateTime.now());
    await _persist();
  }

  Future<void> evaluateResume() async {
    if (!state.enabled || state.locked) return;
    final lastActiveAt = state.lastActiveAt;
    if (lastActiveAt == null) return;
    final awayFor = DateTime.now().difference(lastActiveAt);
    if (awayFor >= state.timeout) {
      await lock(
          reason: 'Auto-locked after ${state.timeout.inMinutes} minutes');
    }
  }

  Future<void> lock({String? reason}) async {
    state = state.copyWith(
      locked: true,
      reason: reason ?? 'Locked for your security',
      lastActiveAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> unlock() async {
    state = state.copyWith(
      locked: false,
      reason: null,
      lastActiveAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _persist();
  }

  Future<void> _persist() => Preferences.instance.writeJson(
        _key,
        state.toJson(),
      );
}

final sessionLockProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
  SessionLockController.new,
);
