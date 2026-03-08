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

const PassengerParticles: React.FC<Props> = ({ count = 120, speed = 1 }) => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const trails = useMemo(() => {
    const flights = generateSimulatedFlights(count);
    return flights.map((f) => {
      const from = latLngToVector3(f.from.lat, f.from.lng, GLOBE_R);
      const to = latLngToVector3(f.to.lat, f.to.lng, GLOBE_R);
      const pts = createArcPoints(from, to, 64, 0.08 + Math.random() * 0.12);
      return {
        points: pts.map((p) => new THREE.Vector3(...p)),
        progress: Math.random(),
        speed: (0.015 + Math.random() * 0.025) * speed,
        size: 0.003 + Math.random() * 0.004,
      };
    });
  }, [count, speed]);

  useFrame((_, delta) => {
    if (!meshRef.current) return;
    trails.forEach((t, i) => {
      t.progress = (t.progress + delta * t.speed * speed) % 1;
      const idx = Math.floor(t.progress * (t.points.length - 1));
      const pos = t.points[idx];
      dummy.position.copy(pos);
      dummy.scale.setScalar(t.size * (0.7 + Math.sin(t.progress * Math.PI) * 0.6));
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
      <sphereGeometry args={[1, 5, 5]} />
      <meshBasicMaterial color="#7dd3fc" transparent opacity={0.85} />
    </instancedMesh>
  );
};

export default PassengerParticles;
