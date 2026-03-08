import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const Starfield: React.FC<{ count?: number }> = ({ count = 3000 }) => {
  const groupRef = useRef<THREE.Group>(null);

  const { positions, colors, sizes } = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const col = new Float32Array(count * 3);
    const siz = new Float32Array(count);

    for (let i = 0; i < count; i++) {
      const r = 6 + Math.random() * 14;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      pos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
      pos[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
      pos[i * 3 + 2] = r * Math.cos(phi);

      // Color variation: blue-white stars
      const temp = Math.random();
      if (temp > 0.9) {
        // Warm star
        col[i * 3] = 1.0;
        col[i * 3 + 1] = 0.85;
        col[i * 3 + 2] = 0.7;
      } else if (temp > 0.7) {
        // Cyan star
        col[i * 3] = 0.6;
        col[i * 3 + 1] = 0.85;
        col[i * 3 + 2] = 1.0;
      } else {
        // White star
        const b = 0.7 + Math.random() * 0.3;
        col[i * 3] = b;
        col[i * 3 + 1] = b;
        col[i * 3 + 2] = b + 0.1;
      }

      siz[i] = 0.008 + Math.random() * 0.025;
    }
    return { positions: pos, colors: col, sizes: siz };
  }, [count]);

  // Slow parallax rotation
  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.003;
      groupRef.current.rotation.x += delta * 0.001;
    }
  });

  return (
    <group ref={groupRef}>
      {/* Stars */}
      <points>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={count} array={positions} itemSize={3} />
          <bufferAttribute attach="attributes-color" count={count} array={colors} itemSize={3} />
          <bufferAttribute attach="attributes-size" count={count} array={sizes} itemSize={1} />
        </bufferGeometry>
        <pointsMaterial
          size={0.025}
          vertexColors
          transparent
          opacity={0.8}
          sizeAttenuation
          depthWrite={false}
        />
      </points>

      {/* Nebula clouds — large soft meshes */}
      <mesh position={[6, 2, -8]} rotation={[0.3, 0.5, 0]}>
        <planeGeometry args={[8, 6]} />
        <meshBasicMaterial
          color={new THREE.Color("hsl(258, 50%, 25%)")}
          transparent
          opacity={0.04}
          side={THREE.DoubleSide}
          depthWrite={false}
        />
      </mesh>
      <mesh position={[-5, -3, -10]} rotation={[-0.2, 0.8, 0.1]}>
        <planeGeometry args={[10, 7]} />
        <meshBasicMaterial
          color={new THREE.Color("hsl(210, 60%, 20%)")}
          transparent
          opacity={0.03}
          side={THREE.DoubleSide}
          depthWrite={false}
        />
      </mesh>
      <mesh position={[3, -4, -7]} rotation={[0.5, -0.3, 0.2]}>
        <planeGeometry args={[6, 5]} />
        <meshBasicMaterial
          color={new THREE.Color("hsl(180, 40%, 18%)")}
          transparent
          opacity={0.025}
          side={THREE.DoubleSide}
          depthWrite={false}
        />
      </mesh>
    </group>
  );
};

export default Starfield;
