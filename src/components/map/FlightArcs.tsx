import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { flightRoutes, getAirport, latLngToVector3, createArcPoints, type FlightRoute } from "@/lib/airports";

interface FlightArcsProps {
  showHistory: boolean;
}

const arcColors: Record<FlightRoute["type"], THREE.Color> = {
  upcoming: new THREE.Color("#3fa9ff"),
  current: new THREE.Color("#ff7a00"),
  past: new THREE.Color("#3fa9ff"),
};

const arcGlowColors: Record<FlightRoute["type"], THREE.Color> = {
  upcoming: new THREE.Color("#6bc5ff"),
  current: new THREE.Color("#ffaa44"),
  past: new THREE.Color("#5bb8ff"),
};

const FlightArc: React.FC<{ route: FlightRoute; radius: number }> = ({ route, radius }) => {
  const glowLineRef = useRef<THREE.Line>(null);
  const coreLineRef = useRef<THREE.Line>(null);
  const planeRef = useRef<THREE.Group>(null);
  const trailRef = useRef<THREE.Mesh>(null);
  const progressRef = useRef(Math.random());

  const fromAirport = getAirport(route.from);
  const toAirport = getAirport(route.to);

  const { curve, color, glowColor, posArrayA, posArrayB, pointCount } = useMemo(() => {
    if (!fromAirport || !toAirport) {
      return {
        curve: null,
        color: arcColors.past,
        glowColor: arcGlowColors.past,
        posArrayA: null,
        posArrayB: null,
        pointCount: 0,
      };
    }
    const from3D = latLngToVector3(fromAirport.lat, fromAirport.lng, radius);
    const to3D = latLngToVector3(toAirport.lat, toAirport.lng, radius);
    const arcPts = createArcPoints(from3D, to3D, 120, 0.25);
    const vectors = arcPts.map(p => new THREE.Vector3(...p));
    const c = new THREE.CatmullRomCurve3(vectors);
    // Sample once and reuse for both <line> children; two distinct
    // Float32Array buffers because each <bufferAttribute> binds the
    // backing array directly.
    const pts = c.getPoints(120);
    const flat = pts.flatMap(p => [p.x, p.y, p.z]);
    return {
      curve: c,
      color: arcColors[route.type],
      glowColor: arcGlowColors[route.type],
      posArrayA: new Float32Array(flat),
      posArrayB: new Float32Array(flat),
      pointCount: pts.length,
    };
  }, [fromAirport, toAirport, radius, route.type]);

  useFrame((_, delta) => {
    if (!curve) return;
    if (coreLineRef.current) {
      const mat = coreLineRef.current.material as THREE.LineDashedMaterial;
      if (mat.dashOffset !== undefined) mat.dashOffset -= delta * 0.35;
    }
    if (planeRef.current && (route.type === "upcoming" || route.type === "current")) {
      progressRef.current = (progressRef.current + delta * 0.05) % 1;
      const pos = curve.getPoint(progressRef.current);
      const ahead = curve.getPoint(Math.min(progressRef.current + 0.012, 1));
      planeRef.current.position.copy(pos);
      planeRef.current.lookAt(ahead);
      if (trailRef.current) {
        trailRef.current.position.copy(curve.getPoint(Math.max(progressRef.current - 0.025, 0)));
      }
    }
  });

  if (!curve || !posArrayA || !posArrayB) return null;

  const isActive = route.type === "upcoming" || route.type === "current";

  return (
    <group>
      {/* Outer glow */}
      <line ref={glowLineRef as React.Ref<THREE.Line>}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={pointCount} array={posArrayA} itemSize={3} />
        </bufferGeometry>
        <lineBasicMaterial color={glowColor} transparent opacity={isActive ? 0.3 : 0.08} linewidth={1} depthWrite={false} />
      </line>

      {/* Core dashed */}
      <line ref={coreLineRef as React.Ref<THREE.Line>}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={pointCount} array={posArrayB} itemSize={3} />
        </bufferGeometry>
        <lineDashedMaterial
          color={color}
          dashSize={isActive ? 0.025 : 0.02}
          gapSize={isActive ? 0.012 : 0.018}
          transparent
          opacity={isActive ? 0.9 : 0.35}
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
                <sphereGeometry args={[0.007, 10, 10]} />
                <meshBasicMaterial color={idx === 0 ? color : glowColor} toneMapped={false} />
              </mesh>
            );
          })}
        </>
      )}

      {/* Aircraft + fading trail */}
      {isActive && (
        <>
          <group ref={planeRef}>
            <mesh rotation={[Math.PI / 2, 0, 0]}>
              <coneGeometry args={[0.007, 0.022, 3]} />
              <meshBasicMaterial color="#ffffff" toneMapped={false} />
            </mesh>
            <mesh>
              <sphereGeometry args={[0.015, 8, 8]} />
              <meshBasicMaterial color={glowColor} transparent opacity={0.3} depthWrite={false} toneMapped={false} />
            </mesh>
          </group>
          <mesh ref={trailRef}>
            <sphereGeometry args={[0.009, 6, 6]} />
            <meshBasicMaterial color={color} transparent opacity={0.15} depthWrite={false} toneMapped={false} />
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
