/// Dart port of `src/lib/identityTier.ts`. Maps a numeric identity
/// score to a tier (0..3) and a label/badge.
class IdentityTier {
  const IdentityTier(this.tier, this.label, this.threshold);
  final int tier;
  final String label;
  final int threshold;

  static const tiers = [
    IdentityTier(0, 'Wanderer', 0),
    IdentityTier(1, 'Voyager', 50),
    IdentityTier(2, 'Globetrotter', 75),
    IdentityTier(3, 'Aviator', 90),
  ];

  static IdentityTier forScore(int score) {
    var current = tiers.first;
    for (final t in tiers) {
      if (score >= t.threshold) current = t;
    }
    return current;
  }
}
