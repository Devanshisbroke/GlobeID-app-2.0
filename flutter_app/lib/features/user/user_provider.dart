import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';
import '../../data/api/api_provider.dart';
import '../../data/api/globeid_api.dart';
import '../../data/models/travel_document.dart';
import '../../data/models/travel_record.dart';
import '../../data/models/user_profile.dart';

/// Mirrors `src/store/userStore.ts` — profile + records + documents.
@immutable
class UserState {
  const UserState({
    required this.profile,
    required this.records,
    required this.documents,
    required this.hydrated,
    required this.loading,
    this.error,
  });

  final UserProfile profile;
  final List<TravelRecord> records;
  final List<TravelDocument> documents;
  final bool hydrated;
  final bool loading;
  final String? error;

  UserState copyWith({
    UserProfile? profile,
    List<TravelRecord>? records,
    List<TravelDocument>? documents,
    bool? hydrated,
    bool? loading,
    String? error,
  }) =>
      UserState(
        profile: profile ?? this.profile,
        records: records ?? this.records,
        documents: documents ?? this.documents,
        hydrated: hydrated ?? this.hydrated,
        loading: loading ?? this.loading,
        error: error,
      );

  static UserState initial() => UserState(
        profile: UserProfile.defaults(),
        records: const [],
        documents: const [],
        hydrated: false,
        loading: false,
      );

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'records': records.map((r) => r.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
      };

  static UserState fromJson(Map<String, dynamic> j) => UserState(
        profile: UserProfile.fromJson(j['profile'] as Map<String, dynamic>),
        records: ((j['records'] as List?) ?? const [])
            .map((e) => TravelRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        documents: ((j['documents'] as List?) ?? const [])
            .map((e) => TravelDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
        hydrated: false,
        loading: false,
      );
}

class UserController extends Notifier<UserState> {
  static const _key = 'userStore';

  GlobeIdApi get _api => ref.read(globeIdApiProvider);

  @override
  UserState build() {
    final prefs = Preferences.instance.readJson(_key);
    if (prefs != null) {
      try {
        return UserState.fromJson(prefs);
      } catch (_) {/* ignore */}
    }
    return UserState.initial();
  }

  Future<void> _persist() async {
    await Preferences.instance.writeJson(_key, state.toJson());
  }

  Future<void> hydrate() async {
    state = state.copyWith(loading: true);
    try {
      final results = await Future.wait<dynamic>([
        _api.me(),
        _api.tripsList(),
        _api.documents().catchError((Object _) => <TravelDocument>[]),
      ]);
      state = state.copyWith(
        profile: results[0] as UserProfile,
        records: results[1] as List<TravelRecord>,
        documents: results[2] as List<TravelDocument>,
        hydrated: true,
        loading: false,
        error: null,
      );
      await _persist();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        hydrated: true,
      );
    }
  }

  Future<void> addRecord(TravelRecord record) async {
    state = state.copyWith(records: [...state.records, record]);
    await _persist();
    try {
      await _api.tripsCreate([record]);
    } catch (_) {/* keep local for retry queue */}
  }

  Future<void> removeRecord(String id) async {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
    await _persist();
    try {
      await _api.tripsRemove(id);
    } catch (_) {}
  }

  Future<void> patchProfile(Map<String, dynamic> patch) async {
    try {
      final next = await _api.patchMe(patch);
      state = state.copyWith(profile: next);
      await _persist();
    } catch (_) {/* keep local */}
  }

  String exportJson() => jsonEncode(state.toJson());
}

final userProvider =
    NotifierProvider<UserController, UserState>(UserController.new);
