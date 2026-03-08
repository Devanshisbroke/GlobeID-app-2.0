import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { airports, latLngToVector3 } from "@/lib/airports";

interface AirportMarkersProps {
  showAirports: boolean;
}

const AirportMarkers: React.FC<AirportMarkersProps> = ({ showAirports }) => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const glowRef = useRef<THREE.InstancedMesh>(null);

  const count = airports.length;

  const { matrices, colors } = useMemo(() => {
    const mats: THREE.Matrix4[] = [];
    const cols: THREE.Color[] = [];
    const dummy = new THREE.Object3D();
    const cyanColor = new THREE.Color("hsl(200, 90%, 60%)");
    const amberColor = new THREE.Color("hsl(36, 92%, 58%)");

    airports.forEach((airport) => {
      const [x, y, z] = latLngToVector3(airport.lat, airport.lng, 1.005);
      dummy.position.set(x, y, z);
      dummy.lookAt(0, 0, 0);
      dummy.updateMatrix();
      mats.push(dummy.matrix.clone());
      // Color US airports differently
      cols.push(airport.country === "United States" ? amberColor : cyanColor);
    });
    return { matrices: mats, colors: cols };
  }, []);

  React.useEffect(() => {
    if (!meshRef.current || !glowRef.current) return;
    const colorArray = new Float32Array(count * 3);
    matrices.forEach((mat, i) => {
      meshRef.current!.setMatrixAt(i, mat);
      glowRef.current!.setMatrixAt(i, mat);
      colorArray[i * 3] = colors[i].r;
      colorArray[i * 3 + 1] = colors[i].g;
      colorArray[i * 3 + 2] = colors[i].b;
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
    glowRef.current.instanceMatrix.needsUpdate = true;
    meshRef.current.geometry.setAttribute(
      "instanceColor",
      new THREE.InstancedBufferAttribute(colorArray, 3)
    );
  }, [matrices, colors, count]);

  useFrame(({ clock }) => {
    if (glowRef.current) {
      const mat = glowRef.current.material as THREE.MeshBasicMaterial;
      mat.opacity = 0.15 + Math.sin(clock.getElapsedTime() * 2) * 0.08;
    }
  });

  if (!showAirports) return null;

  return (
    <group>
      {/* Core dots */}
      <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
        <sphereGeometry args={[0.006, 8, 8]} />
        <meshBasicMaterial color="hsl(200, 90%, 60%)" toneMapped={false} />
      </instancedMesh>
      {/* Glow dots */}
      <instancedMesh ref={glowRef} args={[undefined, undefined, count]}>
        <sphereGeometry args={[0.012, 8, 8]} />
        <meshBasicMaterial color="hsl(200, 90%, 60%)" transparent opacity={0.2} toneMapped={false} depthWrite={false} />
      </instancedMesh>
    </group>
  );
};

export default AirportMarkers;
