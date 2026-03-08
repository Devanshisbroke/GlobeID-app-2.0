import React, { useEffect, useMemo, useRef, useState } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { flightRoutes, getAirport, loadAirportsDataset } from "@/lib/airports";
import { loadGlobeGeoData, type CountryPolygon, type PositionTuple } from "@/lib/geoLoader";

interface GlobeProps {
  sunDirection?: THREE.Vector3;
}

const GLOBE_RADIUS = 1;
const OCEAN_FALLBACK = new THREE.Color("#0a2a4a");
const LAND_FALLBACK = new THREE.Color("#1e3a5f");
const VISITED_LAND = new THREE.Color("#3ddc97");
const DEFAULT_SUN = new THREE.Vector3(5, 3, 5).normalize();

const Globe: React.FC<GlobeProps> = ({ sunDirection }) => {
  const meshRef = useRef<THREE.Mesh>(null);
  const materialRef = useRef<THREE.ShaderMaterial | null>(null);
  const cloudRef = useRef<THREE.Mesh>(null);
  const atmosphereRef = useRef<THREE.Mesh>(null);

  const [texturesReady, setTexturesReady] = useState(false);
  const [textureLoadFailed, setTextureLoadFailed] = useState(false);
  const [geoLoadFailed, setGeoLoadFailed] = useState(false);
  const [textures, setTextures] = useState<{ day: THREE.Texture | null; night: THREE.Texture | null; bump: THREE.Texture | null; water: THREE.Texture | null; }>({ day: null, night: null, bump: null, water: null });
  const [landPolygons, setLandPolygons] = useState<PositionTuple[][]>([]);
  const [countryPolygons, setCountryPolygons] = useState<CountryPolygon[]>([]);
  const [countryBorders, setCountryBorders] = useState<PositionTuple[][]>([]);
  const [coastlines, setCoastlines] = useState<PositionTuple[][]>([]);
  const [visitedCountries, setVisitedCountries] = useState<Set<string>>(new Set());

  const resolvedSunDirection = useMemo(() => (sunDirection ? sunDirection.clone().normalize() : DEFAULT_SUN.clone()), [sunDirection]);

  useEffect(() => {
    loadGlobeGeoData(GLOBE_RADIUS)
      .then((geo) => {
        setLandPolygons(geo.landPolygons);
        setCountryPolygons(geo.countryPolygons);
        setCountryBorders(geo.countryBorders);
        setCoastlines(geo.coastlines);
      })
      .catch(() => setGeoLoadFailed(true));

    loadAirportsDataset().then(() => {
      const countries = new Set<string>();
      flightRoutes.forEach((route) => {
        const from = getAirport(route.from);
        const to = getAirport(route.to);
        if (from?.country) countries.add(from.country);
        if (to?.country) countries.add(to.country);
      });
      setVisitedCountries(countries);
    });

    let cancelled = false;
    const loader = new THREE.TextureLoader();
    Promise.allSettled([
      loader.loadAsync("/textures/earth-day.jpg"),
      loader.loadAsync("/textures/earth-night.jpg"),
      loader.loadAsync("/textures/earth-bump.png"),
      loader.loadAsync("/textures/earth-water.png"),
    ]).then((results) => {
      if (cancelled) return;
      if (!results.every((r) => r.status === "fulfilled")) {
        setTextureLoadFailed(true);
        return;
      }
      const [day, night, bump, water] = results.map((r) => (r as PromiseFulfilledResult<THREE.Texture>).value);
      [day, night, bump, water].forEach((tex) => {
        tex.minFilter = THREE.LinearMipmapLinearFilter;
        tex.magFilter = THREE.LinearFilter;
      });
      setTextures({ day, night, bump, water });
      setTexturesReady(true);
    }).catch(() => setTextureLoadFailed(true));

    return () => {
      cancelled = true;
    };
  }, []);

  const globeMaterial = useMemo(() => {
    const material = new THREE.ShaderMaterial({
      uniforms: {
        uDayMap: { value: textures.day },
        uNightMap: { value: textures.night },
        uBumpMap: { value: textures.bump },
        uWaterMap: { value: textures.water },
        uSunDir: { value: resolvedSunDirection.clone() },
        uOceanFallback: { value: OCEAN_FALLBACK },
        uLandFallback: { value: LAND_FALLBACK },
        uAtmoColor: { value: new THREE.Color(0.4, 0.6, 1.0) },
        uHasTextures: { value: texturesReady ? 1.0 : 0.0 },
      },
      vertexShader: `
        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;
        uniform sampler2D uBumpMap;
        uniform float uHasTextures;

        void main() {
          vNormal = normalize(normalMatrix * normal);
          vPosition = position;
          vUv = uv;
          vec3 displaced = position;
          if (uHasTextures > 0.5) {
            float bump = texture2D(uBumpMap, uv).r;
            displaced += normal * bump * 0.01;
          }
          gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D uDayMap;
        uniform sampler2D uNightMap;
        uniform sampler2D uWaterMap;
        uniform vec3 uSunDir;
        uniform vec3 uOceanFallback;
        uniform vec3 uLandFallback;
        uniform vec3 uAtmoColor;
        uniform float uHasTextures;

        varying vec3 vNormal;
        varying vec3 vPosition;
        varying vec2 vUv;

        void main() {
          float sunDot = max(dot(vNormal, normalize(uSunDir)), -0.2);
          float dayFactor = smoothstep(-0.15, 0.35, sunDot);
          float nightFactor = clamp(1.0 - dayFactor, 0.0, 0.45);

          vec3 finalColor = mix(uOceanFallback * 0.8, uOceanFallback * 1.15, dayFactor);

          if (uHasTextures > 0.5) {
            vec3 dayColor = texture2D(uDayMap, vUv).rgb;
            vec3 nightColor = texture2D(uNightMap, vUv).rgb;
            float water = texture2D(uWaterMap, vUv).r;

            vec3 textured = mix(dayColor * 0.95, nightColor * 1.10, nightFactor);
            textured = mix(uLandFallback, textured, 0.85);

            if (water < 0.5) {
              vec3 viewDir = normalize(-vPosition);
              vec3 halfDir = normalize(uSunDir + viewDir);
              float spec = pow(max(dot(vNormal, halfDir), 0.0), 64.0);
              textured += vec3(0.10, 0.18, 0.28) * spec * dayFactor;
            }
            finalColor = textured;
          }

          float fresnel = pow(1.0 - max(dot(vNormal, vec3(0.0, 0.0, 1.0)), 0.0), 2.2);
          finalColor += uAtmoColor * fresnel * 0.35;

          float ambient = 0.35;
          float diffuse = max(sunDot, 0.0) * 0.65;
          finalColor *= (ambient + diffuse);
          finalColor = max(finalColor, uOceanFallback * 0.50);
          finalColor.rgb *= 1.6;

          gl_FragColor = vec4(finalColor, 1.0);
        }
      `,
    });

    materialRef.current = material;
    return material;
  }, [textures, texturesReady, resolvedSunDirection]);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    if (meshRef.current) meshRef.current.rotation.y = Math.sin(t * 0.02) * 0.015;
    if (materialRef.current) {
      materialRef.current.uniforms.uSunDir.value.copy(resolvedSunDirection);
      materialRef.current.uniforms.uHasTextures.value = texturesReady ? 1.0 : 0.0;
    }
    if (cloudRef.current) cloudRef.current.rotation.y += 0.00012;
    if (atmosphereRef.current) atmosphereRef.current.scale.setScalar(1 + Math.sin(t * 0.5) * 0.003);
  });

  const fallbackOnly = textureLoadFailed || geoLoadFailed;

  return (
    <group>
      <mesh>
        <sphereGeometry args={[GLOBE_RADIUS, 128, 128]} />
        <meshStandardMaterial color="#0a2a4a" roughness={0.85} metalness={0} />
      </mesh>

      {!fallbackOnly && (
        <mesh ref={meshRef} material={globeMaterial}>
          <sphereGeometry args={[GLOBE_RADIUS, 128, 128]} />
        </mesh>
      )}

      {countryPolygons.map((country, index) => {
        const polygon = country.positions;
        if (polygon.length < 3) return null;
        const triangles: number[] = [];
        const p0 = polygon[0];
        for (let i = 1; i < polygon.length - 1; i += 1) {
          triangles.push(...p0, ...polygon[i], ...polygon[i + 1]);
        }
        const color = visitedCountries.has(country.name) ? VISITED_LAND : LAND_FALLBACK;

        return (
          <mesh
            key={`country-${index}`}
            onClick={(e) => {
              e.stopPropagation();
              window.dispatchEvent(new CustomEvent("map-focus", { detail: { ...country.centroid } }));
            }}
          >
            <bufferGeometry>
              <bufferAttribute attach="attributes-position" count={triangles.length / 3} array={new Float32Array(triangles)} itemSize={3} />
            </bufferGeometry>
            <meshStandardMaterial color={color} opacity={1} transparent={false} roughness={0.85} metalness={0} side={THREE.DoubleSide} />
          </mesh>
        );
      })}

      {coastlines.map((polygon, index) => {
        if (polygon.length < 2) return null;
        const points = polygon.flatMap((p, i) => (i === polygon.length - 1 ? [p[0], p[1], p[2], polygon[0][0], polygon[0][1], polygon[0][2]] : [p[0], p[1], p[2], polygon[i + 1][0], polygon[i + 1][1], polygon[i + 1][2]]));
        return (
          <lineSegments key={`land-outline-${index}`}>
            <bufferGeometry>
              <bufferAttribute attach="attributes-position" count={points.length / 3} array={new Float32Array(points)} itemSize={3} />
            </bufferGeometry>
            <lineBasicMaterial color="#00e6ff" transparent opacity={0.35} blending={THREE.AdditiveBlending} depthWrite={false} />
          </lineSegments>
        );
      })}

      {countryBorders.map((border, index) => {
        if (border.length < 2) return null;
        const points = border.flatMap((p, i) => (i === border.length - 1 ? [p[0], p[1], p[2], border[0][0], border[0][1], border[0][2]] : [p[0], p[1], p[2], border[i + 1][0], border[i + 1][1], border[i + 1][2]]));
        return (
          <lineSegments key={`border-${index}`}>
            <bufferGeometry>
              <bufferAttribute attach="attributes-position" count={points.length / 3} array={new Float32Array(points)} itemSize={3} />
            </bufferGeometry>
            <lineBasicMaterial color="#00dcff" transparent opacity={0.6} depthWrite={false} />
          </lineSegments>
        );
      })}

      {!fallbackOnly && (
        <>
          <mesh ref={cloudRef}>
            <sphereGeometry args={[GLOBE_RADIUS + 0.006, 64, 64]} />
            <meshStandardMaterial color="#d7ebff" transparent opacity={0.08} depthWrite={false} />
          </mesh>
          <mesh ref={atmosphereRef}>
            <sphereGeometry args={[GLOBE_RADIUS + 0.06, 64, 64]} />
            <meshBasicMaterial color="#4f88ff" transparent opacity={0.14} side={THREE.BackSide} depthWrite={false} />
          </mesh>
        </>
      )}
    </group>
  );
};

export default Globe;
