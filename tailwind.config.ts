import type { Config } from "tailwindcss";
import animate from "tailwindcss-animate";

export default {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "1rem",
      screens: { "2xl": "1400px" },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        warning: {
          DEFAULT: "hsl(var(--warning))",
          foreground: "hsl(var(--warning-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar-background))",
          foreground: "hsl(var(--sidebar-foreground))",
          primary: "hsl(var(--sidebar-primary))",
          "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
          accent: "hsl(var(--sidebar-accent))",
          "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
          border: "hsl(var(--sidebar-border))",
          ring: "hsl(var(--sidebar-ring))",
        },
        glass: {
          DEFAULT: "hsl(var(--glass-bg))",
          border: "hsl(var(--glass-border))",
        },

        /* ──────────────────────────────────────────────────────────────
           Phase 7 — additive palette referenceable as Tailwind classes
           (e.g. `bg-surface-base`, `text-ink-secondary`, `bg-brand`).
           v2 components consume these; legacy components stay untouched.
           ────────────────────────────────────────────────────────────── */
        surface: {
          base: "hsl(var(--p7-surface-base))",
          elevated: "hsl(var(--p7-surface-elevated))",
          overlay: "hsl(var(--p7-surface-overlay))",
          hairline: "hsl(var(--p7-surface-hairline))",
        },
        ink: {
          primary: "hsl(var(--p7-ink-primary))",
          secondary: "hsl(var(--p7-ink-secondary))",
          tertiary: "hsl(var(--p7-ink-tertiary))",
          "on-brand": "hsl(var(--p7-ink-on-brand))",
        },
        brand: {
          DEFAULT: "hsl(var(--p7-brand))",
          soft: "hsl(var(--p7-brand-soft))",
          strong: "hsl(var(--p7-brand-strong))",
        },
        "state-accent": {
          DEFAULT: "hsl(var(--p7-accent))",
          soft: "hsl(var(--p7-accent-soft))",
        },
        critical: {
          DEFAULT: "hsl(var(--p7-critical))",
          soft: "hsl(var(--p7-critical-soft))",
        },
      },
      fontFamily: {
        /* Phase 7: single Inter Variable stack with optical sizing for
           the display tier; JBM Variable for technical IDs (MRZ, hashes). */
        display: "var(--p7-font-display)",
        sans: "var(--p7-font-sans)",
        mono: "var(--p7-font-mono)",
      },
      fontSize: {
        /* Phase 7 type scale — pairs `[size, { lineHeight, letterSpacing, fontWeight }]`.
           These are net-new keys (`p7-display`, `p7-title-1`, …) so existing
           `text-xs` / `text-sm` / etc. utilities remain untouched. */
        "p7-display":   ["var(--p7-text-display)",   { lineHeight: "var(--p7-text-display-lh)",   letterSpacing: "var(--p7-text-display-track)",   fontWeight: "600" }],
        "p7-title-1":   ["var(--p7-text-title-1)",   { lineHeight: "var(--p7-text-title-1-lh)",   letterSpacing: "var(--p7-text-title-1-track)",   fontWeight: "600" }],
        "p7-title-2":   ["var(--p7-text-title-2)",   { lineHeight: "var(--p7-text-title-2-lh)",   letterSpacing: "var(--p7-text-title-2-track)",   fontWeight: "600" }],
        "p7-title-3":   ["var(--p7-text-title-3)",   { lineHeight: "var(--p7-text-title-3-lh)",   letterSpacing: "var(--p7-text-title-3-track)",   fontWeight: "600" }],
        "p7-body":      ["var(--p7-text-body)",      { lineHeight: "var(--p7-text-body-lh)",      letterSpacing: "var(--p7-text-body-track)",      fontWeight: "400" }],
        "p7-body-em":   ["var(--p7-text-body)",      { lineHeight: "var(--p7-text-body-lh)",      letterSpacing: "var(--p7-text-body-track)",      fontWeight: "500" }],
        "p7-callout":   ["var(--p7-text-callout)",   { lineHeight: "var(--p7-text-callout-lh)",   letterSpacing: "var(--p7-text-callout-track)",   fontWeight: "400" }],
        "p7-caption-1": ["var(--p7-text-caption-1)", { lineHeight: "var(--p7-text-caption-1-lh)", letterSpacing: "var(--p7-text-caption-1-track)", fontWeight: "400" }],
        "p7-caption-2": ["var(--p7-text-caption-2)", { lineHeight: "var(--p7-text-caption-2-lh)", letterSpacing: "var(--p7-text-caption-2-track)", fontWeight: "500" }],

        /* Slice-A — fluid typography scale.
           clamp(min, preferred, max) where the preferred grows with viewport
           width via `cqi`-equivalent `vi`. Lower bound holds steady at
           320 px (foldable narrow); upper bound stops at the 430 px
           iPhone-Pro-Max class. Use these on UI surfaces that need to
           shrink gracefully on iPhone-mini without losing legibility on
           large phones. Not a replacement for the `p7-*` tier — that
           remains the design-system tier. */
        "fluid-xs":   ["clamp(0.6875rem, 0.62rem + 0.34vw, 0.8125rem)",   { lineHeight: "1.35", letterSpacing: "0.005em" }],
        "fluid-sm":   ["clamp(0.75rem,   0.69rem + 0.34vw, 0.875rem)",    { lineHeight: "1.4",  letterSpacing: "0.003em" }],
        "fluid-base": ["clamp(0.875rem,  0.81rem + 0.34vw, 1rem)",        { lineHeight: "1.5",  letterSpacing: "0" }],
        "fluid-lg":   ["clamp(1rem,      0.91rem + 0.45vw, 1.125rem)",    { lineHeight: "1.45", letterSpacing: "-0.005em" }],
        "fluid-xl":   ["clamp(1.125rem,  1rem + 0.6vw, 1.375rem)",        { lineHeight: "1.35", letterSpacing: "-0.01em",  fontWeight: "600" }],
        "fluid-2xl":  ["clamp(1.375rem,  1.16rem + 1.05vw, 1.875rem)",    { lineHeight: "1.2",  letterSpacing: "-0.015em", fontWeight: "600" }],
      },
      transitionTimingFunction: {
        /* Phase 7 — non-spring eases */
        "p7-standard": "var(--p7-ease-standard)",
        "p7-emphasized": "var(--p7-ease-emphasized)",
        "p7-decelerated": "var(--p7-ease-decelerated)",
        "p7-accelerated": "var(--p7-ease-accelerated)",
      },
      transitionDuration: {
        /* Phase 7 — duration tokens for `transition-duration` utilities */
        "p7-tap": "120ms",
        "p7-pop": "200ms",
        "p7-page": "320ms",
        "p7-hero": "520ms",
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        xl: "calc(var(--radius) + 4px)",
        "2xl": "calc(var(--radius) + 8px)",
        "3xl": "1.5rem",
        /* Phase 7 — semantic radii */
        "p7-chip": "var(--p7-radius-chip)",
        "p7-input": "var(--p7-radius-input)",
        "p7-surface": "var(--p7-radius-surface)",
        "p7-sheet": "var(--p7-radius-sheet)",
      },
      boxShadow: {
        "glow-sm": "0 0 12px hsl(var(--primary) / 0.15)",
        "glow-md": "0 0 20px hsl(var(--primary) / 0.2), 0 0 40px hsl(var(--primary) / 0.1)",
        "glow-lg": "0 0 30px hsl(var(--primary) / 0.25), 0 0 60px hsl(var(--primary) / 0.15)",
        "glow-indigo": "0 0 20px hsl(var(--primary) / 0.2), 0 0 40px hsl(var(--primary) / 0.1)",
        "depth-sm": "var(--shadow-sm)",
        "depth-md": "var(--shadow-md)",
        "depth-lg": "var(--shadow-lg)",
        "depth-xl": "var(--shadow-xl)",
        /* Phase 7 — 4-tier elevation (sm/md/lg/overlay) with theme-aware shadow tint */
        "p7-sm": "var(--p7-shadow-sm)",
        "p7-md": "var(--p7-shadow-md)",
        "p7-lg": "var(--p7-shadow-lg)",
        "p7-overlay": "var(--p7-shadow-overlay)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "fade-out": {
          "0%": { opacity: "1", transform: "translateY(0)" },
          "100%": { opacity: "0", transform: "translateY(10px)" },
        },
        "scale-in": {
          "0%": { opacity: "0", transform: "scale(0.95)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
        "slide-up": {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "slide-down": {
          "0%": { opacity: "0", transform: "translateY(-20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "glow-pulse": {
          "0%, 100%": { opacity: "0.4", transform: "scale(1)" },
          "50%": { opacity: "1", transform: "scale(1.08)" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        "orb-drift": {
          "0%": { transform: "translate(0, 0) scale(1)" },
          "25%": { transform: "translate(40px, -30px) scale(1.1)" },
          "50%": { transform: "translate(-20px, 20px) scale(0.95)" },
          "75%": { transform: "translate(30px, 10px) scale(1.05)" },
          "100%": { transform: "translate(0, 0) scale(1)" },
        },
        "score-fill": {
          "0%": { strokeDashoffset: "283" },
          "100%": { strokeDashoffset: "var(--score-offset)" },
        },
        shimmer: {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(100%)" },
        },
        "qr-pulse": {
          "0%, 100%": { transform: "scale(1)", opacity: "1" },
          "50%": { transform: "scale(1.02)", opacity: "0.95" },
        },
        "card-lift": {
          "0%": { transform: "translateY(0)", boxShadow: "var(--shadow-sm)" },
          "100%": { transform: "translateY(-2px)", boxShadow: "var(--shadow-lg)" },
        },
        "pulse-subtle": {
          "0%, 100%": { opacity: "0.6" },
          "50%": { opacity: "1" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in var(--motion-small, 180ms) var(--ease-cinematic, cubic-bezier(0.16,1,0.3,1)) forwards",
        "fade-out": "fade-out var(--motion-small, 180ms) var(--ease-out-expo) forwards",
        "scale-in": "scale-in var(--motion-small, 180ms) var(--ease-cinematic) forwards",
        "slide-up": "slide-up var(--motion-medium, 260ms) var(--ease-cinematic) forwards",
        "slide-down": "slide-down var(--motion-medium, 260ms) var(--ease-cinematic) forwards",
        "glow-pulse": "glow-pulse 2.5s ease-in-out infinite",
        float: "float 5s ease-in-out infinite",
        "orb-drift": "orb-drift 20s ease-in-out infinite",
        "score-fill": "score-fill var(--motion-long, 380ms) var(--ease-out-expo) forwards",
        shimmer: "shimmer 2.5s linear infinite",
        "qr-pulse": "qr-pulse 1400ms var(--ease-out-expo) infinite",
        "card-lift": "card-lift var(--motion-small, 180ms) var(--ease-out-expo) forwards",
        "pulse-subtle": "pulse-subtle 3s ease-in-out infinite",
      },
    },
  },
  plugins: [animate],
} satisfies Config;
