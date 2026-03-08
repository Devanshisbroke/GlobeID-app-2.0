import React, { useMemo } from "react";
import { latLngToVector3 } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";
import { airports } from "@/lib/airports";

const GLOBE_R = 1;

/** Glowing point-lights at high-traffic regions */
const RegionalDensity: React.FC = () => {
  const hotspots = useMemo(() => {
    const hubs = getHubs();
    return hubs.map((h) => {
      const ap = airports.find((a) => a.iata === h.iata);
      if (!ap) return null;
      const pos = latLngToVector3(ap.lat, ap.lng, GLOBE_R + 0.04);
      return { pos, intensity: h.popularity / 100, iata: h.iata };
    }).filter(Boolean) as { pos: [number, number, number]; intensity: number; iata: string }[];
  }, []);

  return (
    <group>
      {hotspots.map((h) => (
        <pointLight
          key={h.iata}
          position={h.pos}
          color="#38bdf8"
          intensity={h.intensity * 0.6}
          distance={0.4 + h.intensity * 0.3}
          decay={2}
        />
      ))}
    </group>
  );
};

export default RegionalDensity;
