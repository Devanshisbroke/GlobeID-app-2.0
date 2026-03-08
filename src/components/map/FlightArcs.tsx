import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { flightRoutes, getAirport, latLngToVector3, createArcPoints, type FlightRoute } from "@/lib/airports";

interface FlightArcsProps {
  showHistory: boolean;
}

const arcColors: Record<FlightRoute["type"], THREE.Color> = {
  upcoming: new THREE.Color("hsl(258, 70%, 65%)"),
  current: new THREE.Color("hsl(168, 80%, 55%)"),
  past: new THREE.Color("hsl(200, 85%, 55%)"),
};

const arcGlowColors: Record<FlightRoute["type"], THREE.Color> = {
  upcoming: new THREE.Color("hsl(258, 80%, 75%)"),
  current: new THREE.Color("hsl(168, 90%, 65%)"),
  past: new THREE.Color("hsl(200, 90%, 65%)"),
};

const FlightArc: React.FC<{ route: FlightRoute; radius: number }> = ({ route, radius }) => {
  const glowLineRef = useRef<THREE.Line>(null);
  const coreLineRef = useRef<THREE.Line>(null);
  const planeRef = useRef<THREE.Group>(null);
  const trailRef = useRef<THREE.Mesh>(null);
  const progressRef = useRef(Math.random()); // randomize start

  const fromAirport = getAirport(route.from);
  const toAirport = getAirport(route.to);

  const { curve, color, glowColor } = useMemo(() => {
    if (!fromAirport || !toAirport) return { curve: null, color: arcColors.past, glowColor: arcGlowColors.past };

    const from3D = latLngToVector3(fromAirport.lat, fromAirport.lng, radius);
    const to3D = latLngToVector3(toAirport.lat, toAirport.lng, radius);
    const arcPts = createArcPoints(from3D, to3D, 100, 0.28);
    const vectors = arcPts.map(p => new THREE.Vector3(...p));
    const c = new THREE.CatmullRomCurve3(vectors);
    return { curve: c, color: arcColors[route.type], glowColor: arcGlowColors[route.type] };
  }, [fromAirport, toAirport, radius, route.type]);

  useFrame((_, delta) => {
    if (!curve) return;

    // Animate dash for core line
    if (coreLineRef.current) {
      const mat = coreLineRef.current.material as any;
      if (mat.dashOffset !== undefined) mat.dashOffset -= delta * 0.4;
    }

    // Animate plane + trail
    if (planeRef.current && (route.type === "upcoming" || route.type === "current")) {
      progressRef.current = (progressRef.current + delta * 0.06) % 1;
      const pos = curve.getPoint(progressRef.current);
      const ahead = curve.getPoint(Math.min(progressRef.current + 0.015, 1));
      planeRef.current.position.copy(pos);
      planeRef.current.lookAt(ahead);

      // Trail glow follows slightly behind
      if (trailRef.current) {
        const trailPos = curve.getPoint(Math.max(progressRef.current - 0.02, 0));
        trailRef.current.position.copy(trailPos);
      }
    }
  });

  if (!curve) return null;

  const points = curve.getPoints(100);
  const posArray = new Float32Array(points.flatMap(p => [p.x, p.y, p.z]));

  const isActive = route.type === "upcoming" || route.type === "current";

  return (
    <group>
      {/* Outer glow line */}
      <line ref={glowLineRef as any}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArray.slice()} itemSize={3} />
        </bufferGeometry>
        <lineBasicMaterial
          color={glowColor}
          transparent
          opacity={isActive ? 0.25 : 0.08}
          linewidth={1}
          depthWrite={false}
        />
      </line>

      {/* Core dashed line */}
      <line ref={coreLineRef as any}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArray.slice()} itemSize={3} />
        </bufferGeometry>
        <lineDashedMaterial
          color={color}
          dashSize={isActive ? 0.03 : 0.025}
          gapSize={isActive ? 0.015 : 0.02}
          transparent
          opacity={isActive ? 0.95 : 0.4}
          linewidth={1}
        />
      </line>

      {/* Endpoint markers */}
      {isActive && fromAirport && toAirport && (
        <>
          {[fromAirport, toAirport].map((apt, idx) => {
            const [ex, ey, ez] = latLngToVector3(apt.lat, apt.lng, radius + 0.003);
            return (
              <mesh key={idx} position={[ex, ey, ez]}>
                <sphereGeometry args={[0.008, 10, 10]} />
                <meshBasicMaterial color={idx === 0 ? color : glowColor} toneMapped={false} />
              </mesh>
            );
          })}
        </>
      )}

      {/* Aircraft + trailing glow for active routes */}
      {isActive && (
        <>
          <group ref={planeRef}>
            {/* Plane body */}
            <mesh rotation={[Math.PI / 2, 0, 0]}>
              <coneGeometry args={[0.008, 0.025, 3]} />
              <meshBasicMaterial color={new THREE.Color("hsl(0, 0%, 95%)")} toneMapped={false} />
            </mesh>
            {/* Glow around plane */}
            <mesh>
              <sphereGeometry args={[0.018, 8, 8]} />
              <meshBasicMaterial color={glowColor} transparent opacity={0.35} depthWrite={false} toneMapped={false} />
            </mesh>
          </group>
          {/* Trail dot */}
          <mesh ref={trailRef}>
            <sphereGeometry args={[0.01, 6, 6]} />
            <meshBasicMaterial color={color} transparent opacity={0.2} depthWrite={false} toneMapped={false} />
          </mesh>
        </>
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
