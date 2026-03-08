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
  const ripple1Ref = useRef<THREE.Mesh>(null);
  const ripple2Ref = useRef<THREE.Mesh>(null);
  const [x, y, z] = latLngToVector3(lat, lng, 1.01);

  // Orient the ripple rings to face outward from globe center
  const normal = new THREE.Vector3(x, y, z).normalize();
  const quaternion = new THREE.Quaternion().setFromUnitVectors(
    new THREE.Vector3(0, 0, 1),
    normal
  );

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();

    if (pulseRef.current) {
      const s = 1 + Math.sin(t * 2.5) * 0.35;
      pulseRef.current.scale.setScalar(s);
      (pulseRef.current.material as THREE.MeshBasicMaterial).opacity = 0.5 + Math.sin(t * 2.5) * 0.2;
    }

    // Staggered ripples
    [ripple1Ref, ripple2Ref].forEach((ref, i) => {
      if (ref.current) {
        const phase = ((t * 0.7 + i * 0.5) % 1);
        const rippleScale = 1 + phase * 4;
        ref.current.scale.setScalar(rippleScale);
        (ref.current.material as THREE.MeshBasicMaterial).opacity = Math.max(0, 0.35 - phase * 0.45);
      }
    });
  });

  return (
    <group position={[x, y, z]} quaternion={quaternion}>
      {/* Core dot — bright */}
      <mesh>
        <sphereGeometry args={[0.014, 14, 14]} />
        <meshBasicMaterial color="hsl(200, 95%, 60%)" toneMapped={false} />
      </mesh>
      {/* Inner glow pulse */}
      <mesh ref={pulseRef}>
        <sphereGeometry args={[0.022, 12, 12]} />
        <meshBasicMaterial color="hsl(200, 90%, 60%)" transparent opacity={0.5} depthWrite={false} toneMapped={false} />
      </mesh>
      {/* Ripple ring 1 */}
      <mesh ref={ripple1Ref}>
        <ringGeometry args={[0.016, 0.02, 32]} />
        <meshBasicMaterial color="hsl(200, 90%, 60%)" transparent opacity={0.3} side={THREE.DoubleSide} depthWrite={false} toneMapped={false} />
      </mesh>
      {/* Ripple ring 2 (staggered) */}
      <mesh ref={ripple2Ref}>
        <ringGeometry args={[0.016, 0.019, 32]} />
        <meshBasicMaterial color="hsl(200, 85%, 55%)" transparent opacity={0.2} side={THREE.DoubleSide} depthWrite={false} toneMapped={false} />
      </mesh>
    </group>
  );
};

export default UserLocation;
