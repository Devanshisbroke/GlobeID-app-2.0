import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3, createArcPoints } from "@/lib/airports";
import { generateSimulatedFlights } from "@/simulation/PlanetSimulation";

const GLOBE_R = 1;

interface Props {
  count?: number;
  speed?: number;
}

/** Renders moving "flight lights" along arcs — lightweight instanced points */
const AirTrafficLayer: React.FC<Props> = ({ count = 80, speed = 1 }) => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const flights = useMemo(() => {
    const sims = generateSimulatedFlights(count);
    return sims.map((f) => {
      const from = latLngToVector3(f.from.lat, f.from.lng, GLOBE_R);
      const to = latLngToVector3(f.to.lat, f.to.lng, GLOBE_R);
      const pts = createArcPoints(from, to, 48, 0.1 + Math.random() * 0.15);
      return {
        points: pts.map((p) => new THREE.Vector3(...p)),
        t: Math.random(),
        spd: (0.02 + Math.random() * 0.03) * speed,
      };
    });
  }, [count, speed]);

  useFrame((_, delta) => {
    if (!meshRef.current) return;
    flights.forEach((f, i) => {
      f.t = (f.t + delta * f.spd * speed) % 1;
      const idx = Math.floor(f.t * (f.points.length - 1));
      dummy.position.copy(f.points[idx]);
      const glow = 0.5 + Math.sin(f.t * Math.PI) * 0.5;
      dummy.scale.setScalar(0.004 * glow + 0.002);
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
      <sphereGeometry args={[1, 4, 4]} />
      <meshBasicMaterial color="#facc15" transparent opacity={0.9} />
    </instancedMesh>
  );
};

export default AirTrafficLayer;
