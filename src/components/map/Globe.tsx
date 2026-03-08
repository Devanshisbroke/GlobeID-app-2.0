import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

/** Dark globe with grid lines, subtle glow atmosphere */
const Globe: React.FC = () => {
  const atmosphereRef = useRef<THREE.Mesh>(null);
  const globeRef = useRef<THREE.Mesh>(null);

  useFrame(({ clock }) => {
    if (atmosphereRef.current) {
      const s = 1.0 + Math.sin(clock.getElapsedTime() * 0.5) * 0.003;
      atmosphereRef.current.scale.setScalar(s);
    }
  });

  const gridMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("hsl(220, 85%, 62%)") },
        uGridColor: { value: new THREE.Color("hsl(200, 90%, 60%)") },
        uBaseColor: { value: new THREE.Color("hsl(228, 20%, 8%)") },
        uVisitedColor: { value: new THREE.Color("hsl(168, 70%, 48%)") },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 uColor;
        uniform vec3 uGridColor;
        uniform vec3 uBaseColor;
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        
        void main() {
          // Base dark color
          vec3 color = uBaseColor;
          
          // Latitude/longitude grid
          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;
          
          float latGrid = smoothstep(0.0, 0.8, abs(fract(lat / 15.0) - 0.5) * 2.0);
          float lngGrid = smoothstep(0.0, 0.8, abs(fract(lng / 15.0) - 0.5) * 2.0);
          
          float grid = 1.0 - min(latGrid, lngGrid);
          grid *= 0.15;
          
          // Continent outlines (simplified via noise-like pattern)
          float detail = smoothstep(0.0, 0.6, abs(fract(lat / 5.0) - 0.5) * 2.0);
          float detailGrid = (1.0 - detail) * 0.06;
          
          color += uGridColor * grid;
          color += uColor * detailGrid;
          
          // Edge glow (fresnel)
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          fresnel = pow(fresnel, 3.0);
          color += uColor * fresnel * 0.3;
          
          gl_FragColor = vec4(color, 1.0);
        }
      `,
    });
  }, []);

  const atmosphereMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("hsl(200, 90%, 60%)") },
      },
      vertexShader: `
        varying vec3 vNormal;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 uColor;
        varying vec3 vNormal;
        void main() {
          float intensity = pow(0.7 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.5);
          gl_FragColor = vec4(uColor, intensity * 0.4);
        }
      `,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    });
  }, []);

  return (
    <group>
      {/* Main globe */}
      <mesh ref={globeRef} material={gridMaterial}>
        <sphereGeometry args={[1, 64, 64]} />
      </mesh>
      {/* Atmosphere glow */}
      <mesh ref={atmosphereRef} material={atmosphereMaterial}>
        <sphereGeometry args={[1.12, 64, 64]} />
      </mesh>
    </group>
  );
};

export default Globe;
