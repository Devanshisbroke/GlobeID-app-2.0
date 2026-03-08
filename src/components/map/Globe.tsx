import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

/**
 * Premium globe with procedural continents, ocean gradient,
 * dual atmosphere layers, and rotating cloud band.
 */
const Globe: React.FC = () => {
  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const cloudRef = useRef<THREE.Mesh>(null);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (atmosphereRef.current) {
      const s = 1.0 + Math.sin(t * 0.5) * 0.003;
      atmosphereRef.current.scale.setScalar(s);
    }
    if (outerGlowRef.current) {
      const s = 1.0 + Math.sin(t * 0.3) * 0.002;
      outerGlowRef.current.scale.setScalar(s);
    }
    if (cloudRef.current) {
      cloudRef.current.rotation.y += 0.0003;
    }
  });

  const globeMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uOceanDeep: { value: new THREE.Color("hsl(220, 60%, 8%)") },
        uOceanMid: { value: new THREE.Color("hsl(215, 55%, 14%)") },
        uOceanLight: { value: new THREE.Color("hsl(210, 50%, 18%)") },
        uLandDark: { value: new THREE.Color("hsl(150, 25%, 12%)") },
        uLandMid: { value: new THREE.Color("hsl(140, 20%, 18%)") },
        uLandLight: { value: new THREE.Color("hsl(130, 18%, 24%)") },
        uCoastGlow: { value: new THREE.Color("hsl(200, 90%, 55%)") },
        uGridColor: { value: new THREE.Color("hsl(200, 80%, 50%)") },
        uAtmoColor: { value: new THREE.Color("hsl(210, 90%, 60%)") },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        varying vec3 vWorldPos;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          vWorldPos = (modelMatrix * vec4(position, 1.0)).xyz;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 uOceanDeep;
        uniform vec3 uOceanMid;
        uniform vec3 uOceanLight;
        uniform vec3 uLandDark;
        uniform vec3 uLandMid;
        uniform vec3 uLandLight;
        uniform vec3 uCoastGlow;
        uniform vec3 uGridColor;
        uniform vec3 uAtmoColor;
        uniform float uTime;
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;

        // Simplex-like hash noise
        float hash(vec2 p) {
          p = fract(p * vec2(123.34, 456.21));
          p += dot(p, p + 45.32);
          return fract(p.x * p.y);
        }

        float noise(vec2 p) {
          vec2 i = floor(p);
          vec2 f = fract(p);
          f = f * f * (3.0 - 2.0 * f);
          float a = hash(i);
          float b = hash(i + vec2(1.0, 0.0));
          float c = hash(i + vec2(0.0, 1.0));
          float d = hash(i + vec2(1.0, 1.0));
          return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
        }

        float fbm(vec2 p) {
          float v = 0.0;
          float a = 0.5;
          for (int i = 0; i < 5; i++) {
            v += a * noise(p);
            p *= 2.1;
            a *= 0.48;
          }
          return v;
        }

        void main() {
          // Spherical coords
          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;

          // Generate continent mask with FBM noise
          vec2 noiseCoord = vec2(lng * 0.03, lat * 0.04);
          float continentNoise = fbm(noiseCoord + vec2(3.7, 1.2));
          float continent2 = fbm(noiseCoord * 1.5 + vec2(7.1, 4.8));
          float landMask = smoothstep(0.42, 0.52, continentNoise * 0.7 + continent2 * 0.3);

          // Polar ice caps
          float polarMask = smoothstep(0.0, 0.15, abs(vPosition.y) - 0.85);
          landMask = max(landMask, polarMask * 0.6);

          // Ocean color with depth variation
          float oceanDepth = fbm(noiseCoord * 2.0 + vec2(1.0, 2.0));
          vec3 ocean = mix(uOceanDeep, uOceanMid, oceanDepth * 0.6);
          ocean = mix(ocean, uOceanLight, smoothstep(0.35, 0.42, continentNoise * 0.7 + continent2 * 0.3) * 0.5);

          // Land color with elevation
          float elevation = fbm(noiseCoord * 3.0 + vec2(5.5, 3.2));
          vec3 land = mix(uLandDark, uLandMid, elevation);
          land = mix(land, uLandLight, smoothstep(0.6, 0.8, elevation));

          // Coastline glow
          float coastline = smoothstep(0.0, 0.08, abs(continentNoise * 0.7 + continent2 * 0.3 - 0.47));
          coastline = 1.0 - coastline;
          vec3 coast = uCoastGlow * coastline * 0.4;

          // Combine land and ocean
          vec3 surface = mix(ocean, land, landMask);
          surface += coast;

          // Subtle lat/lng grid
          float latGrid = smoothstep(0.0, 0.85, abs(fract(lat / 30.0) - 0.5) * 2.0);
          float lngGrid = smoothstep(0.0, 0.85, abs(fract(lng / 30.0) - 0.5) * 2.0);
          float grid = (1.0 - min(latGrid, lngGrid)) * 0.06;
          surface += uGridColor * grid;

          // Fresnel edge glow
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          fresnel = pow(fresnel, 3.5);
          surface += uAtmoColor * fresnel * 0.35;

          // Subtle lighting
          vec3 lightDir = normalize(vec3(1.0, 0.5, 0.8));
          float diffuse = max(dot(vNormal, lightDir), 0.0);
          surface *= 0.7 + diffuse * 0.4;

          gl_FragColor = vec4(surface, 1.0);
        }
      `,
    });
  }, []);

  const atmosphereMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("hsl(200, 90%, 60%)") },
        uColor2: { value: new THREE.Color("hsl(220, 85%, 55%)") },
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
        uniform vec3 uColor2;
        varying vec3 vNormal;
        void main() {
          float intensity = pow(0.65 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.0);
          vec3 color = mix(uColor, uColor2, intensity);
          gl_FragColor = vec4(color, intensity * 0.5);
        }
      `,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    });
  }, []);

  const outerGlowMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("hsl(200, 80%, 55%)") },
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
          float intensity = pow(0.5 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 4.0);
          gl_FragColor = vec4(uColor, intensity * 0.15);
        }
      `,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    });
  }, []);

  const cloudMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
      },
      vertexShader: `
        varying vec3 vPosition;
        varying vec3 vNormal;
        void main() {
          vPosition = position;
          vNormal = normalize(normalMatrix * normal);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        varying vec3 vPosition;
        varying vec3 vNormal;

        float hash(vec2 p) {
          p = fract(p * vec2(123.34, 456.21));
          p += dot(p, p + 45.32);
          return fract(p.x * p.y);
        }
        float noise(vec2 p) {
          vec2 i = floor(p);
          vec2 f = fract(p);
          f = f * f * (3.0 - 2.0 * f);
          return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
                     mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
        }
        float fbm(vec2 p) {
          float v = 0.0, a = 0.5;
          for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
          return v;
        }

        void main() {
          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;
          float clouds = fbm(vec2(lng * 0.04, lat * 0.05) + vec2(2.0, 5.0));
          clouds = smoothstep(0.45, 0.7, clouds) * 0.12;

          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          clouds *= (1.0 - pow(fresnel, 2.0));

          gl_FragColor = vec4(vec3(0.7, 0.85, 1.0), clouds);
        }
      `,
      transparent: true,
      depthWrite: false,
      side: THREE.FrontSide,
    });
  }, []);

  return (
    <group>
      {/* Main globe */}
      <mesh material={globeMaterial}>
        <sphereGeometry args={[1, 96, 96]} />
      </mesh>
      {/* Cloud layer */}
      <mesh ref={cloudRef} material={cloudMaterial}>
        <sphereGeometry args={[1.008, 64, 64]} />
      </mesh>
      {/* Inner atmosphere */}
      <mesh ref={atmosphereRef} material={atmosphereMaterial}>
        <sphereGeometry args={[1.08, 64, 64]} />
      </mesh>
      {/* Outer glow ring */}
      <mesh ref={outerGlowRef} material={outerGlowMaterial}>
        <sphereGeometry args={[1.2, 48, 48]} />
      </mesh>
    </group>
  );
};

export default Globe;
