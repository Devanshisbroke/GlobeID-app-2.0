import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';

@immutable
class OnboardingState {
  const OnboardingState({
    required this.completed,
    required this.completedAt,
  });

  final bool completed;
  final DateTime? completedAt;

  OnboardingState copyWith({
    bool? completed,
    DateTime? completedAt,
  }) =>
      OnboardingState(
        completed: completed ?? this.completed,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    final rawCompletedAt = json['completedAt'] as String?;
    return OnboardingState(
      completed: (json['completed'] as bool?) ?? false,
      completedAt:
          rawCompletedAt == null ? null : DateTime.tryParse(rawCompletedAt),
    );
  }

  static const initial = OnboardingState(
    completed: false,
    completedAt: null,
  );
}

class OnboardingController extends Notifier<OnboardingState> {
  static const _key = 'onboardingStore';

  @override
  OnboardingState build() {
    final json = Preferences.instance.readJson(_key);
    if (json != null) {
      try {
        return OnboardingState.fromJson(json);
      } catch (_) {/* keep first-run fallback */}
    }
    return OnboardingState.initial;
  }

  Future<void> complete() async {
    state = OnboardingState(completed: true, completedAt: DateTime.now());
    await Preferences.instance.writeJson(_key, state.toJson());
  }

  Future<void> reset() async {
    state = OnboardingState.initial;
    await Preferences.instance.writeJson(_key, state.toJson());
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
