import 'dart:async';

import 'visa_adapter.dart';
import 'visa_models.dart';

/// `VisaService` — wraps a [VisaAdapter] with per-corridor cache
/// + single-flight + fallback chain. Mirrors the FX / Flight
/// services so every production-data surface has the same shape.
class VisaService {
  VisaService({
    required this.adapter,
    this.fallback,
    this.staleThreshold = const Duration(days: 7),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VisaAdapter adapter;
  final VisaAdapter? fallback;
  final Duration staleThreshold;
  final DateTime Function() _now;

  final _cache = <VisaCorridor, VisaRule>{};
  final _inflight = <VisaCorridor, Completer<VisaRule>>{};

  VisaRule? cached(VisaCorridor corridor) => _cache[corridor];

  bool isStale(VisaCorridor corridor) {
    final r = _cache[corridor];
    if (r == null) return false;
    return _now().difference(r.fetchedAt) > staleThreshold;
  }

  Future<VisaRule> resolve(VisaCorridor corridor) async {
    final inflight = _inflight[corridor];
    if (inflight != null) return inflight.future;
    final completer = Completer<VisaRule>();
    completer.future.ignore();
    _inflight[corridor] = completer;
    try {
      VisaRule rule;
      try {
        rule = await adapter.rule(corridor);
      } catch (e) {
        if (fallback == null) rethrow;
        final fb = await fallback!.rule(corridor);
        rule = fb.copyWith(source: '${fallback!.source}+fallback');
      }
      _cache[corridor] = rule;
      completer.complete(rule);
      return rule;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inflight.remove(corridor);
    }
  }

  Future<List<VisaRule>> rulesFor(String passport) async {
    try {
      final rules = await adapter.rulesFor(passport);
      for (final r in rules) {
        _cache[r.corridor] = r;
      }
      return rules;
    } catch (e) {
      if (fallback == null) rethrow;
      final fb = await fallback!.rulesFor(passport);
      final tagged = [
        for (final r in fb)
          r.copyWith(source: '${fallback!.source}+fallback'),
      ];
      for (final r in tagged) {
        _cache[r.corridor] = r;
      }
      return tagged;
    }
  }
}
