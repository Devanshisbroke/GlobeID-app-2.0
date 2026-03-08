import React, { Suspense } from "react";
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
  return (
    <Canvas
      camera={{ position: [0, 0.4, 2.6], fov: 42, near: 0.1, far: 50 }}
      dpr={[1, 2]}
      gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
      style={{ background: "transparent" }}
      performance={{ min: 0.5 }}
    >
      <Suspense fallback={null}>
        {/* Cinematic lighting — sun simulation */}
        <ambientLight intensity={0.06} />
        <directionalLight position={[5, 2, 4]} intensity={0.35} color="hsl(40, 90%, 95%)" />
        <directionalLight position={[-4, -1, 2]} intensity={0.06} color="hsl(220, 60%, 70%)" />
        <pointLight position={[0, 2, 3]} intensity={0.12} color="hsl(195, 90%, 70%)" distance={8} />

        {/* Stars + nebula */}
        <Starfield count={2500} />

        {/* Globe */}
        <Globe />

        {/* Flight paths */}
        <FlightArcs showHistory={showHistory} />

        {/* Airport markers */}
        <AirportMarkers showAirports={showAirports} />

        {/* User location */}
        <UserLocation lat={userLat} lng={userLng} />

        {/* Controls — smooth damped */}
        <OrbitControls
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
      </Suspense>
    </Canvas>
  );
};

export default GlobeScene;
