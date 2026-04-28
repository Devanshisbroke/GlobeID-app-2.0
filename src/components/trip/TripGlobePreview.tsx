import React, { Suspense, useMemo, useRef } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import * as THREE from "three";
import Globe from "@/components/map/Globe";
import Starfield from "@/components/map/Starfield";
import { getAirport, latLngToVector3, createArcPoints } from "@/lib/airports";
import type { TripLeg } from "@shared/types/lifecycle";
import { isMobileOrCapacitor } from "@/hooks/useMobileDetect";

const GLOBE_R = 1;

interface ArcMeshProps {
  fromIata: string;
  toIata: string;
  emphasis: "next" | "past" | "future";
}

const ArcMesh: React.FC<ArcMeshProps> = ({ fromIata, toIata, emphasis }) => {
  const ref = useRef<THREE.Line>(null);
  const planeRef = useRef<THREE.Mesh>(null);
  const progress = useRef(0);

  const data = useMemo(() => {
    const fromA = getAirport(fromIata);
    const toA = getAirport(toIata);
    if (!fromA || !toA) return null;
    const f = latLngToVector3(fromA.lat, fromA.lng, GLOBE_R);
    const t = latLngToVector3(toA.lat, toA.lng, GLOBE_R);
    const arc = createArcPoints(f, t, 90, 0.22);
    const vecs = arc.map((p) => new THREE.Vector3(...p));
    const curve = new THREE.CatmullRomCurve3(vecs);
    const flat = vecs.flatMap((v) => [v.x, v.y, v.z]);
    return {
      curve,
      positions: new Float32Array(flat),
      count: vecs.length,
    };
  }, [fromIata, toIata]);

  useFrame((_, delta) => {
    if (!data) return;
    if (emphasis === "next" && planeRef.current) {
      progress.current = (progress.current + delta * 0.06) % 1;
      const pos = data.curve.getPoint(progress.current);
      const ahead = data.curve.getPoint(Math.min(progress.current + 0.01, 1));
      planeRef.current.position.copy(pos);
      planeRef.current.lookAt(ahead);
    }
  });

  if (!data) return null;

  const colorMap: Record<typeof emphasis, string> = {
    next: "#3fa9ff",
    past: "#5a7fa8",
    future: "#3fa9ff",
  };
  const opacity = emphasis === "past" ? 0.4 : 0.95;

  return (
    <group>
      {/* Arc */}
      <line ref={ref}>
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            args={[data.positions, 3]}
            count={data.count}
          />
        </bufferGeometry>
        <lineBasicMaterial
          color={colorMap[emphasis]}
          transparent
          opacity={opacity}
          linewidth={2}
        />
      </line>
      {/* Animated plane head on the highlighted arc only */}
      {emphasis === "next" ? (
        <mesh ref={planeRef}>
          <sphereGeometry args={[0.012, 12, 12]} />
          <meshBasicMaterial color="#ffaa44" />
        </mesh>
      ) : null}
      {/* Endpoint markers */}
      <EndpointMarker iata={fromIata} color={colorMap[emphasis]} />
      <EndpointMarker iata={toIata} color={colorMap[emphasis]} />
    </group>
  );
};

const EndpointMarker: React.FC<{ iata: string; color: string }> = ({ iata, color }) => {
  const a = getAirport(iata);
  if (!a) return null;
  const [x, y, z] = latLngToVector3(a.lat, a.lng, GLOBE_R + 0.005);
  return (
    <mesh position={[x, y, z]}>
      <sphereGeometry args={[0.014, 12, 12]} />
      <meshBasicMaterial color={color} />
    </mesh>
  );
};

interface CameraOrbiterProps {
  targetLat: number;
  targetLng: number;
}

