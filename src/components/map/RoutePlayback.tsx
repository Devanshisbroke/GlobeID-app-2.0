import React, { useRef, useMemo, useState } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { generateGlobalRoutes } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1;

const RoutePlayback: React.FC<{ speed?: number; maxRoutes?: number }> = ({ speed = 1, maxRoutes = 40 }) => {
  const [visibleCount, setVisibleCount] = useState(0);
  const timerRef = useRef(0);

  const arcsData = useMemo(() => {
    const routes = generateGlobalRoutes(maxRoutes);
    return routes.map((r) => {
      const fromAirport = airports.find((a) => a.iata === r.from);
      const toAirport = airports.find((a) => a.iata === r.to);
      if (!fromAirport || !toAirport) return null;
      const from = latLngToVector3(fromAirport.lat, fromAirport.lng, GLOBE_RADIUS);
      const to = latLngToVector3(toAirport.lat, toAirport.lng, GLOBE_RADIUS);
      const points = createArcPoints(from, to, 32, 0.15);
      const geometry = new THREE.BufferGeometry().setFromPoints(points.map((p) => new THREE.Vector3(...p)));
      const material = new THREE.LineBasicMaterial({
        color: new THREE.Color().setHSL(0.58, 0.75, 0.55),
        transparent: true,
        opacity: 0.3,
      });
      return new THREE.Line(geometry, material);
    }).filter(Boolean) as THREE.Line[];
  }, [maxRoutes]);

  useFrame((_, delta) => {
    timerRef.current += delta * speed;
    const newCount = Math.min(Math.floor(timerRef.current * 3), arcsData.length);
    if (newCount !== visibleCount) setVisibleCount(newCount);
  });

  return (
    <group>
      {arcsData.slice(0, visibleCount).map((line, i) => (
        <primitive key={i} object={line} />
      ))}
    </group>
  );
};

export default RoutePlayback;
