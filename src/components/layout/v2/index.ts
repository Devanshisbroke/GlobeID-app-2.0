/**
 * Phase 7 PR-γ — v2 layout barrel.
 *
 * The v2 chrome is parallel to the legacy `src/components/layout/AppShell.tsx`
 * during the migration window. App.tsx imports `AppChromeV2` here; legacy
 * AppShell.tsx remains on disk for back-compat reference until PR-ζ removes
 * it in the final cleanup pass.
 */

export { default as AppChromeV2 } from "./AppChrome";
export { default as BottomNavV2 } from "./BottomNav";
export { default as PageTransitionV2 } from "./PageTransition";
export { default as SplashV2 } from "./Splash";
export { default as CommandPaletteProvider } from "./CommandPalette";
export { useCommandPalette } from "./use-command-palette";
