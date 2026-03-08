/**
 * GlobeID Cinematic Color System
 * Premium palette tokens for cinematic UI layers
 */

export const cinematicColors = {
  deepSpace: "228 20% 4%",
  auroraBlue: "220 85% 62%",
  solarOrange: "25 95% 58%",
  cosmicPurple: "258 65% 65%",
  neonCyan: "200 90% 60%",
  stellarGold: "42 94% 58%",
  nebulaPink: "330 72% 65%",
  voidBlack: "228 18% 3%",
} as const;

export const cinematicGradients = {
  deepSpace: "linear-gradient(135deg, hsl(228 20% 4%), hsl(228 18% 8%))",
  auroraGlow: "linear-gradient(135deg, hsl(220 85% 62% / 0.15), hsl(258 65% 65% / 0.1), hsl(200 90% 60% / 0.05))",
  solarFlare: "linear-gradient(135deg, hsl(25 95% 58% / 0.12), hsl(42 94% 58% / 0.08))",
  cosmicDust: "radial-gradient(ellipse at 30% 20%, hsl(258 65% 65% / 0.08) 0%, transparent 50%), radial-gradient(ellipse at 70% 80%, hsl(200 90% 60% / 0.06) 0%, transparent 50%)",
  nebulaMist: "radial-gradient(ellipse at 50% 50%, hsl(330 72% 65% / 0.06) 0%, transparent 60%)",
  heroShimmer: "linear-gradient(115deg, transparent 30%, hsl(0 0% 100% / 0.03) 45%, hsl(0 0% 100% / 0.06) 50%, hsl(0 0% 100% / 0.03) 55%, transparent 70%)",
} as const;
