import React, { useRef, useMemo, useState, useCallback } from "react";
import { useFrame, useThree } from "@react-three/fiber";
import * as THREE from "three";
import { Html } from "@react-three/drei";
import { airports, latLngToVector3 } from "@/lib/airports";

interface AirportMarkersProps {
  showAirports: boolean;
}

const AirportMarker: React.FC<{
  airport: typeof airports[0];
  index: number;
  onSelect: (iata: string | null) => void;
  selected: boolean;
}> = ({ airport, index, onSelect, selected }) => {
  const meshRef = useRef<THREE.Mesh>(null);
  const glowRef = useRef<THREE.Mesh>(null);
  const [x, y, z] = useMemo(() => latLngToVector3(airport.lat, airport.lng, 1.005), [airport]);

  const isUS = airport.country === "United States";
  const dotColor = useMemo(
    () => new THREE.Color(isUS ? "hsl(36, 92%, 58%)" : "hsl(200, 90%, 60%)"),
    [isUS]
  );

  useFrame(({ clock }) => {
    if (glowRef.current) {
      const t = clock.getElapsedTime();
      const phase = (t * 1.5 + index * 0.3) % (Math.PI * 2);
      const scale = 1 + Math.sin(phase) * 0.4;
      glowRef.current.scale.setScalar(scale);
      (glowRef.current.material as THREE.MeshBasicMaterial).opacity = 0.15 + Math.sin(phase) * 0.1;
    }
  });

  const handleClick = useCallback((e: any) => {
    e.stopPropagation();
    onSelect(selected ? null : airport.iata);
  }, [airport.iata, selected, onSelect]);

  return (
    <group position={[x, y, z]}>
      {/* Core dot */}
      <mesh ref={meshRef} onClick={handleClick}>
        <sphereGeometry args={[0.007, 10, 10]} />
        <meshBasicMaterial color={dotColor} toneMapped={false} />
      </mesh>
      {/* Pulse glow */}
      <mesh ref={glowRef}>
        <sphereGeometry args={[0.014, 8, 8]} />
        <meshBasicMaterial color={dotColor} transparent opacity={0.2} toneMapped={false} depthWrite={false} />
      </mesh>
      {/* Tooltip */}
      {selected && (
        <Html
          center
          distanceFactor={3}
          style={{ pointerEvents: "none" }}
        >
          <div
            style={{
              background: "rgba(10,12,20,0.92)",
              backdropFilter: "blur(16px)",
              border: "1px solid rgba(100,160,255,0.2)",
              borderRadius: 12,
              padding: "8px 12px",
              minWidth: 130,
              boxShadow: "0 4px 20px rgba(0,0,0,0.5), 0 0 15px rgba(100,160,255,0.15)",
            }}
          >
            <p style={{ color: "#fff", fontSize: 12, fontWeight: 700, margin: 0, letterSpacing: "-0.02em" }}>
              {airport.name}
            </p>
            <p style={{ color: "rgba(255,255,255,0.5)", fontSize: 10, margin: "2px 0 0", letterSpacing: "0.05em" }}>
              {airport.city}, {airport.country}
            </p>
            <p style={{
              color: "hsl(200,90%,60%)",
              fontSize: 11,
              fontWeight: 700,
              margin: "4px 0 0",
              fontFamily: "monospace",
              letterSpacing: "0.1em",
            }}>
              {airport.iata}
            </p>
          </div>
        </Html>
      )}
    </group>
  );
};

const AirportMarkers: React.FC<AirportMarkersProps> = ({ showAirports }) => {
  const [selectedIata, setSelectedIata] = useState<string | null>(null);

  if (!showAirports) return null;

  return (
    <group>
      {airports.map((airport, i) => (
        <AirportMarker
          key={airport.iata}
          airport={airport}
          index={i}
          onSelect={setSelectedIata}
          selected={selectedIata === airport.iata}
        />
      ))}
    </group>
  );
};

export default AirportMarkers;
