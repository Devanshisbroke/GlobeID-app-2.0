import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';
import '../../data/api/api_provider.dart';
import '../../data/api/globeid_api.dart';
import '../../data/models/lifecycle.dart';

@immutable
class LifecycleState {
  const LifecycleState({
    required this.trips,
    required this.hydrated,
    required this.loading,
    this.error,
  });

  final List<TripLifecycle> trips;
  final bool hydrated;
  final bool loading;
  final String? error;

  LifecycleState copyWith({
    List<TripLifecycle>? trips,
    bool? hydrated,
    bool? loading,
    String? error,
  }) =>
      LifecycleState(
        trips: trips ?? this.trips,
        hydrated: hydrated ?? this.hydrated,
        loading: loading ?? this.loading,
        error: error,
      );

  Map<String, dynamic> toJson() => {
        'trips': trips.map((t) => t.toJson()).toList(),
      };

  static LifecycleState fromJson(Map<String, dynamic> j) => LifecycleState(
        trips: ((j['trips'] as List?) ?? const [])
            .map((e) => TripLifecycle.fromJson(e as Map<String, dynamic>))
            .toList(),
        hydrated: false,
        loading: false,
      );

  static LifecycleState initial() =>
      const LifecycleState(trips: [], hydrated: false, loading: false);
}

class LifecycleController extends Notifier<LifecycleState> {
  static const _key = 'lifecycleStore';

  GlobeIdApi get _api => ref.read(globeIdApiProvider);

  @override
  LifecycleState build() {
    final j = Preferences.instance.readJson(_key);
    if (j != null) {
      try {
        return LifecycleState.fromJson(j);
      } catch (_) {/* ignore */}
    }
    return LifecycleState.initial();
  }

  Future<void> hydrate() async {
    state = state.copyWith(loading: true);
    try {
      final trips = await _api.lifecycleTrips();
      state = state.copyWith(
        trips: trips,
        hydrated: true,
        loading: false,
        error: null,
      );
      await Preferences.instance.writeJson(_key, state.toJson());
    } catch (e) {
      state =
          state.copyWith(loading: false, error: e.toString(), hydrated: true);
    }
  }

  TripLifecycle? findTrip(String id) {
    for (final t in state.trips) {
      if (t.id == id) return t;
    }
    return null;
  }
}

final lifecycleProvider = NotifierProvider<LifecycleController, LifecycleState>(
    LifecycleController.new);
