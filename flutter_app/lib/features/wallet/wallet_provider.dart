import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/preferences.dart';
import '../../data/api/api_provider.dart';
import '../../data/api/demo_data.dart';
import '../../data/api/globeid_api.dart';
import '../../data/models/wallet_models.dart';

/// Mirrors `src/store/walletStore.ts`.
@immutable
class WalletStateView {
  const WalletStateView({
    required this.balances,
    required this.transactions,
    required this.defaultCurrency,
    required this.activeCountry,
    required this.hydrated,
    required this.loading,
    this.error,
  });

  final List<WalletBalance> balances;
  final List<WalletTransaction> transactions;
  final String defaultCurrency;
  final String? activeCountry;
  final bool hydrated;
  final bool loading;
  final String? error;

  WalletStateView copyWith({
    List<WalletBalance>? balances,
    List<WalletTransaction>? transactions,
    String? defaultCurrency,
    String? activeCountry,
    bool? hydrated,
    bool? loading,
    String? error,
  }) =>
      WalletStateView(
        balances: balances ?? this.balances,
        transactions: transactions ?? this.transactions,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        activeCountry: activeCountry ?? this.activeCountry,
        hydrated: hydrated ?? this.hydrated,
        loading: loading ?? this.loading,
        error: error,
      );

  Map<String, dynamic> toJson() => {
        'balances': balances.map((b) => b.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'defaultCurrency': defaultCurrency,
        if (activeCountry != null) 'activeCountry': activeCountry,
      };

  static WalletStateView fromJson(Map<String, dynamic> j) => WalletStateView(
        balances: ((j['balances'] as List?) ?? const [])
            .map((e) => WalletBalance.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: ((j['transactions'] as List?) ?? const [])
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        defaultCurrency: (j['defaultCurrency'] as String?) ?? 'USD',
        activeCountry: j['activeCountry'] as String?,
        hydrated: false,
        loading: false,
      );

  static WalletStateView initial() => const WalletStateView(
        balances: [],
        transactions: [],
        defaultCurrency: 'USD',
        activeCountry: null,
        hydrated: false,
        loading: false,
      );

  /// Synchronous fresh-install seed — keeps the Treasury card from
  /// flashing $0.00 while the async wallet snapshot is in flight.
  /// Mirrors the offline DemoData wallet payload so the UI is alive on
  /// first paint regardless of network state.
  static WalletStateView seed() {
    final snap =
        WalletSnapshot.fromJson(Map<String, dynamic>.from(DemoData.seedWallet()));
    return WalletStateView(
      balances: snap.balances,
      transactions: snap.transactions,
      defaultCurrency: snap.state.defaultCurrency,
      activeCountry: snap.state.activeCountry,
      hydrated: false,
      loading: false,
    );
  }
}

class WalletController extends Notifier<WalletStateView> {
  static const _key = 'walletStore';
  final _uuid = const Uuid();

  GlobeIdApi get _api => ref.read(globeIdApiProvider);

  @override
  WalletStateView build() {
    final j = Preferences.instance.readJson(_key);
    if (j != null) {
      try {
        final cached = WalletStateView.fromJson(j);
        // Defensive re-seed: an upgrade install with empty balances
        // would render Treasury as $0.00 just like a cold install.
        if (cached.balances.isEmpty) {
          final seed = WalletStateView.seed();
          return cached.copyWith(
            balances: seed.balances,
            transactions:
                cached.transactions.isEmpty ? seed.transactions : null,
          );
        }
        return cached;
      } catch (_) {/* ignore */}
    }
    // Fresh install — seed Treasury balances + transactions from the
    // canonical demo payload so the wallet card never reads $0.00.
    return WalletStateView.seed();
  }

  Future<void> _persist() =>
      Preferences.instance.writeJson(_key, state.toJson());

  Future<void> hydrate() async {
    state = state.copyWith(loading: true);
    try {
      final snap = await _api.walletSnapshot();
      state = state.copyWith(
        balances: snap.balances,
        transactions: snap.transactions,
        defaultCurrency: snap.state.defaultCurrency,
        activeCountry: snap.state.activeCountry,
        hydrated: true,
        loading: false,
        error: null,
      );
      await _persist();
    } catch (e) {
      state =
          state.copyWith(loading: false, error: e.toString(), hydrated: true);
    }
  }

  Future<void> setDefaultCurrency(String code) async {
    state = state.copyWith(defaultCurrency: code);
    await _persist();
    try {
      await _api.walletUpdateState({'defaultCurrency': code});
    } catch (_) {}
  }

  Future<void> setActiveCountry(String? country) async {
    state = state.copyWith(activeCountry: country);
    await _persist();
    try {
      await _api.walletUpdateState({'activeCountry': country});
    } catch (_) {}
  }

  Future<void> recordTransaction({
    required String type,
    required double amount,
    required String currency,
    required String description,
    required String category,
    required String icon,
    String? merchant,
    String? location,
  }) async {
    try {
      final res = await _api.walletRecord({
        'idempotencyKey': _uuid.v4(),
        'type': type,
        'amount': amount,
        'currency': currency,
        'description': description,
        'category': category,
        'icon': icon,
        if (merchant != null) 'merchant': merchant,
        if (location != null) 'location': location,
      });
      final tx = WalletTransaction.fromJson(
          res['transaction'] as Map<String, dynamic>);
      final bal =
          WalletBalance.fromJson(res['balance'] as Map<String, dynamic>);
      final newBalances = [
        for (final b in state.balances)
          if (b.currency == bal.currency) bal else b,
      ];
      if (!newBalances.any((b) => b.currency == bal.currency)) {
        newBalances.add(bal);
      }
      state = state.copyWith(
        balances: newBalances,
        transactions: [tx, ...state.transactions],
      );
      await _persist();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final walletProvider =
    NotifierProvider<WalletController, WalletStateView>(WalletController.new);
