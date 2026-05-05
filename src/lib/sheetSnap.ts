/**
 * Bottom-sheet snap-point helpers (BACKLOG J 114).
 *
 * Pure: no React, no DOM. Given the current drag offset (px) and a list
 * of snap-point fractions (e.g. [0.25, 0.6, 0.95]), pick the nearest
 * snap point + return the resting offset.
 *
 * Velocity-based: if the user is flicking, prefer the next snap in the
 * direction of velocity rather than the geometrically-nearest snap.
 */

export interface SnapInput {
  /** Current drag Y offset, where 0 = sheet at top of viewport. */
  currentY: number;
  /** Total sheet content height. */
  containerHeight: number;
  /** Snap points as fractions of containerHeight (e.g. [0.25,0.6,0.95]). */
  snaps: number[];
  /** Velocity in px/ms (positive = downward). */
  velocity?: number;
}

export interface SnapResult {
  /** Final resting offset. */
  restY: number;
  /** Index of the snap point chosen. */
  index: number;
  /** Fraction of containerHeight the sheet now sits at. */
  fraction: number;
}

const VELOCITY_THRESHOLD = 0.5; // px / ms

export function chooseSnap(input: SnapInput): SnapResult {
  const { currentY, containerHeight, snaps } = input;
  const v = input.velocity ?? 0;
  if (snaps.length === 0)
    return { restY: 0, index: 0, fraction: 1 };

  const sorted = [...snaps].sort((a, b) => a - b);
  // Convert fraction → offset (top-anchored: 0 = fully open).
  const offsets = sorted.map((f) => containerHeight * (1 - f));

  if (Math.abs(v) > VELOCITY_THRESHOLD) {
    // Pick neighbour in velocity direction.
    // Sorted ascending by fraction → low index = lowest fraction = sheet
    // mostly closed. Downward fling (v > 0) wants a smaller fraction so
    // we step *down* the sorted index. Upward fling steps up.
    const currentIdx = closestIndex(offsets, currentY);
    const dir = v > 0 ? -1 : 1;
    const nextIdx = clamp(currentIdx + dir, 0, offsets.length - 1);
    return {
      restY: offsets[nextIdx]!,
      index: nextIdx,
      fraction: sorted[nextIdx]!,
    };
  }

  const idx = closestIndex(offsets, currentY);
  return {
    restY: offsets[idx]!,
    index: idx,
    fraction: sorted[idx]!,
  };
}

function closestIndex(arr: number[], v: number): number {
  let best = 0;
  let bestDist = Infinity;
  for (let i = 0; i < arr.length; i += 1) {
    const d = Math.abs(arr[i]! - v);
    if (d < bestDist) {
      best = i;
      bestDist = d;
    }
  }
  return best;
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, n));
}
