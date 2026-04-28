import * as React from "react";
import { motion, AnimatePresence } from "motion/react";
import { ease, duration, spring } from "@/lib/motion-tokens";

/**
 * Splash v2 — Phase 7 PR-γ.
 *
 * Choreography (Phase 9-α: compressed by ~35% from the Phase-7 1.40 s timeline,
 * locked at ≤1.0 s while preserving the same four-beat rhythm):
 *   1. 0.00–0.30s — Wireframe globe draws on. The 5 latitude ellipses + 5
 *      longitude meridians stroke in (path-length animation), giving the
 *      sense of a wireframe spinning into existence rather than fading in.
 *   2. 0.20–0.55s — Three brand arcs (sapphire / sapphire-deep / mint) trace
 *      across the surface of the globe, like aircraft routes. Each arc is a
 *      stroke-dashoffset animation on a quadratic curve.
 *   3. 0.45–0.70s — Wordmark "GlobeID" + tagline resolve in from below with
 *      a soft spring. The dot of the "i" in GlobeID is a brand sapphire
 *      pulse to pick up the arc accent.
 *   4. 0.70–0.90s — Whole layer fades to fully transparent and unmounts.
 *
 * Total duration: 0.90 s exactly. Hydration calls in App.tsx run in parallel
 * during the splash (see `hydrateAll()` — queryClient + userStore + alerts +
 * insights + recommendations + tripPlanner + copilot all kick off on mount,
 * not at splash dismiss), so this number is wall-clock, not blocking I/O.
 *
 * Theme: this splash is rendered against the OLED-near-black `--p7-surface-base`
 * regardless of the persisted user theme. A splash that flashes warm-paper
 * white on a cold morning is jarring; a one-second neutral-dark frame buys
 * us time to read the saved theme without an FOUC. App.tsx applies the
 * persisted theme inside the same `useEffect` where it dismisses the splash.
 */

interface SplashProps {
  onComplete: () => void;
}

const TOTAL_MS = 900;
const FADE_MS = 200;

