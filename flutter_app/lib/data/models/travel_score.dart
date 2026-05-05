class TravelScore {
  TravelScore({
    required this.score,
    required this.tier,
    required this.factors,
    required this.history,
  });

  final int score;
  final int tier; // 0..3
  final List<TravelScoreFactor> factors;
  final List<int> history;

  factory TravelScore.fromJson(Map<String, dynamic> j) => TravelScore(
        score: (j['score'] as num?)?.toInt() ?? 0,
        tier: (j['tier'] as num?)?.toInt() ?? 0,
        factors: ((j['factors'] as List?) ?? const [])
            .map((e) => TravelScoreFactor.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: ((j['history'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
}

class TravelScoreFactor {
  TravelScoreFactor({
    required this.id,
    required this.label,
    required this.weight,
    required this.value,
  });

  final String id;
  final String label;
  final double weight;
  final double value;

  factory TravelScoreFactor.fromJson(Map<String, dynamic> j) =>
      TravelScoreFactor(
        id: j['id'] as String,
        label: j['label'] as String,
        weight: (j['weight'] as num).toDouble(),
        value: (j['value'] as num).toDouble(),
      );
}
