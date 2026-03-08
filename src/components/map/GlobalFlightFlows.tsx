import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { generateGlobalRoutes } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

const FlowArc: React.FC<{ geometry: THREE.BufferGeometry; traffic: number; index: number }> = ({ geometry, traffic, index }) => {
  const lineRef = useRef<THREE.Line>(null);
  const progress = useRef(Math.random());

  useFrame((_, delta) => {
    if (!lineRef.current) return;
    progress.current = (progress.current + delta * 0.08) % 1;
    const mat = lineRef.current.material as THREE.LineBasicMaterial;
    mat.opacity = 0.15 + Math.sin(progress.current * Math.PI) * 0.25;
  });

  const mat = useMemo(() => new THREE.LineBasicMaterial({
    color: new THREE.Color().setHSL(0.55 + traffic * 0.1, 0.7, 0.6),
    transparent: true,
    opacity: 0.2,
  }), [traffic]);

  return <primitive ref={lineRef} object={new THREE.Line(geometry, mat)} />;
};

const GlobalFlightFlows: React.FC<{ count?: number }> = ({ count = 60 }) => {
  const arcsData = useMemo(() => {
    const routes = generateGlobalRoutes(count);
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
  }, [count]);

  return (
    <group>
      {arcsData.map((arc, i) => (
        <FlowArc key={i} geometry={arc.geometry} traffic={arc.traffic} index={i} />
      ))}
    </group>
  );
};

export default GlobalFlightFlows;