const CameraOrbiter: React.FC<CameraOrbiterProps> = ({ targetLat, targetLng }) => {
  const angle = useRef(0);
  const target = useMemo(() => {
    const [tx, ty, tz] = latLngToVector3(targetLat, targetLng, 1);
    return new THREE.Vector3(tx, ty, tz);
  }, [targetLat, targetLng]);

  useFrame(({ camera }, delta) => {
    angle.current += delta * 0.08;
    const radius = 2.6;
    const ny = target.y * 0.4 + 0.4;
    // Orbit slowly around the destination's normal axis.
    const baseDir = target.clone().normalize();
    // Build an orthonormal basis on the surface normal.
    const up = new THREE.Vector3(0, 1, 0);
    const right = new THREE.Vector3().crossVectors(baseDir, up).normalize();
    if (right.lengthSq() < 0.001) right.set(1, 0, 0);
    const forward = new THREE.Vector3().crossVectors(right, baseDir).normalize();
    const offset = right
      .clone()
      .multiplyScalar(Math.sin(angle.current) * 0.7)
      .add(forward.clone().multiplyScalar(Math.cos(angle.current) * 0.7));
    const pos = baseDir.clone().multiplyScalar(radius).add(offset);
    camera.position.set(pos.x, pos.y + ny, pos.z);
    camera.lookAt(0, 0, 0);
  });
  return null;
};

export interface TripGlobePreviewProps {
  legs: TripLeg[];
  /** ISO date YYYY-MM-DD; defaults to today UTC. */
  today?: string;
  className?: string;
}

const TripGlobePreview: React.FC<TripGlobePreviewProps> = ({
  legs,
  today,
  className,
}) => {
  const todayDate = today ?? new Date().toISOString().slice(0, 10);
  const mobile = useMemo(() => isMobileOrCapacitor(), []);

  // Pick the leg to focus the camera on:
  //  - first upcoming leg, else last past leg
  const focusLeg = useMemo(() => {
    const upcoming = legs.find((l) => l.date >= todayDate);
    if (upcoming) return upcoming;
    const sortedDesc = [...legs].sort((a, b) => b.date.localeCompare(a.date));
    return sortedDesc[0] ?? null;
  }, [legs, todayDate]);

  const focusAirport = focusLeg ? getAirport(focusLeg.toIata) : null;

  if (legs.length === 0 || !focusAirport) {
    return (
      <div
        className={`rounded-2xl border border-border bg-card flex items-center justify-center text-sm text-muted-foreground py-12 ${
          className ?? ""
        }`}
      >
        Save flights on this trip to preview the path on the globe.
      </div>
    );
  }

  return (
    <div
      className={`rounded-2xl border border-border bg-[#020617] overflow-hidden relative ${
        className ?? ""
      }`}
      style={{ aspectRatio: "16 / 10" }}
      data-trip-preview
    >
      <Canvas
        camera={{ position: [0, 0.5, 2.8], fov: 40, near: 0.1, far: 50 }}
        dpr={mobile ? [1, 1.5] : [1, 2]}
        gl={{
          antialias: !mobile,
          alpha: true,
          powerPreference: "high-performance",
          stencil: false,
        }}
        style={{ touchAction: "pan-y" }}
        performance={{ min: 0.4 }}
      >
        <Suspense fallback={null}>
          <ambientLight intensity={0.25} color="#b8c9e0" />
          <directionalLight
            position={[5, 2, 4]}
            intensity={1.2}
            color="#fff5e0"
          />
          <Starfield count={mobile ? 800 : 2200} />
          <Globe />

          {legs.map((leg) => {
            const emphasis: ArcMeshProps["emphasis"] =
              leg.id === focusLeg?.id
                ? "next"
                : leg.date < todayDate
                ? "past"
                : "future";
            return (
              <ArcMesh
                key={leg.id}
                fromIata={leg.fromIata}
                toIata={leg.toIata}
                emphasis={emphasis}
              />
            );
          })}

          <CameraOrbiter
            targetLat={focusAirport.lat}
            targetLng={focusAirport.lng}
          />
        </Suspense>
      </Canvas>
      <div className="absolute bottom-2 left-3 right-3 text-[10px] text-white/60 flex items-center justify-between pointer-events-none">
        <span className="font-mono">
          Focus · {focusLeg?.fromIata}–{focusLeg?.toIata}
        </span>
        <span>
          {legs.length} arc{legs.length === 1 ? "" : "s"}
        </span>
      </div>
    </div>
  );
};

export default TripGlobePreview;
