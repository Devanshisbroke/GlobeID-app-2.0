import React, { Suspense } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import Globe from "./Globe";
import Starfield from "./Starfield";
import FlightArcs from "./FlightArcs";
import AirportMarkers from "./AirportMarkers";
import UserLocation from "./UserLocation";
import GlobalFlightFlows from "./GlobalFlightFlows";
import TravelParticles from "./TravelParticles";
import PassengerParticles from "./PassengerParticles";
import AirTrafficLayer from "./AirTrafficLayer";
import RegionalDensity from "./RegionalDensity";
import TravelStreams from "./TravelStreams";
import PassengerNetwork from "./PassengerNetwork";
import DestinationMarkers from "./DestinationMarkers";
import LandmarkMarkers from "./LandmarkMarkers";
import ExplorerPaths from "./ExplorerPaths";

interface GlobeSceneProps {
  showHistory: boolean;
  showAirports: boolean;
  userLat: number;
  userLng: number;
  showIntelligence?: boolean;
  showSimulation?: boolean;
  simSpeed?: number;
  showExplorer?: boolean;
  explorerPathId?: string;
  discoveredIds?: string[];
}

const GlobeScene: React.FC<GlobeSceneProps> = ({
  showHistory,
  showAirports,
  userLat,
  userLng,
  showIntelligence = true,
  showSimulation = false,
  simSpeed = 1,
  showExplorer = false,
  explorerPathId,
  discoveredIds = [],
}) => {
  return (
    <Canvas
      camera={{ position: [0, 0.5, 2.8], fov: 40, near: 0.1, far: 50 }}
      dpr={[1, 2]}
      gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
      style={{ background: "#020617" }}
      performance={{ min: 0.5 }}
    >
      <Suspense fallback={null}>
        {/* Lighting — dims for simulation/explorer modes */}
        <ambientLight intensity={showSimulation ? 0.15 : showExplorer ? 0.2 : 0.25} color="#b8c9e0" />
        <directionalLight position={[5, 2, 4]} intensity={showSimulation ? 0.8 : showExplorer ? 0.9 : 1.2} color="#fff5e0" />
        <directionalLight position={[-3, -1, 2]} intensity={0.15} color="#6b8cc7" />
        <pointLight position={[0, 1.5, 3]} intensity={0.15} color="#78b4ff" distance={8} />

        <Starfield count={4000} />
        <Globe />
        <FlightArcs showHistory={showHistory} />

        {/* Intelligence layers */}
        {showIntelligence && (
          <>
            <GlobalFlightFlows count={50} />
            <TravelParticles />
          </>
        )}

        {/* Simulation layers */}
        {showSimulation && (
          <>
            <PassengerParticles count={100} speed={simSpeed} />
            <AirTrafficLayer count={60} speed={simSpeed} />
            <RegionalDensity />
            <TravelStreams />
            <PassengerNetwork />
          </>
        )}

        {/* Explorer layers */}
        {showExplorer && (
          <>
            <DestinationMarkers discoveredIds={discoveredIds} />
            <LandmarkMarkers />
            <ExplorerPaths activePathId={explorerPathId} />
          </>
        )}

        <AirportMarkers showAirports={showAirports} />
        <UserLocation lat={userLat} lng={userLng} />

        <OrbitControls
          enablePan={false}
          enableDamping
          dampingFactor={0.08}
          rotateSpeed={0.35}
          zoomSpeed={0.5}
          minDistance={1.5}
          maxDistance={4.2}
          autoRotate
          autoRotateSpeed={showExplorer ? 0.06 : showSimulation ? 0.08 : 0.15}
          enableRotate
          maxPolarAngle={Math.PI * 0.82}
          minPolarAngle={Math.PI * 0.18}
        />
      </Suspense>
    </Canvas>
  );
};

export default GlobeScene;
