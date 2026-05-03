/** Accent palette — split out from themePrefs so other modules can
 * consume the swatch list without pulling the side-effecting setters. */

export interface AccentOption {
  id: string;
  name: string;
  /** HSL triple in token form: "H S% L%". */
  hsl: string;
  /** Hover/pressed strong variant. */
  hslStrong: string;
}

export const ACCENTS: readonly AccentOption[] = [
  { id: "azure",  name: "Azure",  hsl: "219 67% 54%", hslStrong: "219 72% 46%" },
  { id: "ocean",  name: "Ocean",  hsl: "200 80% 48%", hslStrong: "200 85% 40%" },
  { id: "mint",   name: "Mint",   hsl: "168 65% 42%", hslStrong: "168 70% 36%" },
  { id: "lime",   name: "Lime",   hsl: "100 60% 44%", hslStrong: "100 65% 38%" },
  { id: "amber",  name: "Amber",  hsl: "38 92% 50%",  hslStrong: "38 95% 44%"  },
  { id: "coral",  name: "Coral",  hsl: "12 86% 60%",  hslStrong: "12 90% 52%"  },
  { id: "rose",   name: "Rose",   hsl: "340 78% 56%", hslStrong: "340 82% 48%" },
  { id: "violet", name: "Violet", hsl: "266 78% 62%", hslStrong: "266 82% 54%" },
] as const;

export const DEFAULT_ACCENT_ID = "azure";
