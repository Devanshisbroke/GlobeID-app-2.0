import React, { Suspense, useMemo, useRef, useEffect, useState } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import * as THREE from "three";
import Globe from "./Globe";
import Coastlines from "./Coastlines";
import Starfield from "./Starfield";
import FlightArcs from "./FlightArcs";
import AirportMarkers from "./AirportMarkers";
import UserLocation from "./UserLocation";
import { latLngToVector3 } from "@/lib/airports";

interface GlobeSceneProps {
  showHistory: boolean;
  showAirports: boolean;
  userLat: number;
  userLng: number;
}

const CameraRig: React.FC<{ targetLatLng: { lat: number; lng: number } | null }> = ({ targetLatLng }) => {
  const controlsRef = useRef<any>(null);
  const desiredTarget = useRef(new THREE.Vector3(0, 0, 0));
  const desiredPosition = useRef(new THREE.Vector3(0, 0.4, 2.6));

  useEffect(() => {
    if (!targetLatLng) return;
    const [x, y, z] = latLngToVector3(targetLatLng.lat, targetLatLng.lng, 1.0);
    desiredTarget.current.set(x, y, z);
    desiredPosition.current.set(x * 2.2, y * 1.8 + 0.15, z * 2.2);
  }, [targetLatLng]);

  useFrame(({ camera }, delta) => {
    const t = Math.min(1, delta / 1.5 * 60);
    camera.position.lerp(desiredPosition.current, t * 0.06);
    if (controlsRef.current) {
      controlsRef.current.target.lerp(desiredTarget.current, t * 0.08);
      controlsRef.current.update();
    }
  });

  return (
    <OrbitControls
      ref={controlsRef}
      enablePan={false}
      enableDamping
      dampingFactor={0.05}
      rotateSpeed={0.4}
      zoomSpeed={0.6}
      minDistance={1.4}
      maxDistance={4.5}
      autoRotate
      autoRotateSpeed={0.2}
      enableRotate
      maxPolarAngle={Math.PI * 0.85}
      minPolarAngle={Math.PI * 0.15}
    />
  );
};

const GlobeScene: React.FC<GlobeSceneProps> = ({ showHistory, showAirports, userLat, userLng }) => {
  const [focusTarget, setFocusTarget] = useState<{ lat: number; lng: number } | null>(null);
  const sunDirection = useMemo(() => new THREE.Vector3(5, 3, 5).normalize(), []);

  useEffect(() => {
    const handler = (event: Event) => {
      const detail = (event as CustomEvent<{ lat: number; lng: number }>).detail;
      if (detail && Number.isFinite(detail.lat) && Number.isFinite(detail.lng)) setFocusTarget(detail);
    };
    window.addEventListener("map-focus", handler as EventListener);
    return () => window.removeEventListener("map-focus", handler as EventListener);
  }, []);

  return (
    <Canvas
      camera={{ position: [0, 0.4, 2.6], fov: 42, near: 0.1, far: 50 }}
      dpr={[1, 2]}
      gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
      style={{ background: "#020617" }}
      performance={{ min: 0.5 }}
    >
      <Suspense fallback={null}>
        <ambientLight intensity={0.25} />
        <hemisphereLight skyColor="#6fa8ff" groundColor="#0a1a2a" intensity={0.6} />
        <directionalLight position={[5, 3, 5]} intensity={1.2} />
        <directionalLight position={[-4, -1, 2]} intensity={0.18} color="hsl(220, 60%, 70%)" />
        <pointLight position={[0, 2, 3]} intensity={0.15} color="hsl(195, 90%, 70%)" distance={8} />

        <Starfield count={4000} />
        <Globe sunDirection={sunDirection} />
        <Coastlines />
        <FlightArcs showHistory={showHistory} />
        <AirportMarkers showAirports={showAirports} />
        <UserLocation lat={userLat} lng={userLng} />

        <CameraRig targetLatLng={focusTarget} />
      </Suspense>
    </Canvas>
  );
};

export default GlobeScene;
