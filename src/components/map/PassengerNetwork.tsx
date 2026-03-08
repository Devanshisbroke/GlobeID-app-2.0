import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3 } from "@/lib/airports";
import { getHubs } from "@/lib/destinationAnalytics";

const GLOBE_R = 1;

/** Pulsing hub markers at major airports */
const PassengerNetwork: React.FC = () => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const hubs = useMemo(() => {
    return getHubs().map((h) => {
      const ap = airports.find((a) => a.iata === h.iata);
      if (!ap) return null;
      const pos = latLngToVector3(ap.lat, ap.lng, GLOBE_R + 0.005);
      return { pos, pop: h.popularity, offset: Math.random() * Math.PI * 2 };
    }).filter(Boolean) as { pos: [number, number, number]; pop: number; offset: number }[];
  }, []);

  useFrame(({ clock }) => {
    if (!meshRef.current) return;
    const t = clock.getElapsedTime();
    hubs.forEach((h, i) => {
      dummy.position.set(...h.pos);
      const pulse = 1 + Math.sin(t * 2 + h.offset) * 0.3;
      const baseSize = 0.008 + (h.pop / 100) * 0.012;
      dummy.scale.setScalar(baseSize * pulse);
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, hubs.length]}>
      <sphereGeometry args={[1, 8, 8]} />
      <meshBasicMaterial color="#f0abfc" transparent opacity={0.8} />
    </instancedMesh>
  );
};

export default PassengerNetwork;
