import React, { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { latLngToVector3 } from "@/lib/airports";

interface UserLocationProps {
  lat: number;
  lng: number;
}

const UserLocation: React.FC<UserLocationProps> = ({ lat, lng }) => {
  const pulseRef = useRef<THREE.Mesh>(null);
  const rippleRef = useRef<THREE.Mesh>(null);
  const [x, y, z] = latLngToVector3(lat, lng, 1.008);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (pulseRef.current) {
      const s = 1 + Math.sin(t * 3) * 0.3;
      pulseRef.current.scale.setScalar(s);
      (pulseRef.current.material as THREE.MeshBasicMaterial).opacity = 0.6 + Math.sin(t * 3) * 0.2;
    }
    if (rippleRef.current) {
      const rippleScale = 1 + ((t * 0.8) % 1) * 3;
      rippleRef.current.scale.setScalar(rippleScale);
      (rippleRef.current.material as THREE.MeshBasicMaterial).opacity = Math.max(0, 0.4 - ((t * 0.8) % 1) * 0.5);
    }
  });

  return (
    <group position={[x, y, z]}>
      {/* Core dot */}
      <mesh>
        <sphereGeometry args={[0.012, 12, 12]} />
        <meshBasicMaterial color="hsl(168, 70%, 55%)" toneMapped={false} />
      </mesh>
      {/* Pulse glow */}
      <mesh ref={pulseRef}>
        <sphereGeometry args={[0.02, 12, 12]} />
        <meshBasicMaterial color="hsl(168, 70%, 55%)" transparent opacity={0.5} depthWrite={false} toneMapped={false} />
      </mesh>
      {/* Ripple ring */}
      <mesh ref={rippleRef} rotation={[Math.PI / 2, 0, 0]}>
        <ringGeometry args={[0.015, 0.018, 32]} />
        <meshBasicMaterial color="hsl(168, 70%, 55%)" transparent opacity={0.3} side={THREE.DoubleSide} depthWrite={false} toneMapped={false} />
      </mesh>
    </group>
  );
};

export default UserLocation;
