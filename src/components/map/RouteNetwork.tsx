import React, { useMemo } from "react";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

const RouteNetwork: React.FC = () => {
  const hubs = useMemo(() => getHubs(), []);

  const lines = useMemo(() => {
    const result: THREE.Line[] = [];
    const hubAirports = hubs.map((h) => airports.find((a) => a.iata === h.iata)).filter(Boolean);

    for (let i = 0; i < hubAirports.length; i++) {
      for (let j = i + 1; j < hubAirports.length; j++) {
        const a = hubAirports[i]!;
        const b = hubAirports[j]!;
        const from = latLngToVector3(a.lat, a.lng, GLOBE_RADIUS);
        const to = latLngToVector3(b.lat, b.lng, GLOBE_RADIUS);
        const points = createArcPoints(from, to, 32, 0.12);
        const geometry = new THREE.BufferGeometry().setFromPoints(points.map((p) => new THREE.Vector3(...p)));
        const intensity = 0.5 + Math.random() * 0.5;
        const material = new THREE.LineBasicMaterial({ color: "#3fa9ff", transparent: true, opacity: 0.06 + intensity * 0.04 });
        result.push(new THREE.Line(geometry, material));
      }
    }
    return result;
  }, [hubs]);

  return (
    <group>
      {lines.map((line, i) => (
        <primitive key={i} object={line} />
      ))}
    </group>
  );
};

export default RouteNetwork;
