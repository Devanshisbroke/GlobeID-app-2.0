import React, { useRef, useMemo } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import * as THREE from "three";

const Globe: React.FC = () => {
  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const cloudRef = useRef<THREE.Mesh>(null);
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  const [dayMap, nightMap, bumpMap, waterMap] = useLoader(THREE.TextureLoader, [
    "/textures/earth-day.jpg",
    "/textures/earth-night.jpg",
    "/textures/earth-bump.png",
    "/textures/earth-water.png",
  ]);

  useMemo(() => {
    [dayMap, nightMap, bumpMap, waterMap].forEach((tex) => {
      if (tex) {
        tex.minFilter = THREE.LinearMipMapLinearFilter;
        tex.magFilter = THREE.LinearFilter;
        tex.anisotropy = 4;
      }
    });
  }, [dayMap, nightMap, bumpMap, waterMap]);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (materialRef.current) {
      materialRef.current.uniforms.uTime.value = t;
    }
    if (atmosphereRef.current) {
      atmosphereRef.current.scale.setScalar(1.0 + Math.sin(t * 0.4) * 0.002);
    }
    if (outerGlowRef.current) {
      outerGlowRef.current.scale.setScalar(1.0 + Math.sin(t * 0.25) * 0.001);
    }
    if (cloudRef.current) {
      cloudRef.current.rotation.y += 0.00012;
    }
  });

  const globeMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uDayMap: { value: dayMap },
        uNightMap: { value: nightMap },
        uBumpMap: { value: bumpMap },
        uWaterMap: { value: waterMap },
        uSunDir: { value: new THREE.Vector3(1.0, 0.3, 0.8).normalize() },
        uOceanDeep: { value: new THREE.Color("#08121f") },
        uContinentDark: { value: new THREE.Color("#0f1e33") },
        uAtmoColor: { value: new THREE.Color("#4da6e6") },
        uCoastGlow: { value: new THREE.Color("#00e0ff") },
        uGridColor: { value: new THREE.Color("#1a4a7a") },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        varying vec3 vWorldPos;
        uniform sampler2D uBumpMap;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          vWorldPos = (modelMatrix * vec4(position, 1.0)).xyz;
          float bump = texture2D(uBumpMap, uv).r;
          vec3 displaced = position + normal * bump * 0.01;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D uDayMap;
        uniform sampler2D uNightMap;
        uniform sampler2D uBumpMap;
        uniform sampler2D uWaterMap;
        uniform vec3 uSunDir;
        uniform vec3 uOceanDeep;
        uniform vec3 uContinentDark;
        uniform vec3 uAtmoColor;
        uniform vec3 uCoastGlow;
        uniform vec3 uGridColor;
        uniform float uTime;
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        varying vec3 vWorldPos;

        void main() {
          vec3 dayColor = texture2D(uDayMap, vUv).rgb;
          vec3 nightColor = texture2D(uNightMap, vUv).rgb;
          float bump = texture2D(uBumpMap, vUv).r;
          float water = texture2D(uWaterMap, vUv).r;

          float sunDot = dot(vNormal, uSunDir);
          float dayFactor = smoothstep(-0.2, 0.3, sunDot);

          vec3 tintedDay = mix(dayColor, dayColor * 1.1, bump) * 0.82;

          if (water < 0.5) {
            vec3 oceanBase = mix(uOceanDeep, dayColor * 0.6, 0.3);
            vec3 viewDir = normalize(-vWorldPos);
            vec3 halfDir = normalize(uSunDir + viewDir);
            float spec = pow(max(dot(vNormal, halfDir), 0.0), 120.0);
            float microWave = sin(vUv.x * 800.0 + uTime * 0.3) * sin(vUv.y * 600.0 + uTime * 0.2) * 0.02;
            oceanBase += vec3(0.08, 0.16, 0.28) * spec * dayFactor * 0.7;
            oceanBase += microWave * dayFactor;
            tintedDay = oceanBase;
          }

          vec3 nightBoosted = nightColor * vec3(1.4, 1.1, 0.7) * 1.5;
          vec3 surface = mix(nightBoosted, tintedDay, dayFactor);

          float bumpEdge = length(vec2(dFdx(bump), dFdy(bump))) * 18.0;
          float waterEdge = length(vec2(dFdx(water), dFdy(water))) * 22.0;
          float coastGlow = smoothstep(0.06, 0.5, max(bumpEdge, waterEdge)) * 0.3;
          surface += uCoastGlow * coastGlow * (0.6 + dayFactor * 0.4);

          surface += vec3(0.03, 0.04, 0.06) * bump * dayFactor;

          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;
          float latGrid = smoothstep(0.0, 0.9, abs(fract(lat / 30.0) - 0.5) * 2.0);
          float lngGrid = smoothstep(0.0, 0.9, abs(fract(lng / 30.0) - 0.5) * 2.0);
          float grid = (1.0 - min(latGrid, lngGrid)) * 0.02;
          surface += uGridColor * grid;

          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          fresnel = pow(fresnel, 3.5);
          surface += uAtmoColor * fresnel * 0.2;

          float ambient = 0.14;
          float diffuse = max(sunDot, 0.0) * 0.45;
          surface *= (ambient + diffuse + 0.5);

          gl_FragColor = vec4(surface, 1.0);
        }
      `,
    });
  }, [dayMap, nightMap, bumpMap, waterMap]);

  const atmosphereMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("#1a5a9e") },
        uColor2: { value: new THREE.Color("#78b4ff") },
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
          float intensity = pow(0.6 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.5);
          vec3 color = mix(uColor, uColor2, intensity);
          gl_FragColor = vec4(color, intensity * 0.25);
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
        uColor: { value: new THREE.Color("#78b4ff") },
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
          float intensity = pow(0.45 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 4.5);
          gl_FragColor = vec4(uColor, intensity * 0.1);
        }
      `,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    });
  }, []);

  const proceduralCloudMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
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
          vec2 i = floor(p); vec2 f = fract(p);
          f = f * f * (3.0 - 2.0 * f);
          return mix(mix(hash(i), hash(i+vec2(1,0)), f.x),
                     mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
        }
        float fbm(vec2 p) {
          float v = 0.0, a = 0.5;
          for (int i = 0; i < 5; i++) { v += a*noise(p); p *= 2.1; a *= 0.45; }
          return v;
        }
        void main() {
          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;
          float clouds = fbm(vec2(lng * 0.035, lat * 0.045) + vec2(2.0, 5.0));
          clouds = smoothstep(0.48, 0.72, clouds) * 0.2;
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          clouds *= (1.0 - pow(fresnel, 2.0));
          gl_FragColor = vec4(vec3(0.82, 0.88, 1.0), clouds);
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
      <mesh>
        <sphereGeometry args={[1, 128, 128]} />
        <shaderMaterial ref={materialRef} attach="material" {...globeMaterial} />
      </mesh>
      {/* Cloud layer */}
      <mesh ref={cloudRef} material={proceduralCloudMaterial}>
        <sphereGeometry args={[1.005, 64, 64]} />
      </mesh>
      {/* Inner atmosphere */}
      <mesh ref={atmosphereRef} material={atmosphereMaterial}>
        <sphereGeometry args={[1.055, 64, 64]} />
      </mesh>
      {/* Outer glow */}
      <mesh ref={outerGlowRef} material={outerGlowMaterial}>
        <sphereGeometry args={[1.12, 48, 48]} />
      </mesh>
    </group>
  );
};

export default Globe;
