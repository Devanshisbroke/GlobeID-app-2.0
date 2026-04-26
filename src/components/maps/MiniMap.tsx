import * as React from "react";
import { motion } from "motion/react";
import { ease } from "@/lib/motion-tokens";
import { cn } from "@/lib/utils";

/**
 * MiniMap — Phase 7 PR-γ.
 *
 * A zero-dependency wireframe 2D world map for use in non-Map surfaces:
 *  - Wallet: "currently in" badge with a single dot at the user's lat/lng.
 *  - Identity: passport-stamp scatter — every visited country as a dot.
 *  - Travel: per-trip route thumbnail with origin → destination arc.
 *
 * Why not `react-simple-maps` + `world-atlas` topojson?
 *   That stack adds ~50 KB gz of vendor code + a 100 KB topojson asset for
 *   what amounts to a low-rez landmass silhouette. We can produce the same
 *   visual signal — "this is a world map and X is *here*" — with a
 *   wireframe lat/long grid and an equirectangular projection of marker
 *   coordinates in ~3 KB of code. Aesthetically it's also more on-brand
 *   with the splash globe and the cinematic / wireframe direction of
 *   Phase 7.
 *
 * Coordinate model:
 *   - Equirectangular projection: lon ∈ [-180, 180] → x ∈ [0, w],
 *     lat ∈ [-90, 90] → y ∈ [h, 0] (north-up).
 *   - All marker coords are passed as plain `{ lat, lng }` so callers don't
 *     need to know about the projection.
 *   - Routes are rendered as quadratic Béziers with the control point lifted
 *     above the midpoint so they read as "great circle"-style arcs in 2D.
 *     This is not geographically accurate; it's an aesthetic choice.
 *
 * All visual styling consumes `--p7-*` tokens via Tailwind utilities; the
 * map looks correct in both Atmosphere (dark) and Paper (light).
 */

export type LatLng = { lat: number; lng: number };

export type MiniMapMarker = LatLng & {
  /** Optional unique key. Falls back to lat,lng. */
  id?: string;
  /** Tone — defaults to brand. */
  tone?: "brand" | "accent" | "warning" | "critical";
  /** Override marker radius in viewBox units. */
  size?: number;
  /** Visible label rendered next to the marker. */
  label?: string;
};

export type MiniMapRoute = {
  id?: string;
  from: LatLng;
  to: LatLng;
  /** Tone — defaults to brand. */
  tone?: "brand" | "accent";
  /** Whether to render the arc with a dashed stroke (e.g. "planned"). */
  dashed?: boolean;
};

interface MiniMapProps {
  markers?: MiniMapMarker[];
  routes?: MiniMapRoute[];
  /** Aspect-ratio class name. Defaults to 2:1 (true equirectangular). */
  className?: string;
  /** Whether to draw the latitude / longitude grid. Defaults to true. */
  showGraticule?: boolean;
  /** Density of the lat/long grid. Defaults to 30°. */
  graticuleStep?: 15 | 30 | 45;
  /** Whether to animate the wireframe and markers in. Defaults to true. */
  animate?: boolean;
  /** ARIA label for the map region. */
  ariaLabel?: string;
}

const VB_W = 360;
const VB_H = 180; // 2:1 equirectangular

const TONE_TO_COLOR = {
  brand: "hsl(var(--p7-brand))",
  accent: "hsl(var(--p7-accent))",
  warning: "hsl(var(--p7-warning))",
  critical: "hsl(var(--p7-critical))",
} as const;

const project = ({ lat, lng }: LatLng): { x: number; y: number } => {
  const x = ((lng + 180) / 360) * VB_W;
  const y = ((90 - lat) / 180) * VB_H;
  return { x, y };
};

