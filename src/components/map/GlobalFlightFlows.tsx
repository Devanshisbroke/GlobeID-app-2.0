import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { generateGlobalRoutes } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

const GlobalFlightFlows: React.FC<{ count?: number }> = ({ count = 60 }) => {
  const groupRef = useRef<THREE.Group>(null);
  const progressRefs = useRef<number[]>([]);

  const routes = useMemo(() => {
    const generated = generateGlobalRoutes(count);
    progressRefs.current = generated.map(() => Math.random());
    return generated;
  }, [count]);

  const arcsData = useMemo(() => {
    return routes.map((r) => {
      const fromAirport = airports.find((a) => a.iata === r.from);
      const toAirport = airports.find((a) => a.iata === r.to);
      if (!fromAirport || !toAirport) return null;
      const from = latLngToVector3(fromAirport.lat, fromAirport.lng, GLOBE_RADIUS);
      const to = latLngToVector3(toAirport.lat, toAirport.lng, GLOBE_RADIUS);
      const points = createArcPoints(from, to, 48, 0.15 + r.traffic * 0.2);
      const geometry = new THREE.BufferGeometry().setFromPoints(points.map((p) => new THREE.Vector3(...p)));
      return { geometry, traffic: r.traffic };
    }).filter(Boolean) as { geometry: THREE.BufferGeometry; traffic: number }[];
  }, [routes]);

  useFrame((_, delta) => {
    if (!groupRef.current) return;
    groupRef.current.children.forEach((child, i) => {
      if (child instanceof THREE.Line) {
        const mat = child.material as THREE.LineBasicMaterial;
        progressRefs.current[i] = (progressRefs.current[i] + delta * 0.08) % 1;
        mat.opacity = 0.15 + Math.sin(progressRefs.current[i] * Math.PI) * 0.25;
      }
    });
  });

  return (
    <group ref={groupRef}>
      {arcsData.map((arc, i) => (
        <line key={i} geometry={arc.geometry}>
          <lineBasicMaterial
            color={new THREE.Color().setHSL(0.55 + arc.traffic * 0.1, 0.7, 0.6)}
            transparent
            opacity={0.2}
            linewidth={1}
          />
        </line>
      ))}
    </group>
  );
};

export default GlobalFlightFlows;
