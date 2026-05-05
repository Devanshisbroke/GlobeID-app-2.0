/**
 * Achievement detector (BACKLOG K 135).
 *
 * Pure function that diff'ing two snapshots produces the set of
 * achievements newly unlocked. Caller is responsible for firing the
 * confetti / haptic side-effects (so this module stays unit-testable).
 *
 * Threshold ladder (deterministic, hard-coded — no surprise behaviour):
 *
 *   trips:        1 (first trip), 5, 10, 25, 50, 100
 *   scans:        1 (first scan), 10, 50
 *   countries:    1 (first country), 5, 10, 25, 50, 100
 *   continents:   1, 3, 5, 7
 *
 * Each achievement has a `tone` for the UI badge + a `body` line so the
 * toast / overlay has copy ready without the caller composing it.
 */

export type AchievementId =
  | "first-trip"
  | "trips-5"
  | "trips-10"
  | "trips-25"
  | "trips-50"
  | "trips-100"
  | "first-scan"
  | "scans-10"
  | "scans-50"
  | "first-country"
  | "countries-5"
  | "countries-10"
  | "countries-25"
  | "countries-50"
  | "countries-100"
  | "continent-3"
  | "continent-5"
  | "continent-all";

export interface Achievement {
  id: AchievementId;
  title: string;
  body: string;
  tone: "brand" | "premium" | "success";
}

const ACHIEVEMENTS: Record<AchievementId, Achievement> = {
  "first-trip": {
    id: "first-trip",
    title: "First trip booked",
    body: "Welcome to GlobeID. Your travel timeline begins.",
    tone: "brand",
  },
  "trips-5": {
    id: "trips-5",
    title: "5 trips planned",
    body: "You've crossed the casual-traveller threshold.",
    tone: "brand",
  },
  "trips-10": {
    id: "trips-10",
    title: "10 trips logged",
    body: "Frequent flyer territory.",
    tone: "success",
  },
  "trips-25": {
    id: "trips-25",
    title: "25 trips logged",
    body: "You spend more time in the air than most spend on email.",
    tone: "success",
  },
  "trips-50": {
    id: "trips-50",
    title: "50 trips logged",
    body: "Half a hundred — that's a serious history.",
    tone: "premium",
  },
  "trips-100": {
    id: "trips-100",
    title: "100 trips logged",
    body: "Centurion of the skies. Respect.",
    tone: "premium",
  },
  "first-scan": {
    id: "first-scan",
    title: "First document scanned",
    body: "Your vault is open. Privacy stays on-device.",
    tone: "brand",
  },
  "scans-10": {
    id: "scans-10",
    title: "10 documents scanned",
    body: "Vault stocked. Time to enable auto-lock.",
    tone: "brand",
  },
  "scans-50": {
    id: "scans-50",
    title: "50 documents scanned",
    body: "Full archive. Consider exporting an encrypted backup.",
    tone: "success",
  },
  "first-country": {
    id: "first-country",
    title: "First country visited",
    body: "Welcome to the citizen-of-the-world club.",
    tone: "brand",
  },
  "countries-5": {
    id: "countries-5",
    title: "5 countries visited",
    body: "Five flags pinned to the globe.",
    tone: "brand",
  },
  "countries-10": {
    id: "countries-10",
    title: "10 countries visited",
    body: "Double digits.",
    tone: "success",
  },
  "countries-25": {
    id: "countries-25",
    title: "25 countries visited",
    body: "An eighth of the world.",
    tone: "success",
  },
  "countries-50": {
    id: "countries-50",
    title: "50 countries visited",
    body: "A quarter of every nation. Rare air.",
    tone: "premium",
  },
  "countries-100": {
    id: "countries-100",
    title: "100 countries visited",
    body: "Half the planet. The Travelers' Century Club beckons.",
    tone: "premium",
  },
  "continent-3": {
    id: "continent-3",
    title: "3 continents visited",
    body: "Multi-continent traveller.",
    tone: "brand",
  },
  "continent-5": {
    id: "continent-5",
    title: "5 continents visited",
    body: "Five down — chasing the seven.",
    tone: "success",
  },
  "continent-all": {
    id: "continent-all",
    title: "Every continent visited",
    body: "Even Antarctica. The full set.",
    tone: "premium",
  },
};

export interface AchievementSnapshot {
  trips: number;
  scans: number;
  countries: number;
  continents: number;
}

const TRIP_LADDER: Array<{ at: number; id: AchievementId }> = [
  { at: 1, id: "first-trip" },
  { at: 5, id: "trips-5" },
  { at: 10, id: "trips-10" },
  { at: 25, id: "trips-25" },
  { at: 50, id: "trips-50" },
  { at: 100, id: "trips-100" },
];

const SCAN_LADDER: Array<{ at: number; id: AchievementId }> = [
  { at: 1, id: "first-scan" },
  { at: 10, id: "scans-10" },
  { at: 50, id: "scans-50" },
];

const COUNTRY_LADDER: Array<{ at: number; id: AchievementId }> = [
  { at: 1, id: "first-country" },
  { at: 5, id: "countries-5" },
  { at: 10, id: "countries-10" },
  { at: 25, id: "countries-25" },
  { at: 50, id: "countries-50" },
  { at: 100, id: "countries-100" },
];

const CONTINENT_LADDER: Array<{ at: number; id: AchievementId }> = [
  { at: 3, id: "continent-3" },
  { at: 5, id: "continent-5" },
  { at: 7, id: "continent-all" },
];

function ladderUnlocked(
  ladder: Array<{ at: number; id: AchievementId }>,
  prev: number,
  next: number,
): AchievementId[] {
  return ladder
    .filter(({ at }) => prev < at && next >= at)
    .map(({ id }) => id);
}

/**
 * Compute the achievements newly unlocked between two snapshots. Returns
 * the full Achievement objects (in ladder order, deduplicated). Empty
 * array when no thresholds were crossed.
 */
export function diffAchievements(
  prev: AchievementSnapshot,
  next: AchievementSnapshot,
): Achievement[] {
  const ids: AchievementId[] = [
    ...ladderUnlocked(TRIP_LADDER, prev.trips, next.trips),
    ...ladderUnlocked(SCAN_LADDER, prev.scans, next.scans),
    ...ladderUnlocked(COUNTRY_LADDER, prev.countries, next.countries),
    ...ladderUnlocked(CONTINENT_LADDER, prev.continents, next.continents),
  ];
  const seen = new Set<AchievementId>();
  const out: Achievement[] = [];
  for (const id of ids) {
    if (seen.has(id)) continue;
    seen.add(id);
    out.push(ACHIEVEMENTS[id]);
  }
  return out;
}

export function getAchievement(id: AchievementId): Achievement {
  return ACHIEVEMENTS[id];
}
