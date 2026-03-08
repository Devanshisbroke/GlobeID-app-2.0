import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { latLngToVector3 } from "@/lib/airports";
import { landmarks } from "@/lib/explorerData";

const GLOBE_R = 1;

const LandmarkMarkers: React.FC = () => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const positions = useMemo(() =>
    landmarks.map((l) => ({
      pos: latLngToVector3(l.lat, l.lng, GLOBE_R + 0.015),
      offset: Math.random() * Math.PI * 2,
    })),
  []);

  useFrame(({ clock }) => {
    if (!meshRef.current) return;
    const t = clock.getElapsedTime();
    positions.forEach((p, i) => {
      dummy.position.set(...p.pos);
      const float = Math.sin(t * 1.2 + p.offset) * 0.003;
      dummy.position.y += float;
      dummy.scale.setScalar(0.005);
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, landmarks.length]}>
      <octahedronGeometry args={[1, 0]} />
      <meshBasicMaterial color="#facc15" transparent opacity={0.85} />
    </instancedMesh>
  );
};

export default LandmarkMarkers;
