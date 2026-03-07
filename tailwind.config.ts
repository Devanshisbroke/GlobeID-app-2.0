import type { Config } from "tailwindcss";

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
        neon: {
          indigo: "hsl(var(--neon-indigo))",
          cyan: "hsl(var(--neon-cyan))",
          teal: "hsl(var(--neon-teal))",
          magenta: "hsl(var(--neon-magenta))",
          amber: "hsl(var(--neon-amber))",
        },
        glass: {
          DEFAULT: "hsl(var(--glass-bg))",
          border: "hsl(var(--glass-border))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        xl: "calc(var(--radius) + 4px)",
        "2xl": "calc(var(--radius) + 8px)",
        "3xl": "1.5rem",
      },
      boxShadow: {
        "glow-sm": "0 0 12px hsl(var(--neon-cyan) / 0.15)",
        "glow-md": "0 0 20px hsl(var(--neon-cyan) / 0.2), 0 0 40px hsl(var(--neon-cyan) / 0.1)",
        "glow-lg": "0 0 30px hsl(var(--neon-cyan) / 0.25), 0 0 60px hsl(var(--neon-cyan) / 0.15)",
        "glow-indigo": "0 0 20px hsl(var(--neon-indigo) / 0.2), 0 0 40px hsl(var(--neon-indigo) / 0.1)",
        "depth-sm": "var(--shadow-sm)",
        "depth-md": "var(--shadow-md)",
        "depth-lg": "var(--shadow-lg)",
        "depth-xl": "var(--shadow-xl)",
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
        "fade-in": "fade-in var(--motion-small, 250ms) var(--ease-cinematic, cubic-bezier(0.16,1,0.3,1)) forwards",
        "fade-out": "fade-out var(--motion-small, 250ms) var(--ease-out-expo) forwards",
        "scale-in": "scale-in var(--motion-small, 250ms) var(--ease-cinematic) forwards",
        "slide-up": "slide-up var(--motion-medium, 400ms) var(--ease-cinematic) forwards",
        "slide-down": "slide-down var(--motion-medium, 400ms) var(--ease-cinematic) forwards",
        "glow-pulse": "glow-pulse 2.5s ease-in-out infinite",
        float: "float 5s ease-in-out infinite",
        "orb-drift": "orb-drift 20s ease-in-out infinite",
        "score-fill": "score-fill var(--motion-long, 800ms) var(--ease-out-expo) forwards",
        shimmer: "shimmer 2.5s linear infinite",
        "qr-pulse": "qr-pulse 1400ms var(--ease-out-expo) infinite",
        "card-lift": "card-lift var(--motion-small, 250ms) var(--ease-out-expo) forwards",
        "pulse-subtle": "pulse-subtle 3s ease-in-out infinite",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
