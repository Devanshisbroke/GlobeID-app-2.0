import React, { Suspense, useRef } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import Globe from "./Globe";
import Starfield from "./Starfield";
import FlightArcs from "./FlightArcs";
import AirportMarkers from "./AirportMarkers";
import UserLocation from "./UserLocation";

interface GlobeSceneProps {
  showHistory: boolean;
  showAirports: boolean;
  userLat: number;
  userLng: number;
}

const GlobeScene: React.FC<GlobeSceneProps> = ({
  showHistory,
  showAirports,
  userLat,
  userLng,
}) => {
  const controlsRef = useRef<any>(null);

  return (
    <Canvas
      camera={{ position: [0, 0, 2.8], fov: 45, near: 0.1, far: 50 }}
      dpr={[1, 2]}
      gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
      style={{ background: "transparent" }}
      performance={{ min: 0.5 }}
    >
      <Suspense fallback={null}>
        {/* Ambient lighting */}
        <ambientLight intensity={0.15} />
        <directionalLight position={[5, 3, 5]} intensity={0.3} color="hsl(200, 90%, 80%)" />

        {/* Stars */}
        <Starfield count={1500} />

        {/* Globe */}
        <Globe />

        {/* Flight paths */}
        <FlightArcs showHistory={showHistory} />

        {/* Airport markers */}
        <AirportMarkers showAirports={showAirports} />

        {/* User location */}
        <UserLocation lat={userLat} lng={userLng} />

        {/* Controls */}
        <OrbitControls
          ref={controlsRef}
          enablePan={false}
          enableDamping
          dampingFactor={0.08}
          rotateSpeed={0.5}
          zoomSpeed={0.8}
          minDistance={1.5}
          maxDistance={5}
          autoRotate
          autoRotateSpeed={0.3}
        />
      </Suspense>
    </Canvas>
  );
};

export default GlobeScene;
