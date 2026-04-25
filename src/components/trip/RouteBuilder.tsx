import React, { useMemo } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { getAirport, latLngToVector3, createArcPoints } from "@/lib/airports";

const RADIUS = 1;

const PlannerArc: React.FC<{ from: string; to: string; index: number }> = ({ from, to, index }) => {
  const lineRef = React.useRef<THREE.Line>(null);
  const glowRef = React.useRef<THREE.Line>(null);

  const { curve, posArrA, posArrB, pointCount } = useMemo(() => {
    const a = getAirport(from);
    const b = getAirport(to);
    if (!a || !b) return { curve: null, posArrA: null, posArrB: null, pointCount: 0 };
    const f = latLngToVector3(a.lat, a.lng, RADIUS);
    const t = latLngToVector3(b.lat, b.lng, RADIUS);
    const pts = createArcPoints(f, t, 100, 0.22);
    const c = new THREE.CatmullRomCurve3(pts.map((p) => new THREE.Vector3(...p)));
    const sampled = c.getPoints(100);
    const flat = sampled.flatMap((p) => [p.x, p.y, p.z]);
    return {
      curve: c,
      posArrA: new Float32Array(flat),
      posArrB: new Float32Array(flat),
      pointCount: sampled.length,
    };
  }, [from, to]);

  useFrame((_, delta) => {
    if (lineRef.current) {
      const mat = lineRef.current.material as THREE.LineDashedMaterial;
      if (mat.dashOffset !== undefined) mat.dashOffset -= delta * 0.4;
    }
  });

  if (!curve || !posArrA || !posArrB) return null;

  return (
    <group>
      <line ref={glowRef as React.Ref<THREE.Line>}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={pointCount} array={posArrA} itemSize={3} />
        </bufferGeometry>
        <lineBasicMaterial color="#22d3ee" transparent opacity={0.2} linewidth={1} depthWrite={false} />
      </line>
      <line ref={lineRef as React.Ref<THREE.Line>}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={pointCount} array={posArrB} itemSize={3} />
        </bufferGeometry>
        <lineDashedMaterial color="#06b6d4" dashSize={0.02} gapSize={0.01} transparent opacity={0.85} linewidth={1} />
      </line>
      {/* Endpoint dots */}
      {[from, to].map((iata, i) => {
        const apt = getAirport(iata);
        if (!apt) return null;
        const [x, y, z] = latLngToVector3(apt.lat, apt.lng, RADIUS + 0.004);
        return (
          <mesh key={`${iata}-${i}`} position={[x, y, z]}>
            <sphereGeometry args={[0.008, 8, 8]} />
            <meshBasicMaterial color={i === 0 ? "#22d3ee" : "#06b6d4"} toneMapped={false} />
          </mesh>
        );
      })}
    </group>
  );
};

const RouteBuilder: React.FC = () => {
  const { currentDestinations } = useTripPlannerStore();

  if (currentDestinations.length < 2) return null;

  return (
    <group>
      {currentDestinations.slice(0, -1).map((iata, idx) => (
        <PlannerArc key={`${iata}-${currentDestinations[idx + 1]}`} from={iata} to={currentDestinations[idx + 1]} index={idx} />
      ))}
    </group>
  );
};

export default RouteBuilder;
