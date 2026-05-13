import 'dart:math' as math;

import '../../data/models/wallet_models.dart';

/// `FxRecommendation` — a single Copilot-grade FX move surfaced to
/// the bearer. Captures the *what*, the *why*, and the *upside* in
/// a shape the UI can render without further computation.
class FxRecommendation {
  const FxRecommendation({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromFlag,
    required this.toFlag,
    required this.suggestedAmount,
    required this.estimatedReceive,
    required this.rationale,
    required this.deltaPercent,
    required this.estimatedSavings,
    required this.strength,
  });

  /// Source currency code (e.g. `USD`).
  final String fromCurrency;

  /// Destination currency code (e.g. `EUR`).
  final String toCurrency;

  /// Flag glyph for [fromCurrency].
  final String fromFlag;

  /// Flag glyph for [toCurrency].
  final String toFlag;

  /// Amount the bearer should convert in [fromCurrency].
  final double suggestedAmount;

  /// Estimated amount received in [toCurrency] at the live rate.
  final double estimatedReceive;

  /// Headline mono-cap rationale shown above the card. ≤ 28 chars
  /// to keep the cap rail rhythm.
  final String rationale;

  /// Today's delta vs. the prior day, as a signed percentage.
  /// e.g. `0.74` means +0.74% (rate improved by 0.74% in
  /// destination terms).
  final double deltaPercent;

  /// Estimated upside in *destination* currency for converting
  /// [suggestedAmount] today vs. yesterday.
  final double estimatedSavings;

  /// Confidence / urgency. Drives the breathing cadence on the
  /// surface card and the "WHY NOW?" tier.
  final FxStrength strength;
}

/// Confidence tier for an [FxRecommendation]. Higher = more
/// aggressive breathing cadence + more urgent eyebrow.
enum FxStrength {
  /// Cosmetic — rate move is real but small. Card breathes idle.
  passive,

  /// Material — rate move is worth surfacing. Card breathes armed.
  notable,

  /// Strong — rate move is unusually large. Card breathes active.
  high,
}

/// `FxAdvisor` — the deterministic engine that turns a wallet
/// snapshot into a list of Copilot recommendations. Pure Dart, no
/// I/O, no clocks — the same input always produces the same output
/// (essential for tests and for the demo to look stable).
class FxAdvisor {
  const FxAdvisor({
    this.maxResults = 5,
    this.minDeltaBps = 25,
    this.notableDeltaBps = 50,
    this.highDeltaBps = 110,
  });

  /// Hard cap on how many recommendations the advisor returns.
  final int maxResults;

  /// Minimum daily delta (in basis points, 1 bps = 0.01%) to
  /// surface a recommendation at all. Filters out cosmetic moves.
  final int minDeltaBps;

  /// Daily delta (bps) at which a recommendation is promoted from
  /// `passive` to `notable`.
  final int notableDeltaBps;

  /// Daily delta (bps) at which a recommendation is promoted to
  /// `high`. Triggers the most aggressive cadence and copy.
  final int highDeltaBps;

  /// Compute the recommendation list for a wallet snapshot. The
  /// algorithm is deterministic and brand-stable for the demo:
  ///
  ///   1. Each non-default balance is a candidate destination
  ///      ("convert from default INTO this currency").
  ///   2. Each balance computes a synthetic daily delta from
  ///      `currency.hashCode` — gives stable per-currency moves
  ///      across runs (so screenshots and tests don't churn).
  ///   3. Anything below [minDeltaBps] is dropped.
  ///   4. Suggested amount is 10–25% of the default balance,
  ///      capped at 1 000 in the default unit, rounded to the
  ///      nearest 25.
  ///   5. Results sorted by absolute delta descending; capped at
  ///      [maxResults].
  List<FxRecommendation> recommend({
    required List<WalletBalance> balances,
    required String defaultCurrency,
  }) {
    if (balances.isEmpty) return const [];
    final fromBalance = balances.firstWhere(
      (b) => b.currency == defaultCurrency,
      orElse: () => balances.first,
    );
    final fromAmount = fromBalance.amount;
    if (fromAmount <= 0) return const [];

    final out = <FxRecommendation>[];
    for (final to in balances) {
      if (to.currency == fromBalance.currency) continue;
      final deltaBps = _syntheticDeltaBps(
        from: fromBalance.currency,
        to: to.currency,
      );
      if (deltaBps.abs() < minDeltaBps) continue;

      final suggestedAmount = _suggestedAmount(fromAmount);
      // 1 unit of `from` → `to.rate / fromBalance.rate` units of `to`.
      final crossRate = fromBalance.rate == 0
          ? to.rate
          : to.rate / fromBalance.rate;
      final estimatedReceive = suggestedAmount * crossRate;
      final estimatedSavings = estimatedReceive * (deltaBps / 10000.0);
      final strength = _strength(deltaBps.abs());
      final rationale = _rationale(strength, deltaBps);

      out.add(
        FxRecommendation(
          fromCurrency: fromBalance.currency,
          toCurrency: to.currency,
          fromFlag: fromBalance.flag,
          toFlag: to.flag,
          suggestedAmount: suggestedAmount,
          estimatedReceive: estimatedReceive,
          rationale: rationale,
          deltaPercent: deltaBps / 100.0,
          estimatedSavings: estimatedSavings,
          strength: strength,
        ),
      );
    }

    out.sort((a, b) =>
        b.deltaPercent.abs().compareTo(a.deltaPercent.abs()));
    if (out.length > maxResults) {
      return out.sublist(0, maxResults);
    }
    return out;
  }

  /// Returns a stable synthetic daily delta (in bps) for a from/to
  /// pair. Range roughly [-180, 180] bps. Combines hashes of both
  /// codes so the demo doesn't show a uniform sign across all
  /// pairs.
  int _syntheticDeltaBps({required String from, required String to}) {
    final seed = (from.hashCode ^ (to.hashCode * 1103515245)).abs();
    // Map seed to [-180, 180] in a way that produces a meaningful
    // spread across currency codes.
    final mod = seed % 361; // 0..360
    return mod - 180;
  }

  double _suggestedAmount(double balance) {
    if (balance <= 0) return 0;
    final raw = math.min(balance * 0.18, 1000.0);
    // Round to the nearest 25.
    final rounded = (raw / 25.0).round() * 25.0;
    return math.max(rounded, 25.0);
  }

  FxStrength _strength(int absDeltaBps) {
    if (absDeltaBps >= highDeltaBps) return FxStrength.high;
    if (absDeltaBps >= notableDeltaBps) return FxStrength.notable;
    return FxStrength.passive;
  }

  String _rationale(FxStrength strength, int deltaBps) {
    final sign = deltaBps >= 0 ? '+' : '−';
    final pctText = '$sign${(deltaBps.abs() / 100.0).toStringAsFixed(2)}%';
    switch (strength) {
      case FxStrength.high:
        return 'STRONG MOVE · $pctText TODAY';
      case FxStrength.notable:
        return 'RATE $pctText TODAY';
      case FxStrength.passive:
        return 'EDGE $pctText';
    }
  }
}
