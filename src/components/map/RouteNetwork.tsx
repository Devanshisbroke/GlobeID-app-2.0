import React, { useMemo } from "react";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

/** Renders routes between all major hubs */
const RouteNetwork: React.FC = () => {
  const hubs = useMemo(() => getHubs(), []);

  const lines = useMemo(() => {
    const result: { geometry: THREE.BufferGeometry; intensity: number }[] = [];
    const hubAirports = hubs.map((h) => airports.find((a) => a.iata === h.iata)).filter(Boolean);

    for (let i = 0; i < hubAirports.length; i++) {
      for (let j = i + 1; j < hubAirports.length; j++) {
        const a = hubAirports[i]!;
        const b = hubAirports[j]!;
        const from = latLngToVector3(a.lat, a.lng, GLOBE_RADIUS);
        const to = latLngToVector3(b.lat, b.lng, GLOBE_RADIUS);
        const points = createArcPoints(from, to, 32, 0.12);
        const geometry = new THREE.BufferGeometry().setFromPoints(points.map((p) => new THREE.Vector3(...p)));
        result.push({ geometry, intensity: 0.5 + Math.random() * 0.5 });
      }
    }
    return result;
  }, [hubs]);

  return (
    <group>
      {lines.map((line, i) => (
        <line key={i} geometry={line.geometry}>
          <lineBasicMaterial color="#3fa9ff" transparent opacity={0.06 + line.intensity * 0.04} linewidth={1} />
        </line>
      ))}
    </group>
  );
};

export default RouteNetwork;
