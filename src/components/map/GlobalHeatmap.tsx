import React, { useMemo } from "react";
import * as THREE from "three";
import { airports, latLngToVector3 } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

const GlobalHeatmap: React.FC = () => {
  const hubs = useMemo(() => getHubs(), []);

  return (
    <group>
      {hubs.map((hub) => {
        const airport = airports.find((a) => a.iata === hub.iata);
        if (!airport) return null;
        const pos = latLngToVector3(airport.lat, airport.lng, GLOBE_RADIUS + 0.01);
        const intensity = hub.popularity / 100;
        return (
          <pointLight
            key={hub.iata}
            position={pos}
            color={new THREE.Color().setHSL(0.55, 0.8, 0.6)}
            intensity={intensity * 0.3}
            distance={0.3}
          />
        );
      })}
    </group>
  );
};

export default GlobalHeatmap;