const SplashV2: React.FC<SplashProps> = ({ onComplete }) => {
  const [visible, setVisible] = React.useState(true);

  React.useEffect(() => {
    // Hand control back to the app at the *start* of the fade-out so the
    // app can mount under us during the fade. AnimatePresence handles the
    // unmount on `exit`.
    const t = window.setTimeout(() => {
      setVisible(false);
    }, TOTAL_MS - FADE_MS);
    return () => window.clearTimeout(t);
  }, []);

  return (
    <AnimatePresence onExitComplete={onComplete}>
      {visible ? (
        <motion.div
          key="p7-splash"
          className="fixed inset-0 z-[100] flex flex-col items-center justify-center overflow-hidden"
          style={{
            // OLED-near-black regardless of light/dark — see component doc.
            background:
              "radial-gradient(120% 80% at 50% 40%, hsl(228 16% 9%) 0%, hsl(228 22% 5%) 60%, hsl(228 30% 3%) 100%)",
          }}
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: FADE_MS / 1000, ease: ease.standard }}
        >
          <SplashGlobe />
          <Wordmark />
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
};

/* ──────────────────── Globe ──────────────────── */

/**
 * Wireframe globe with three accent arcs traced across it.
 *
 * The globe is 5 horizontal ellipses (latitudes) + 5 vertical ellipses
 * (longitudes). Each is a `motion.path` whose `pathLength` animates from 0
 * to 1, so the wireframe draws on rather than fades in. Anchoring at the
 * north and south poles is implicit because all longitudes meet there.
 *
 * Three accent arcs are quadratic Bézier curves with stroke-dasharray
 * animations so they trace across the globe like aircraft contrails.
 */
const SplashGlobe: React.FC = () => {
  // Latitude rings — every 30° of latitude.
  const lats = [-60, -30, 0, 30, 60];
  // Longitude meridians — every 36° of longitude (5 visible meridians).
  const lons = [0, 36, 72, 108, 144];

  return (
    <svg
      viewBox="-160 -160 320 320"
      width="200"
      height="200"
      className="mb-7"
      style={{
        filter: "drop-shadow(0 0 24px hsl(214 78% 56% / 0.32))",
      }}
      aria-hidden
    >
      {/* Soft inner sphere — gives the wireframe something to sit on so the
          arcs read as following a 3D surface rather than floating on flat. */}
      <motion.circle
        cx={0}
        cy={0}
        r={120}
        fill="url(#p7-splash-sphere)"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.22, ease: ease.standard }}
      />

      {/* Equator ring — drawn first as a visual anchor. */}
      <motion.ellipse
        cx={0}
        cy={0}
        rx={120}
        ry={120}
        fill="none"
        stroke="hsl(214 80% 64% / 0.36)"
        strokeWidth={1}
        initial={{ pathLength: 0, opacity: 0 }}
        animate={{ pathLength: 1, opacity: 1 }}
        transition={{ duration: 0.36, ease: ease.standard }}
      />

      {/* Latitude rings */}
      {lats.map((lat, i) => {
        // Each latitude is an ellipse whose ry shrinks as it moves toward poles.
        const rad = (lat * Math.PI) / 180;
        const ry = 120 * Math.cos(rad) * 0.18; // visual squash for "globe seen from front"
        const cy = 120 * Math.sin(rad);
        return (
          <motion.ellipse
            key={`lat-${lat}`}
            cx={0}
            cy={cy}
            rx={120 * Math.cos(rad)}
            ry={Math.abs(ry)}
            fill="none"
            stroke="hsl(214 70% 60% / 0.22)"
            strokeWidth={0.8}
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 1 }}
            transition={{
              duration: 0.30,
              delay: 0.08 + i * 0.025,
              ease: ease.standard,
            }}
          />
        );
      })}

      {/* Longitude meridians */}
      {lons.map((lon, i) => {
        // Each meridian is an ellipse rotated by lon degrees.
        const rx = 120 * Math.cos((lon * Math.PI) / 180) * 0.6;
        return (
          <motion.ellipse
            key={`lon-${lon}`}
            cx={0}
            cy={0}
            rx={Math.abs(rx) || 1}
            ry={120}
            fill="none"
            stroke="hsl(214 70% 60% / 0.22)"
            strokeWidth={0.8}
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 1 }}
            transition={{
              duration: 0.30,
              delay: 0.12 + i * 0.025,
              ease: ease.standard,
            }}
          />
        );
      })}

      {/* Brand arcs — three traced contrails across the globe. */}
      {[
        // sapphire — top-left to mid-right
        {
          d: "M -90 -70 Q 0 -130, 95 -20",
          color: "hsl(214 88% 64%)",
          width: 2.0,
          delay: 0.32,
          dur: 0.36,
        },
        // sapphire-deep — bottom-left arc
        {
          d: "M -100 30 Q -10 80, 80 60",
          color: "hsl(222 80% 55%)",
          width: 1.8,
          delay: 0.40,
          dur: 0.32,
        },
        // mint — vertical-ish accent
        {
          d: "M 30 -100 Q 70 0, 20 95",
          color: "hsl(168 76% 56%)",
          width: 1.6,
          delay: 0.48,
          dur: 0.30,
        },
      ].map((arc, i) => (
        <motion.path
          key={`arc-${i}`}
          d={arc.d}
          fill="none"
          stroke={arc.color}
          strokeWidth={arc.width}
          strokeLinecap="round"
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: 1, opacity: 1 }}
          transition={{
            duration: arc.dur,
            delay: arc.delay,
            ease: ease.accelerated,
          }}
          style={{
            filter: `drop-shadow(0 0 6px ${arc.color})`,
          }}
        />
      ))}

      {/* Three city dots at the arc endpoints — reads as "connections". */}
      {[
        { cx: -90, cy: -70, color: "hsl(214 88% 64%)", delay: 0.62 },
        { cx: 95, cy: -20, color: "hsl(214 88% 64%)", delay: 0.65 },
        { cx: 80, cy: 60, color: "hsl(168 76% 56%)", delay: 0.68 },
      ].map((d, i) => (
        <motion.circle
          key={`dot-${i}`}
          cx={d.cx}
          cy={d.cy}
          r={3}
          fill={d.color}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ ...spring.snap, delay: d.delay }}
          style={{ filter: `drop-shadow(0 0 6px ${d.color})` }}
        />
      ))}

      <defs>
        <radialGradient id="p7-splash-sphere" cx="40%" cy="35%" r="65%">
          <stop offset="0%" stopColor="hsl(214 60% 22% / 0.85)" />
          <stop offset="65%" stopColor="hsl(228 35% 8% / 0.65)" />
          <stop offset="100%" stopColor="hsl(228 40% 3% / 0)" />
        </radialGradient>
      </defs>
    </svg>
  );
};

/* ──────────────────── Wordmark ──────────────────── */

const Wordmark: React.FC = () => {
  return (
    <motion.div
      className="text-center"
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.26, delay: 0.45, ease: ease.standard }}
    >
      <div className="font-display text-[28px] leading-none tracking-tight text-white">
        Globe
        <span className="relative">
          ID
          {/* The dot of the "I" in ID — we stitch a brand-sapphire micro-dot
              onto the right serif of D so the wordmark picks up the same
              accent color as the globe arcs. Subtle but lets the eye complete
              the visual handoff between symbol and wordmark. */}
          <motion.span
            className="absolute -top-0.5 -right-1.5 h-1.5 w-1.5 rounded-full"
            style={{
              background: "hsl(214 88% 64%)",
              boxShadow: "0 0 8px hsl(214 88% 64% / 0.8)",
            }}
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ ...spring.snap, delay: 0.62 }}
          />
        </span>
      </div>
      <motion.p
        className="mt-2 text-[11px] uppercase tracking-[0.22em] text-white/50"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.28, delay: 0.58, ease: ease.standard }}
      >
        Identity for the borderless world
      </motion.p>
    </motion.div>
  );
};

// `duration` token is imported for parity with other v2 motion files even
// though this file uses literal seconds for the splash storyboard. Keeping
// the import flags any future drift if the token catalog changes.
void duration;

export default SplashV2;
