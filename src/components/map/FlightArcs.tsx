import React, { useRef, useMemo, useEffect, useState } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import {
  flightRoutes,
  getAirport,
  loadAirportsDataset,
  latLngToVector3,
  createArcPoints,
  type FlightRoute,
} from "@/lib/airports";

interface FlightArcsProps {
  showHistory: boolean;
}

const ARC_DEFAULT = new THREE.Color("#3fa9ff");
const ARC_ACTIVE = new THREE.Color("#ff7a00");

const FlightArc: React.FC<{ route: FlightRoute; radius: number; dataVersion: number }> = ({ route, radius, dataVersion }) => {
  const coreLineRef = useRef<THREE.Line>(null);
  const planeRef = useRef<THREE.Group>(null);
  const trailRefs = useRef(Array.from({ length: 8 }, () => React.createRef<THREE.Mesh>()));
  const progressRef = useRef(Math.random());

  const fromAirport = getAirport(route.from);
  const toAirport = getAirport(route.to);

  const { curve, color, glowColor, lineDistances, distanceFactor, midpoint } = useMemo(() => {
    if (!fromAirport || !toAirport) {
      return {
        curve: null,
        color: ARC_DEFAULT,
        glowColor: ARC_DEFAULT,
        lineDistances: new Float32Array(),
        distanceFactor: 1,
        midpoint: null as { lat: number; lng: number } | null,
      };
    }

    const from3D = latLngToVector3(fromAirport.lat, fromAirport.lng, radius);
    const to3D = latLngToVector3(toAirport.lat, toAirport.lng, radius);
    const arcPts = createArcPoints(from3D, to3D, 120, 0.06);
    const vectors = arcPts.map((p) => new THREE.Vector3(...p));
    const c = new THREE.CatmullRomCurve3(vectors);

    const dists: number[] = [0];
    for (let i = 1; i < vectors.length; i += 1) dists[i] = dists[i - 1] + vectors[i - 1].distanceTo(vectors[i]);

    const dist = Math.hypot(fromAirport.lat - toAirport.lat, fromAirport.lng - toAirport.lng);
    const factor = Math.max(0.6, Math.min(2.1, dist / 60));

    return {
      curve: c,
      color: route.type === "upcoming" || route.type === "current" ? ARC_ACTIVE : ARC_DEFAULT,
      glowColor: route.type === "upcoming" || route.type === "current" ? new THREE.Color("#ffb066") : new THREE.Color("#84c6ff"),
      lineDistances: new Float32Array(dists),
      distanceFactor: factor,
      midpoint: { lat: (fromAirport.lat + toAirport.lat) / 2, lng: (fromAirport.lng + toAirport.lng) / 2 },
    };
  }, [fromAirport, toAirport, radius, route.type, dataVersion]);

  useFrame((_, delta) => {
    if (!curve) return;

    if (coreLineRef.current) {
      const mat = coreLineRef.current.material as THREE.LineDashedMaterial;
      mat.dashOffset -= delta * 0.5;
    }

    const isActive = route.type === "upcoming" || route.type === "current";
    if (isActive && planeRef.current) {
      progressRef.current = (progressRef.current + delta * 0.06 * distanceFactor) % 1;
      const pos = curve.getPoint(progressRef.current);
      const ahead = curve.getPoint((progressRef.current + 0.01) % 1);
      planeRef.current.position.copy(pos);
      planeRef.current.lookAt(ahead);

      trailRefs.current.forEach((ref, idx) => {
        const t = (progressRef.current - idx * 0.018 + 1) % 1;
        const trailPos = curve.getPoint(t);
        if (ref.current) {
          ref.current.position.copy(trailPos);
          (ref.current.material as THREE.MeshBasicMaterial).opacity = Math.max(0.02, 0.22 - idx * 0.02);
        }
      });
    }
  });

  if (!curve) return null;

  const points = curve.getPoints(120);
  const posArray = new Float32Array(points.flatMap((p) => [p.x, p.y, p.z]));
  const isActive = route.type === "upcoming" || route.type === "current";

  return (
    <group>
      <line
        onClick={(e) => {
          e.stopPropagation();
          if (midpoint) window.dispatchEvent(new CustomEvent("map-focus", { detail: midpoint }));
        }}
      >
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArray} itemSize={3} />
        </bufferGeometry>
        <lineBasicMaterial color={glowColor} transparent opacity={isActive ? 0.45 : 0.28} blending={THREE.AdditiveBlending} depthWrite={false} />
      </line>

      <line ref={coreLineRef}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" count={points.length} array={posArray} itemSize={3} />
          <bufferAttribute attach="attributes-lineDistance" count={lineDistances.length} array={lineDistances} itemSize={1} />
        </bufferGeometry>
        <lineDashedMaterial color={color} dashSize={0.04} gapSize={0.017} transparent opacity={isActive ? 0.98 : 0.7} />
      </line>

      {isActive && (
        <>
          <group ref={planeRef}>
            <mesh rotation={[Math.PI / 2, 0, 0]}>
              <coneGeometry args={[0.008, 0.025, 3]} />
              <meshBasicMaterial color="#f7fafc" toneMapped={false} />
            </mesh>
          </group>
          {trailRefs.current.map((ref, idx) => (
            <mesh ref={ref} key={`trail-${idx}`}>
              <sphereGeometry args={[0.007 - idx * 0.0005, 6, 6]} />
              <meshBasicMaterial color={glowColor} transparent opacity={0.2} depthWrite={false} toneMapped={false} />
            </mesh>
          ))}
        </>
      )}
    </group>
  );
};

const FlightArcs: React.FC<FlightArcsProps> = ({ showHistory }) => {
  const [dataVersion, setDataVersion] = useState(0);

  useEffect(() => {
    loadAirportsDataset().then(() => setDataVersion((v) => v + 1));
  }, []);

  const routes = showHistory ? flightRoutes : flightRoutes.filter((r) => r.type === "upcoming" || r.type === "current");

  return (
    <group>
      {routes.map((route) => (
        <FlightArc key={route.id} route={route} radius={1.002} dataVersion={dataVersion} />
      ))}
    </group>
  );
};

export default FlightArcs;
