/**
 * v2 layout barrel — primary chrome surface for the app.
 *
 * The legacy `AppShell.tsx`, `BottomTabBar.tsx`, and `PageTransition.tsx`
 * variants were removed once every screen migrated to the v2 system.
 * `AppChromeV2` is the only chrome wrapper used in `App.tsx`; everything
 * else here is a re-export so screens can import from a single barrel.
 */

export { default as AppChromeV2 } from "./AppChrome";
export { default as BottomNavV2 } from "./BottomNav";
export { default as PageTransitionV2 } from "./PageTransition";
export { default as SplashV2 } from "./Splash";
export { default as CommandPaletteProvider } from "./CommandPalette";
export { useCommandPalette } from "./use-command-palette";
