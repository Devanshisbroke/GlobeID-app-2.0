import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { flightRoutes, getAirport, latLngToVector3, createArcPoints, type FlightRoute } from "@/lib/airports";

interface FlightArcsProps {
  showHistory: boolean;
}

const arcColors: Record<FlightRoute["type"], string> = {
  upcoming: "hsl(258, 65%, 65%)",
  current: "hsl(168, 70%, 55%)",
  past: "hsl(200, 90%, 55%)",
};

const FlightArc: React.FC<{ route: FlightRoute; radius: number }> = ({ route, radius }) => {
  const lineRef = useRef<THREE.Line>(null);
  const planeRef = useRef<THREE.Mesh>(null);
  const progressRef = useRef(0);

  const fromAirport = getAirport(route.from);
  const toAirport = getAirport(route.to);

  const { curve, color } = useMemo(() => {
    if (!fromAirport || !toAirport) return { curve: null, color: new THREE.Color("white") };

    const from3D = latLngToVector3(fromAirport.lat, fromAirport.lng, radius);
    const to3D = latLngToVector3(toAirport.lat, toAirport.lng, radius);
    const arcPts = createArcPoints(from3D, to3D, 80, 0.25);
    const vectors = arcPts.map(p => new THREE.Vector3(...p));
    const c = new THREE.CatmullRomCurve3(vectors);
    return { curve: c, color: new THREE.Color(arcColors[route.type]) };
  }, [fromAirport, toAirport, radius, route.type]);

  useFrame((_, delta) => {
    if (!curve || !lineRef.current) return;

    // Animate dash offset for all routes
    const mat = lineRef.current.material as any;
    if (mat.dashOffset !== undefined) mat.dashOffset -= delta * 0.3;

    // Animate plane along upcoming routes
    if (planeRef.current && (route.type === "upcoming" || route.type === "current")) {
      progressRef.current = (progressRef.current + delta * 0.08) % 1;
      const pos = curve.getPoint(progressRef.current);
      const ahead = curve.getPoint(Math.min(progressRef.current + 0.02, 1));
      planeRef.current.position.copy(pos);
      planeRef.current.lookAt(ahead);
    }
  });

  if (!curve) return null;

  const points = curve.getPoints(80);

  return (
    <group>
      {/* Glow line (wider, more transparent) */}
      <line ref={lineRef as any}>
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            count={points.length}
            array={new Float32Array(points.flatMap(p => [p.x, p.y, p.z]))}
            itemSize={3}
          />
        </bufferGeometry>
        <lineDashedMaterial
          color={color}
          dashSize={0.04}
          gapSize={0.02}
          transparent
          opacity={route.type === "upcoming" ? 0.9 : 0.45}
          linewidth={1}
        />
      </line>

      {/* Aircraft indicator for upcoming/current */}
      {(route.type === "upcoming" || route.type === "current") && (
        <mesh ref={planeRef}>
          <coneGeometry args={[0.015, 0.04, 4]} />
          <meshBasicMaterial color={color} transparent opacity={0.95} />
        </mesh>
      )}
    </group>
  );
};

const FlightArcs: React.FC<FlightArcsProps> = ({ showHistory }) => {
  const routes = showHistory
    ? flightRoutes
    : flightRoutes.filter(r => r.type === "upcoming" || r.type === "current");

  return (
    <group>
      {routes.map(route => (
        <FlightArc key={route.id} route={route} radius={1} />
      ))}
    </group>
  );
};

export default FlightArcs;
