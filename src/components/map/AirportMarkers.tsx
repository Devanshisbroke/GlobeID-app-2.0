import React, { useRef, useMemo, useState, useCallback } from "react";
import { useFrame, type ThreeEvent } from "@react-three/fiber";
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
  const glowRef = useRef<THREE.Mesh>(null);
  const [x, y, z] = useMemo(() => latLngToVector3(airport.lat, airport.lng, 1.005), [airport]);

  const isUS = airport.country === "United States";
  const dotColor = useMemo(
    () => new THREE.Color(isUS ? "#7aff9a" : "#00e0ff"),
    [isUS]
  );

  useFrame(({ clock }) => {
    if (glowRef.current) {
      const t = clock.getElapsedTime();
      const phase = (t * 1.2 + index * 0.4) % (Math.PI * 2);
      const scale = 1 + Math.sin(phase) * 0.35;
      glowRef.current.scale.setScalar(scale);
      (glowRef.current.material as THREE.MeshBasicMaterial).opacity = 0.12 + Math.sin(phase) * 0.08;
    }
  });

  const handleClick = useCallback((e: ThreeEvent<MouseEvent>) => {
    e.stopPropagation();
    onSelect(selected ? null : airport.iata);
  }, [airport.iata, selected, onSelect]);

  return (
    <group position={[x, y, z]}>
      {/* Core dot */}
      <mesh onClick={handleClick}>
        <sphereGeometry args={[0.006, 10, 10]} />
        <meshBasicMaterial color={dotColor} toneMapped={false} />
      </mesh>
      {/* Pulse glow */}
      <mesh ref={glowRef}>
        <sphereGeometry args={[0.012, 8, 8]} />
        <meshBasicMaterial color={dotColor} transparent opacity={0.15} toneMapped={false} depthWrite={false} />
      </mesh>
      {/* Glass tooltip */}
      {selected && (
        <Html center distanceFactor={3} style={{ pointerEvents: "none" }}>
          <div
            style={{
              background: "rgba(8,10,18,0.88)",
              backdropFilter: "blur(20px)",
              WebkitBackdropFilter: "blur(20px)",
              border: "1px solid rgba(120,180,255,0.15)",
              borderRadius: 14,
              padding: "10px 14px",
              minWidth: 140,
              boxShadow: "0 8px 32px rgba(0,0,0,0.6), 0 0 20px rgba(0,224,255,0.08)",
            }}
          >
            <p style={{ color: "#fff", fontSize: 12, fontWeight: 700, margin: 0, letterSpacing: "-0.01em" }}>
              {airport.name}
            </p>
            <p style={{ color: "rgba(255,255,255,0.45)", fontSize: 10, margin: "3px 0 0", letterSpacing: "0.03em" }}>
              {airport.city}, {airport.country}
            </p>
            <p style={{
              color: "#00e0ff",
              fontSize: 11,
              fontWeight: 700,
              margin: "5px 0 0",
              fontFamily: "monospace",
              letterSpacing: "0.12em",
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
