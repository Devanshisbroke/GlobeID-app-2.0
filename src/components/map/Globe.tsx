import React, { useRef, useMemo } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import * as THREE from "three";
import { isMobileOrCapacitor } from "@/hooks/useMobileDetect";
import { sunDirection } from "@/lib/sunPosition";

const Globe: React.FC = () => {

  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const cloudsRef = useRef<THREE.Mesh>(null);
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  const mobile = useMemo(() => isMobileOrCapacitor(), []);
  // Lower the sphere tessellation on mobile — visually identical at the
  // typical render scale, materially cheaper.
  const sphereSegments = mobile ? 96 : 128;
  const atmoSegments = mobile ? 48 : 64;
  const glowSegments = mobile ? 32 : 48;

  const [dayMap, nightMap, bumpMap, waterMap, cloudMap] = useLoader(
    THREE.TextureLoader,
    [
      "/textures/earth-day.jpg",
      "/textures/earth-night.jpg",
      "/textures/earth-bump.png",
      "/textures/earth-water.png",
      "/textures/earth-clouds.png",
    ],
  );

  useMemo(() => {
    [dayMap, nightMap, bumpMap, waterMap, cloudMap].forEach((tex) => {
      if (tex) {
        tex.minFilter = THREE.LinearMipMapLinearFilter;
        tex.magFilter = THREE.LinearFilter;
        tex.anisotropy = mobile ? 4 : 8;
        tex.colorSpace = THREE.SRGBColorSpace;
      }
    });
  }, [dayMap, nightMap, bumpMap, waterMap, cloudMap, mobile]);

  // Cache the last-applied sun direction so we only push to the GPU
  // when it has materially shifted. Sun moves ~0.25°/min — a 1-min
  // refresh is undetectable visually, ample for the terminator.
  const lastSunUpdateRef = useRef<number>(0);

  useFrame(({ clock }) => {

    const t = clock.getElapsedTime();

    if (materialRef.current) {
      materialRef.current.uniforms.uTime.value = t;

      // Real-time sun direction → day/night terminator follows the
      // actual sub-solar point. Refreshed at most every 60s.
      if (t - lastSunUpdateRef.current > 60) {
        lastSunUpdateRef.current = t;
        const dir = sunDirection(new Date());
        const v = materialRef.current.uniforms.uSunDir.value as THREE.Vector3;
        v.set(dir[0], dir[1], dir[2]).normalize();
      }
    }

    // Sub-perceptible "breathing" — skip the trig + matrix update on
    // mobile where every dropped useFrame side-effect helps frame budget.
    if (!mobile) {
      if (atmosphereRef.current) {
        atmosphereRef.current.scale.setScalar(
          1 + Math.sin(t * 0.4) * 0.002
        );
      }

      if (outerGlowRef.current) {
        outerGlowRef.current.scale.setScalar(
          1 + Math.sin(t * 0.25) * 0.001
        );
      }
    }

    // Drift the cloud sphere independently of the surface for a soft
    // weather-system effect. ~1 full revolution / 12 minutes — matches
    // Apple Maps' globe cloud parallax. Skipped on mobile to save GPU.
    if (!mobile && cloudsRef.current) {
      cloudsRef.current.rotation.y = t * 0.0087;
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

        uSunDir: {
          // Initialise with the *actual* sun direction so first render
          // already shows the correct terminator. useFrame will keep it
          // refreshed on a 60s cadence.
          value: (() => {
            const d = sunDirection(new Date());
            return new THREE.Vector3(d[0], d[1], d[2]).normalize();
          })()
        },

        // darker land
        uLandColor: { value: new THREE.Color("#132f52") },

        // brighter ocean
        uOceanColor: { value: new THREE.Color("#2f7edb") },

        uAtmoColor: { value: new THREE.Color("#78b4ff") },
        uCityLightColor: { value: new THREE.Color("#ffd27a") }

      },

      vertexShader: `

        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;

        uniform sampler2D uBumpMap;

        void main(){

          vNormal = normalize(normalMatrix * normal);
          vPosition = (modelMatrix * vec4(position,1.0)).xyz;
          vUv = uv;

          float bump = texture2D(uBumpMap, uv).r;

          vec3 displaced = position + normal * bump * 0.006;

          gl_Position =
            projectionMatrix *
            modelViewMatrix *
            vec4(displaced,1.0);
        }
      `,

      fragmentShader: `

        uniform sampler2D uDayMap;
        uniform sampler2D uNightMap;
        uniform sampler2D uBumpMap;
        uniform sampler2D uWaterMap;

        uniform vec3 uSunDir;
        uniform vec3 uLandColor;
        uniform vec3 uOceanColor;
        uniform vec3 uAtmoColor;
        uniform vec3 uCityLightColor;

        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;

        void main(){

          float water = texture2D(uWaterMap,vUv).r;
          float bump = texture2D(uBumpMap,vUv).r;
          float nightLum = texture2D(uNightMap,vUv).r;
          vec3 dayColor = texture2D(uDayMap,vUv).rgb;

          float isLand = 1.0 - smoothstep(0.45,0.55,water);

          vec3 land = uLandColor;
          vec3 ocean = uOceanColor;

          land += vec3(0.02,0.03,0.05) * bump;

          // Blend the procedural land/ocean tint with the real NASA
          // Earth diffuse so the photograph dominates while we still
          // get that cinematic blue ocean tonality. 0.78 ratio favours
          // the real photo for Apple/Google-class visual fidelity.
          vec3 surface = mix(ocean, land, isLand);
          surface = mix(surface, dayColor, 0.78);

          float sunDot =
            dot(normalize(vNormal), normalize(uSunDir));

          float dayFactor =
            smoothstep(-0.15,0.25,sunDot);

          float ambient = 0.7;

          float landDiffuse = max(sunDot,0.0) * 0.35;
          float waterDiffuse = max(sunDot,0.0) * 0.55;

          float diffuse = mix(waterDiffuse, landDiffuse, isLand);

          surface *= (ambient + diffuse);

          float nightFactor = 1.0 - dayFactor;

          float cityGlow =
            nightLum * nightFactor * 0.4;

          surface +=
            uCityLightColor *
            cityGlow *
            isLand;

          vec3 viewDir =
            normalize(cameraPosition - vPosition);

          float fresnel =
            1.0 - dot(normalize(vNormal), viewDir);

          fresnel = pow(fresnel,3.0);

          surface +=
            uAtmoColor *
            fresnel *
            0.25;

          // tone mapping
          surface = surface / (surface + vec3(1.0));

          surface *= 1.5;

          gl_FragColor =
            vec4(surface,1.0);
        }

      `
    });

  }, [dayMap, nightMap, bumpMap, waterMap]);

  const atmosphereMaterial = useMemo(() => {

    return new THREE.ShaderMaterial({

      uniforms: {
        uColor: { value: new THREE.Color("#1a5a9e") },
        uColor2: { value: new THREE.Color("#78b4ff") }
      },

      vertexShader: `
        varying vec3 vNormal;
        void main(){
          vNormal = normalize(normalMatrix * normal);
          gl_Position =
            projectionMatrix *
            modelViewMatrix *
            vec4(position,1.0);
        }
      `,

      fragmentShader: `
        uniform vec3 uColor;
        uniform vec3 uColor2;
        varying vec3 vNormal;

        void main(){
          float intensity =
            pow(0.6 - dot(vNormal,vec3(0,0,1)),2.5);

          vec3 color =
            mix(uColor,uColor2,intensity);

          gl_FragColor =
            vec4(color,intensity * 0.25);
        }
      `,

      side: THREE.BackSide,
      transparent: true,
      depthWrite: false
    });

  }, []);

  const outerGlowMaterial = useMemo(() => {

    return new THREE.ShaderMaterial({

      uniforms: {
        uColor: { value: new THREE.Color("#78b4ff") }
      },

      vertexShader: `
        varying vec3 vNormal;
        void main(){
          vNormal = normalize(normalMatrix * normal);
          gl_Position =
            projectionMatrix *
            modelViewMatrix *
            vec4(position,1.0);
        }
      `,

      fragmentShader: `
        uniform vec3 uColor;
        varying vec3 vNormal;

        void main(){
          float intensity =
            pow(0.45 - dot(vNormal,vec3(0,0,1)),4.5);

          gl_FragColor =
            vec4(uColor,intensity * 0.1);
        }
      `,

      side: THREE.BackSide,
      transparent: true,
      depthWrite: false
    });

  }, []);

  return (

    <group>

      <mesh>
        <sphereGeometry args={[1, sphereSegments, sphereSegments]} />

        <primitive
          object={globeMaterial}
          ref={materialRef}
          attach="material"
        />

      </mesh>

      <mesh
        ref={atmosphereRef}
        material={atmosphereMaterial}
      >
        <sphereGeometry args={[1.055, atmoSegments, atmoSegments]} />
      </mesh>

      {/* Cloud layer — real NASA cloud cover photo, transparent
          where there's open sky. Drifts at a different rate than the
          surface beneath for a parallax effect. Skipped on mobile to
          keep the fragment shader budget lean. */}
      {!mobile && cloudMap ? (
        <mesh ref={cloudsRef}>
          <sphereGeometry args={[1.012, sphereSegments, sphereSegments]} />
          <meshPhongMaterial
            map={cloudMap}
            transparent
            opacity={0.65}
            depthWrite={false}
          />
        </mesh>
      ) : null}

      <mesh
        ref={outerGlowRef}
        material={outerGlowMaterial}
      >
        <sphereGeometry args={[1.12, glowSegments, glowSegments]} />
      </mesh>

    </group>

  );

};

export default Globe;
