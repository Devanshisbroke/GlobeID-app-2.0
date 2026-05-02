/**
 * Canonical z-index ladder.
 *
 * Use these constants instead of bare class names like `z-50` /
 * `z-[60]`. The numeric values match the existing Tailwind utilities so
 * old sites can migrate gradually:
 *
 *   bg-mesh, atmosphere   →  Z.background  (−10 / −5)
 *   in-page content       →  Z.content     ( 10 / 20)
 *   sticky banners        →  Z.banner      ( 30)
 *   floating chrome       →  Z.chrome      ( 40)
 *   FAB + bottom nav      →  Z.fab         ( 50)
 *   sheets, command bar   →  Z.sheet       ( 60)
 *   full-screen overlays  →  Z.overlay     (100)
 *   toast / shortcuts     →  Z.toast       (200)
 *
 * The ladder is *strict*: every layer is at least one full step higher
 * than the layer it sits above. We do not interleave floating chrome
 * inside sheets, so a sheet (60) always covers the FAB (50) and the
 * FAB always covers a sticky banner (30). The only exception is the
 * top-level ErrorBoundary which uses 200 so the recovery surface
 * unconditionally beats every other layer.
 */

export const Z = {
  background: -10,
  atmosphere: -5,
  content: 10,
  contentRaised: 20,
  banner: 30,
  chrome: 40,
  fab: 50,
  sheet: 60,
  overlay: 100,
  toast: 200,
} as const;

export type ZLayer = keyof typeof Z;
