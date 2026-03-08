import React, { useRef, useMemo } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import * as THREE from "three";

const Globe: React.FC = () => {

  const atmosphereRef = useRef<THREE.Mesh>(null);
  const outerGlowRef = useRef<THREE.Mesh>(null);
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  const [nightMap, bumpMap, waterMap] = useLoader(THREE.TextureLoader, [
    "/textures/earth-night.jpg",
    "/textures/earth-bump.png",
    "/textures/earth-water.png",
  ]);

  useMemo(() => {
    [nightMap, bumpMap, waterMap].forEach((tex) => {
      if (tex) {
        tex.minFilter = THREE.LinearMipMapLinearFilter;
        tex.magFilter = THREE.LinearFilter;
        tex.anisotropy = 4;
      }
    });
  }, [nightMap, bumpMap, waterMap]);

  useFrame(({ clock }) => {

    const t = clock.getElapsedTime();

    if (materialRef.current) {
      materialRef.current.uniforms.uTime.value = t;
    }

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

  });

  const globeMaterial = useMemo(() => {

    return new THREE.ShaderMaterial({

      uniforms: {

        uTime: { value: 0 },

        uNightMap: { value: nightMap },
        uBumpMap: { value: bumpMap },
        uWaterMap: { value: waterMap },

        uSunDir: {
          value: new THREE.Vector3(1, 0.3, 0.8).normalize()
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

          float isLand = 1.0 - smoothstep(0.45,0.55,water);

          vec3 land = uLandColor;
          vec3 ocean = uOceanColor;

          land += vec3(0.02,0.03,0.05) * bump;

          vec3 surface = mix(ocean, land, isLand);

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

  }, [nightMap, bumpMap, waterMap]);

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
        <sphereGeometry args={[1,128,128]} />

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
        <sphereGeometry args={[1.055,64,64]} />
      </mesh>

      <mesh
        ref={outerGlowRef}
        material={outerGlowMaterial}
      >
        <sphereGeometry args={[1.12,48,48]} />
      </mesh>

    </group>

  );

};

export default Globe;
