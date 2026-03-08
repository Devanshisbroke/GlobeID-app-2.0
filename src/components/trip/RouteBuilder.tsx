import React, { useMemo } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { getAirport, latLngToVector3, createArcPoints } from "@/lib/airports";

const RADIUS = 1;

const PlannerArc: React.FC<{ from: string; to: string; index: number }> = ({ from, to, index }) => {
  const lineRef = React.useRef<THREE.Line>(null);
  const glowRef = React.useRef<THREE.Line>(null);

  const curve = useMemo(() => {
    const a = getAirport(from);
    const b = getAirport(to);
    if (!a || !b) return null;
    const f = latLngToVector3(a.lat, a.lng, RADIUS);
    const t = latLngToVector3(b.lat, b.lng, RADIUS);
    const pts = createArcPoints(f, t, 100, 0.22);
    return new THREE.CatmullRomCurve3(pts.map((p) => new THREE.Vector3(...p)));
  }, [from, to]);

  useFrame((_, delta) => {
    if (lineRef.current) {
      const mat = lineRef.current.material as any;
      if (mat.dashOffset !== undefined) mat.dashOffset -= delta * 0.4;
    }
  });

  if (!curve) return null;
  const points = curve.getPoints(100);
  const posArr = new Float32Array(points.flatMap((p) => [p.x, p.y, p.z]));

  return (
    <group>
      <line ref={glowRef as any}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArr.slice()} itemSize={3} />
        </bufferGeometry>
        <lineBasicMaterial color="#22d3ee" transparent opacity={0.2} linewidth={1} depthWrite={false} />
      </line>
      <line ref={lineRef as any}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArr.slice()} itemSize={3} />
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