const MiniMap: React.FC<MiniMapProps> = ({
  markers = [],
  routes = [],
  className,
  showGraticule = true,
  graticuleStep = 30,
  animate = true,
  ariaLabel = "World map",
}) => {
  // Reduced-motion users get the static frame, no draw-on animation.
  const reducedMotion = useReducedMotion();
  const shouldAnimate = animate && !reducedMotion;

  // Latitudes / longitudes for the wireframe graticule.
  const lats = React.useMemo(() => {
    const out: number[] = [];
    for (let lat = -90 + graticuleStep; lat < 90; lat += graticuleStep) {
      out.push(lat);
    }
    return out;
  }, [graticuleStep]);

  const lngs = React.useMemo(() => {
    const out: number[] = [];
    for (let lng = -180 + graticuleStep; lng < 180; lng += graticuleStep) {
      out.push(lng);
    }
    return out;
  }, [graticuleStep]);

  return (
    <div
      role="img"
      aria-label={ariaLabel}
      className={cn(
        "relative w-full overflow-hidden rounded-p7-input",
        "bg-surface-overlay border border-surface-hairline",
        className,
      )}
    >
      <svg
        viewBox={`0 0 ${VB_W} ${VB_H}`}
        className="w-full h-auto block"
        preserveAspectRatio="xMidYMid meet"
      >
        {/* Outer hairline frame */}
        <rect
          x={0}
          y={0}
          width={VB_W}
          height={VB_H}
          fill="hsl(var(--p7-surface-overlay))"
        />

        {/* Graticule */}
        {showGraticule ? (
          <g
            stroke="hsl(var(--p7-ink-tertiary) / 0.32)"
            strokeWidth={0.4}
            fill="none"
          >
            {lats.map((lat) => {
              const { y } = project({ lat, lng: 0 });
              return (
                <motion.line
                  key={`lat-${lat}`}
                  x1={0}
                  x2={VB_W}
                  y1={y}
                  y2={y}
                  strokeDasharray={lat === 0 ? "0" : "2 2"}
                  initial={
                    shouldAnimate ? { pathLength: 0, opacity: 0 } : undefined
                  }
                  animate={
                    shouldAnimate
                      ? { pathLength: 1, opacity: 1 }
                      : undefined
                  }
                  transition={
                    shouldAnimate
                      ? {
                          duration: 0.4,
                          delay: 0.05 * Math.abs(lat) / graticuleStep,
                          ease: ease.standard,
                        }
                      : undefined
                  }
                />
              );
            })}
            {lngs.map((lng) => {
              const { x } = project({ lat: 0, lng });
              return (
                <motion.line
                  key={`lng-${lng}`}
                  x1={x}
                  x2={x}
                  y1={0}
                  y2={VB_H}
                  strokeDasharray={lng === 0 ? "0" : "2 2"}
                  initial={
                    shouldAnimate ? { pathLength: 0, opacity: 0 } : undefined
                  }
                  animate={
                    shouldAnimate
                      ? { pathLength: 1, opacity: 1 }
                      : undefined
                  }
                  transition={
                    shouldAnimate
                      ? {
                          duration: 0.4,
                          delay: 0.05 * Math.abs(lng) / graticuleStep,
                          ease: ease.standard,
                        }
                      : undefined
                  }
                />
              );
            })}
            {/* Equator + Prime Meridian rendered solid for orientation. */}
            <line
              x1={0}
              x2={VB_W}
              y1={VB_H / 2}
              y2={VB_H / 2}
              stroke="hsl(var(--p7-ink-tertiary) / 0.5)"
              strokeWidth={0.5}
            />
            <line
              x1={VB_W / 2}
              x2={VB_W / 2}
              y1={0}
              y2={VB_H}
              stroke="hsl(var(--p7-ink-tertiary) / 0.5)"
              strokeWidth={0.5}
            />
          </g>
        ) : null}

        {/* Routes — rendered before markers so dots sit on top. */}
        {routes.map((route, idx) => {
          const a = project(route.from);
          const b = project(route.to);
          // Quadratic control point lifted above the midpoint by ~25% of the
          // chord length, capped to avoid crashing the top edge.
          const midX = (a.x + b.x) / 2;
          const midY = (a.y + b.y) / 2;
          const chord = Math.hypot(b.x - a.x, b.y - a.y);
          const lift = Math.min(VB_H * 0.35, chord * 0.25);
          const cy = Math.max(2, midY - lift);
          const color = TONE_TO_COLOR[route.tone ?? "brand"];
          const key = route.id ?? `route-${idx}`;
          return (
            <motion.path
              key={key}
              d={`M ${a.x} ${a.y} Q ${midX} ${cy} ${b.x} ${b.y}`}
              fill="none"
              stroke={color}
              strokeWidth={1.2}
              strokeLinecap="round"
              strokeDasharray={route.dashed ? "3 3" : undefined}
              initial={
                shouldAnimate ? { pathLength: 0, opacity: 0 } : undefined
              }
              animate={
                shouldAnimate
                  ? { pathLength: 1, opacity: 1 }
                  : undefined
              }
              transition={
                shouldAnimate
                  ? { duration: 0.55, delay: 0.4, ease: ease.accelerated }
                  : undefined
              }
            />
          );
        })}

        {/* Markers */}
        {markers.map((marker, idx) => {
          const { x, y } = project(marker);
          const color = TONE_TO_COLOR[marker.tone ?? "brand"];
          const r = marker.size ?? 2.5;
          const key = marker.id ?? `marker-${marker.lat},${marker.lng}-${idx}`;
          return (
            <motion.g
              key={key}
              initial={shouldAnimate ? { opacity: 0, scale: 0 } : undefined}
              animate={
                shouldAnimate ? { opacity: 1, scale: 1 } : undefined
              }
              transition={
                shouldAnimate
                  ? {
                      type: "spring",
                      stiffness: 320,
                      damping: 18,
                      delay: 0.55 + idx * 0.04,
                    }
                  : undefined
              }
              style={{ transformOrigin: `${x}px ${y}px` }}
            >
              {/* Halo glow */}
              <circle
                cx={x}
                cy={y}
                r={r * 2.4}
                fill={color}
                opacity={0.18}
              />
              <circle cx={x} cy={y} r={r} fill={color} />
              {marker.label ? (
                <text
                  x={x + r + 3}
                  y={y + r}
                  fontSize={6}
                  fontWeight={500}
                  fill="hsl(var(--p7-ink-secondary))"
                >
                  {marker.label}
                </text>
              ) : null}
            </motion.g>
          );
        })}
      </svg>
    </div>
  );
};

/* ──────────────────── Helpers ──────────────────── */

function useReducedMotion(): boolean {
  const [reduced, setReduced] = React.useState<boolean>(() => {
    if (typeof window === "undefined") return false;
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  });
  React.useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);
  return reduced;
}

export default MiniMap;
