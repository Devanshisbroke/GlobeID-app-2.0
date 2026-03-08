import React, { useRef, useMemo } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import * as THREE from "three";

const Globe: React.FC = () => {
  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const cloudRef = useRef<THREE.Mesh>(null);
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  const [dayMap, nightMap, bumpMap] = useLoader(THREE.TextureLoader, [
    "/textures/earth-day.jpg",
    "/textures/earth-night.jpg",
    "/textures/earth-bump.png",
  ]);

  useMemo(() => {
    [dayMap, nightMap, bumpMap].forEach((tex) => {
      if (tex) {
        tex.minFilter = THREE.LinearMipMapLinearFilter;
        tex.magFilter = THREE.LinearFilter;
        tex.anisotropy = 4;
      }
    });
  }, [dayMap, nightMap, bumpMap]);

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

  // Clean globe shader — texture-only, no derivative edge detection
  const globeMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uDayMap: { value: dayMap },
        uNightMap: { value: nightMap },
        uBumpMap: { value: bumpMap },
        uSunDir: { value: new THREE.Vector3(1.0, 0.3, 0.8).normalize() },
        uAtmoColor: { value: new THREE.Color("#4da6e6") },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        uniform sampler2D uBumpMap;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          // Subtle bump displacement
          float bump = texture2D(uBumpMap, uv).r;
          vec3 displaced = position + normal * bump * 0.008;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D uDayMap;
        uniform sampler2D uNightMap;
        uniform vec3 uSunDir;
        uniform vec3 uAtmoColor;
        uniform float uTime;
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;

        void main() {
          // Sample textures directly — no processing artifacts
          vec3 dayColor = texture2D(uDayMap, vUv).rgb;
          vec3 nightColor = texture2D(uNightMap, vUv).rgb;

          // Day/night blend based on sun direction
          float sunDot = dot(vNormal, uSunDir);
          float dayFactor = smoothstep(-0.15, 0.25, sunDot);

          // Slightly darken day side for cinematic feel
          vec3 day = dayColor * 0.88;

          // Warm night city lights
          vec3 night = nightColor * vec3(1.3, 1.0, 0.7) * 1.1;

          // Smooth day/night blend
          vec3 surface = mix(night, day, dayFactor);

          // Simple diffuse lighting
          float ambient = 0.15;
          float diffuse = max(sunDot, 0.0) * 0.4;
          surface *= (ambient + diffuse + 0.5);

          // Fresnel atmosphere rim — soft edge glow
          float fresnel = 1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0)));
          fresnel = pow(fresnel, 3.5);
          surface += uAtmoColor * fresnel * 0.18;

          gl_FragColor = vec4(surface, 1.0);
        }
      `,
    });
  }, [dayMap, nightMap, bumpMap]);

  // Inner atmosphere
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

  // Outer glow
  const outerGlowMaterial = useMemo(() => {
    return new THREE.ShaderMaterial({
      uniforms: { uColor: { value: new THREE.Color("#78b4ff") } },
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

  // Procedural clouds
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
          clouds = smoothstep(0.48, 0.72, clouds) * 0.18;
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
      <mesh>
        <sphereGeometry args={[1, 128, 128]} />
        <shaderMaterial ref={materialRef} attach="material" {...globeMaterial} />
      </mesh>
      <mesh ref={cloudRef} material={proceduralCloudMaterial}>
        <sphereGeometry args={[1.005, 64, 64]} />
      </mesh>
      <mesh ref={atmosphereRef} material={atmosphereMaterial}>
        <sphereGeometry args={[1.055, 64, 64]} />
      </mesh>
      <mesh ref={outerGlowRef} material={outerGlowMaterial}>
        <sphereGeometry args={[1.12, 48, 48]} />
      </mesh>
    </group>
  );
};

export default Globe;
