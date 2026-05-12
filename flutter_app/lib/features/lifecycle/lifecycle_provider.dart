import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';
import '../../data/api/api_provider.dart';
import '../../data/api/demo_data.dart';
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

  /// Synchronous fresh-install seed — populates the Travel tab and the
  /// Pulse focal trip slab with realistic upcoming + past journeys so
  /// the surface is never blank on cold install.
  static LifecycleState seed() => LifecycleState(
        trips: DemoData.seedLifecycleTrips()
            .map((j) => TripLifecycle.fromJson(Map<String, dynamic>.from(j)))
            .toList(growable: false),
        hydrated: false,
        loading: false,
      );
}

class LifecycleController extends Notifier<LifecycleState> {
  static const _key = 'lifecycleStore';

  GlobeIdApi get _api => ref.read(globeIdApiProvider);

  @override
  LifecycleState build() {
    final j = Preferences.instance.readJson(_key);
    if (j != null) {
      try {
        final cached = LifecycleState.fromJson(j);
        // Defensive: an upgraded install with an empty cached trip list
        // (e.g. a previous build that failed to persist its hydrate)
        // would otherwise look identical to a fresh install. Re-seed in
        // that edge case so the Travel tab is never blank.
        if (cached.trips.isEmpty) return LifecycleState.seed();
        return cached;
      } catch (_) {/* ignore */}
    }
    // Fresh install — seed the Travel tab with the canonical demo trip
    // ladder so it renders rich UI on first paint.
    return LifecycleState.seed();
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
