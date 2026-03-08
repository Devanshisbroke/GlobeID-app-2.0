import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const Starfield: React.FC<{ count?: number }> = ({ count = 4000 }) => {
  const groupRef = useRef<THREE.Group>(null);

  const { positions, colors, sizes } = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const col = new Float32Array(count * 3);
    const siz = new Float32Array(count);

    for (let i = 0; i < count; i++) {
      // Distribute in a deep sphere shell for parallax depth
      const r = 7 + Math.random() * 16;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      pos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      pos[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
      pos[i * 3 + 2] = r * Math.cos(phi);

      const temp = Math.random();
      if (temp > 0.92) {
        col[i * 3] = 1.0; col[i * 3 + 1] = 0.88; col[i * 3 + 2] = 0.72;
      } else if (temp > 0.75) {
        col[i * 3] = 0.65; col[i * 3 + 1] = 0.85; col[i * 3 + 2] = 1.0;
      } else {
        const b = 0.65 + Math.random() * 0.35;
        col[i * 3] = b; col[i * 3 + 1] = b; col[i * 3 + 2] = Math.min(b + 0.08, 1.0);
      }

      siz[i] = 0.006 + Math.random() * 0.022;
    }
    return { positions: pos, colors: col, sizes: siz };
  }, [count]);

  // Slow parallax rotation for depth feel
  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.002;
      groupRef.current.rotation.x += delta * 0.0006;
    }
  });

  return (
    <group ref={groupRef}>
      <points>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={count} array={positions} itemSize={3} />
          <bufferAttribute attach="attributes-color" count={count} array={colors} itemSize={3} />
          <bufferAttribute attach="attributes-size" count={count} array={sizes} itemSize={1} />
        </bufferGeometry>
        <pointsMaterial
          size={0.02}
          vertexColors
          transparent
          opacity={0.85}
          sizeAttenuation
          depthWrite={false}
        />
      </points>

      {/* Faint nebula planes for depth */}
      <mesh position={[6, 2, -9]} rotation={[0.3, 0.5, 0]}>
        <planeGeometry args={[9, 6]} />
        <meshBasicMaterial color="#1a0a3a" transparent opacity={0.035} side={THREE.DoubleSide} depthWrite={false} />
      </mesh>
      <mesh position={[-5, -3, -11]} rotation={[-0.2, 0.8, 0.1]}>
        <planeGeometry args={[11, 7]} />
        <meshBasicMaterial color="#0a1a30" transparent opacity={0.025} side={THREE.DoubleSide} depthWrite={false} />
      </mesh>
    </group>
  );
};

export default Starfield;
