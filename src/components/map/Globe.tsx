import React, { useRef, useMemo } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import * as THREE from "three";

/**
 * Realistic Earth globe with:
 * - Blue marble day texture
 * - Night city lights on dark side
 * - Bump mapping for terrain relief
 * - Continent edge glow (cyan)
 * - Animated cloud layer
 * - Dual atmosphere glow
 */
const Globe: React.FC = () => {
  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const cloudRef = useRef<THREE.Mesh>(null);
  const globeMatRef = useRef<THREE.ShaderMaterial>(null);

  // Load textures
  const [dayMap, nightMap, bumpMap, waterMap] = useLoader(THREE.TextureLoader, [
    "/textures/earth-day.jpg",
    "/textures/earth-night.jpg",
    "/textures/earth-bump.png",
    "/textures/earth-water.png",
  ]);

  // Configure texture quality
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
    if (globeMatRef.current) {
      globeMatRef.current.uniforms.uTime.value = t;
    }
    if (atmosphereRef.current) {
      const s = 1.0 + Math.sin(t * 0.5) * 0.003;
      atmosphereRef.current.scale.setScalar(s);
    }
    if (outerGlowRef.current) {
      const s = 1.0 + Math.sin(t * 0.3) * 0.002;
      outerGlowRef.current.scale.setScalar(s);
    }
    if (cloudRef.current) {
      cloudRef.current.rotation.y += 0.00015;
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
        uAtmoColor: { value: new THREE.Color("hsl(200, 90%, 60%)") },
        uCoastGlow: { value: new THREE.Color("hsl(185, 90%, 55%)") },
        uGridColor: { value: new THREE.Color("hsl(200, 80%, 50%)") },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        varying vec3 vWorldNormal;

        uniform sampler2D uBumpMap;

        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          vWorldNormal = normalize((modelMatrix * vec4(normal, 0.0)).xyz);

          // Bump displacement
          float bump = texture2D(uBumpMap, uv).r;
          vec3 displaced = position + normal * bump * 0.012;

          gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D uDayMap;
        uniform sampler2D uNightMap;
        uniform sampler2D uBumpMap;
        uniform sampler2D uWaterMap;
        uniform vec3 uSunDir;
        uniform vec3 uAtmoColor;
        uniform vec3 uCoastGlow;
        uniform vec3 uGridColor;
        uniform float uTime;

        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        varying vec3 vWorldNormal;

        void main() {
          // Sample textures
          vec3 dayColor = texture2D(uDayMap, vUv).rgb;
          vec3 nightColor = texture2D(uNightMap, vUv).rgb;
          float bump = texture2D(uBumpMap, vUv).r;
          float water = texture2D(uWaterMap, vUv).r;

          // Darken the day texture slightly for cinematic feel
          dayColor *= 0.85;

          // Sun illumination
          float sunDot = dot(vNormal, uSunDir);
          float dayFactor = smoothstep(-0.15, 0.25, sunDot);

          // Blend day and night
          vec3 surface = mix(nightColor * 1.2, dayColor, dayFactor);

          // Ocean specular shimmer on day side
          if (water < 0.5) {
            vec3 viewDir = normalize(-vPosition);
            vec3 halfDir = normalize(uSunDir + viewDir);
            float spec = pow(max(dot(vNormal, halfDir), 0.0), 80.0);
            surface += vec3(0.15, 0.25, 0.35) * spec * dayFactor * 0.6;

            // Subtle ocean darkening
            surface *= 0.92;
          }

          // Continent edge glow (using bump map edges)
          float bumpDx = dFdx(bump) * 15.0;
          float bumpDy = dFdy(bump) * 15.0;
          float edgeIntensity = length(vec2(bumpDx, bumpDy));
          edgeIntensity = smoothstep(0.08, 0.4, edgeIntensity);

          // Water mask edges for coastline glow
          float waterDx = dFdx(water) * 20.0;
          float waterDy = dFdy(water) * 20.0;
          float coastEdge = length(vec2(waterDx, waterDy));
          coastEdge = smoothstep(0.05, 0.5, coastEdge);

          float coastGlow = max(edgeIntensity, coastEdge) * 0.35;
          surface += uCoastGlow * coastGlow;

          // Subtle lat/lng grid
          float lat = asin(vPosition.y) * 57.2957795;
          float lng = atan(vPosition.z, -vPosition.x) * 57.2957795;
          float latGrid = smoothstep(0.0, 0.85, abs(fract(lat / 30.0) - 0.5) * 2.0);
          float lngGrid = smoothstep(0.0, 0.85, abs(fract(lng / 30.0) - 0.5) * 2.0);
          float grid = (1.0 - min(latGrid, lngGrid)) * 0.03;
          surface += uGridColor * grid;

          // Fresnel atmosphere edge
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          fresnel = pow(fresnel, 3.0);
          surface += uAtmoColor * fresnel * 0.25;

          // Ambient + directional lighting
          float ambient = 0.12;
          float diffuse = max(sunDot, 0.0) * 0.5;
          surface *= (ambient + diffuse + 0.5);

          gl_FragColor = vec4(surface, 1.0);
        }
      `,
    });
  }, [dayMap, nightMap, bumpMap, waterMap]);

  const atmosphereMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color("hsl(210, 85%, 45%)") },
        uColor2: { value: new THREE.Color("hsl(195, 90%, 60%)") },
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
          float intensity = pow(0.62 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.2);
          vec3 color = mix(uColor, uColor2, intensity);
          gl_FragColor = vec4(color, intensity * 0.4);
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
        uColor: { value: new THREE.Color("hsl(195, 80%, 55%)") },
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
          float intensity = pow(0.48 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 4.0);
          gl_FragColor = vec4(uColor, intensity * 0.12);
        }
      `,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    });
  }, []);

  const cloudMaterial = useMemo(() => {
    return new THREE.MeshPhongMaterial({
      map: dayMap, // Will be replaced by alpha-based approach below
      transparent: true,
      opacity: 0.0, // Invisible base
      depthWrite: false,
      side: THREE.FrontSide,
    });
  }, [dayMap]);

  // Cloud layer using procedural noise (since no cloud texture was available)
  const proceduralCloudMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: { uTime: { value: 0 } },
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
          clouds = smoothstep(0.48, 0.72, clouds) * 0.22;
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          clouds *= (1.0 - pow(fresnel, 2.0));
          gl_FragColor = vec4(vec3(0.85, 0.9, 1.0), clouds);
        }
      `,
      transparent: true,
      depthWrite: false,
      side: THREE.FrontSide,
    });
  }, []);

  return (
    <group>
      {/* Main globe with real textures */}
      <mesh ref={globeMatRef as any} material={globeMaterial}>
        <sphereGeometry args={[1, 128, 128]} />
      </mesh>
      {/* Cloud layer */}
      <mesh ref={cloudRef} material={proceduralCloudMaterial}>
        <sphereGeometry args={[1.006, 64, 64]} />
      </mesh>
      {/* Inner atmosphere */}
      <mesh ref={atmosphereRef} material={atmosphereMaterial}>
        <sphereGeometry args={[1.06, 64, 64]} />
      </mesh>
      {/* Outer glow ring */}
      <mesh ref={outerGlowRef} material={outerGlowMaterial}>
        <sphereGeometry args={[1.15, 48, 48]} />
      </mesh>
    </group>
  );
};

export default Globe;
