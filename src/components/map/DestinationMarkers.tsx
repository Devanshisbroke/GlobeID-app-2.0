import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { latLngToVector3 } from "@/lib/airports";
import { destinations } from "@/lib/explorerData";

const GLOBE_R = 1;

interface Props {
  onSelect?: (id: string) => void;
  discoveredIds?: string[];
}

const DestinationMarkers: React.FC<Props> = ({ discoveredIds = [] }) => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const glowRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const positions = useMemo(() =>
    destinations.map((d) => ({
      pos: latLngToVector3(d.lat, d.lng, GLOBE_R + 0.008),
      discovered: discoveredIds.includes(d.id),
      pop: d.popularity,
      offset: Math.random() * Math.PI * 2,
    })),
  [discoveredIds]);

  useFrame(({ clock }) => {
    if (!meshRef.current || !glowRef.current) return;
    const t = clock.getElapsedTime();
    positions.forEach((p, i) => {
      dummy.position.set(...p.pos);
      const pulse = 1 + Math.sin(t * 1.5 + p.offset) * 0.25;
      dummy.scale.setScalar(0.006 * pulse);
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);

      // Glow ring
      dummy.scale.setScalar(0.012 * pulse);
      dummy.updateMatrix();
      glowRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
    glowRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <group>
      {/* Core markers */}
      <instancedMesh ref={meshRef} args={[undefined, undefined, destinations.length]}>
        <sphereGeometry args={[1, 8, 8]} />
        <meshBasicMaterial color="#34d399" />
      </instancedMesh>
      {/* Glow halos */}
      <instancedMesh ref={glowRef} args={[undefined, undefined, destinations.length]}>
        <sphereGeometry args={[1, 8, 8]} />
        <meshBasicMaterial color="#34d399" transparent opacity={0.25} />
      </instancedMesh>
    </group>
  );
};

export default DestinationMarkers;
