import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { latLngToVector3 } from "@/lib/airports";
import { getHubs, destinations } from "@/lib/destinationAnalytics";

const GLOBE_RADIUS = 1.005;

interface HeatPoint {
  position: THREE.Vector3;
  intensity: number;
  isHub: boolean;
}

const GlobalHeatmap: React.FC = () => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const points: HeatPoint[] = useMemo(() => {
    return destinations.slice(0, 30).map((d) => {
      const airport = { lat: 0, lng: 0 };
      // Look up lat/lng from airports
      const { latLngToVector3: _ , ...rest } = require("@/lib/airports");
      return null;
    }).filter(Boolean) as HeatPoint[];
  }, []);

  // Simplified: render hub glows as point lights
  const hubs = useMemo(() => getHubs(), []);

  return (
    <group>
      {hubs.map((hub) => {
        const airports = require("@/lib/airports").airports;
        const airport = airports.find((a: any) => a.iata === hub.iata);
        if (!airport) return null;
        const pos = latLngToVector3(airport.lat, airport.lng, GLOBE_RADIUS + 0.01);
        const intensity = hub.popularity / 100;
        return (
          <pointLight
            key={hub.iata}
            position={pos}
            color={new THREE.Color().setHSL(0.55, 0.8, 0.6)}
            intensity={intensity * 0.3}
            distance={0.3}
          />
        );
      })}
    </group>
  );
};

export default GlobalHeatmap;
