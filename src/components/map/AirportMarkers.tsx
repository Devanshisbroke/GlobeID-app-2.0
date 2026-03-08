import React, { useRef, useMemo, useState, useEffect } from "react";
import { useFrame, useThree } from "@react-three/fiber";
import * as THREE from "three";
import { Html } from "@react-three/drei";
import { airports, latLngToVector3, loadAirportsDataset, type Airport, flightRoutes } from "@/lib/airports";

interface AirportMarkersProps {
  showAirports: boolean;
}

const ZOOM_THRESHOLD = 2.85;

const AirportMarkers: React.FC<AirportMarkersProps> = ({ showAirports }) => {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const glowRef = useRef<THREE.InstancedMesh>(null);
  const haloRef = useRef<THREE.InstancedMesh>(null);
  const [dataVersion, setDataVersion] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);
  const [visibleByZoom, setVisibleByZoom] = useState(false);
  const { camera } = useThree();

  useEffect(() => {
    loadAirportsDataset().then(() => setDataVersion((v) => v + 1));
  }, []);

  const visitedIata = useMemo(() => {
    const set = new Set<string>();
    flightRoutes.forEach((route) => {
      set.add(route.from);
      set.add(route.to);
    });
    return set;
  }, []);

  const markerData = useMemo(
    () =>
      airports.map((airport) => {
        const [x, y, z] = latLngToVector3(airport.lat, airport.lng, 1.01);
        const color = visitedIata.has(airport.iata) ? new THREE.Color("#7aff9a") : new THREE.Color("#00e0ff");
        const normal = new THREE.Vector3(x, y, z).normalize();
        const quaternion = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, 1), normal);
        return { airport, pos: new THREE.Vector3(x, y, z), color, quaternion };
      }),
    [dataVersion, visitedIata]
  );

  useEffect(() => {
    const matrix = new THREE.Matrix4();
    markerData.forEach((item, i) => {
      matrix.makeTranslation(item.pos.x, item.pos.y, item.pos.z);
      meshRef.current?.setMatrixAt(i, matrix);
      glowRef.current?.setMatrixAt(i, matrix);
      haloRef.current?.setMatrixAt(i, matrix);
      meshRef.current?.setColorAt(i, item.color);
      glowRef.current?.setColorAt(i, item.color);
      haloRef.current?.setColorAt(i, new THREE.Color("#00e0ff"));
    });

    meshRef.current?.instanceMatrix && (meshRef.current.instanceMatrix.needsUpdate = true);
    glowRef.current?.instanceMatrix && (glowRef.current.instanceMatrix.needsUpdate = true);
    if (meshRef.current?.instanceColor) meshRef.current.instanceColor.needsUpdate = true;
    if (glowRef.current?.instanceColor) glowRef.current.instanceColor.needsUpdate = true;
    haloRef.current?.instanceMatrix && (haloRef.current.instanceMatrix.needsUpdate = true);
    if (haloRef.current?.instanceColor) haloRef.current.instanceColor.needsUpdate = true;
  }, [markerData]);

  useFrame(({ clock }) => {
    const t = clock.getElapsedTime();
    const camDistance = camera.position.length();
    const show = camDistance < ZOOM_THRESHOLD;
    if (show !== visibleByZoom) setVisibleByZoom(show);

    if (showAirports && show) {
      const matrix = new THREE.Matrix4();
      if (glowRef.current) {
        markerData.forEach((item, idx) => {
          const scale = 1 + Math.sin(t * 3 + idx * 0.2) * 0.2;
          matrix.compose(item.pos, new THREE.Quaternion(), new THREE.Vector3(scale, scale, scale));
          glowRef.current?.setMatrixAt(idx, matrix);
        });
        glowRef.current.instanceMatrix.needsUpdate = true;
      }

      if (haloRef.current) {
        markerData.forEach((item, idx) => {
          const scale = 1 + Math.sin(t * 3 + idx * 0.2) * 0.25;
          matrix.compose(item.pos, item.quaternion, new THREE.Vector3(scale, scale, scale));
          haloRef.current?.setMatrixAt(idx, matrix);
        });
        haloRef.current.instanceMatrix.needsUpdate = true;
      }
    }
  });

  const selectedAirport: Airport | null = selectedIndex !== null ? markerData[selectedIndex]?.airport ?? null : null;
  const selectedPosition = selectedIndex !== null ? markerData[selectedIndex]?.pos : null;

  if (!showAirports || !visibleByZoom || markerData.length === 0) return null;

  return (
    <group>
      <instancedMesh
        ref={meshRef}
        args={[undefined, undefined, markerData.length]}
        onPointerDown={(event) => {
          event.stopPropagation();
          const idx = event.instanceId ?? null;
          setSelectedIndex((prev) => (prev === idx ? null : idx));
          if (idx !== null) {
            const apt = markerData[idx]?.airport;
            if (apt) {
              window.dispatchEvent(new CustomEvent("map-focus", { detail: { lat: apt.lat, lng: apt.lng } }));
            }
          }
        }}
      >
        <sphereGeometry args={[0.0065, 8, 8]} />
        <meshBasicMaterial toneMapped={false} />
      </instancedMesh>

      <instancedMesh ref={glowRef} args={[undefined, undefined, markerData.length]}>
        <sphereGeometry args={[0.013, 8, 8]} />
        <meshBasicMaterial color="#00e6ff" transparent opacity={0.22} depthWrite={false} toneMapped={false} />
      </instancedMesh>

      <instancedMesh ref={haloRef} args={[undefined, undefined, markerData.length]}>
        <circleGeometry args={[0.008, 20]} />
        <meshBasicMaterial color="#00e0ff" transparent opacity={0.25} depthWrite={false} toneMapped={false} side={THREE.DoubleSide} />
      </instancedMesh>

      {selectedAirport && selectedPosition && (
        <group position={selectedPosition}>
          <Html center distanceFactor={3} style={{ pointerEvents: "none" }}>
            <div
              style={{
                background: "rgba(10,12,20,0.92)",
                backdropFilter: "blur(16px)",
                border: "1px solid rgba(100,160,255,0.2)",
                borderRadius: 12,
                padding: "8px 12px",
                minWidth: 130,
              }}
            >
              <p style={{ color: "#fff", fontSize: 12, fontWeight: 700, margin: 0 }}>{selectedAirport.name}</p>
              <p style={{ color: "rgba(255,255,255,0.5)", fontSize: 10, margin: "2px 0 0" }}>
                {selectedAirport.city}, {selectedAirport.country}
              </p>
              <p style={{ color: "hsl(200,90%,60%)", fontSize: 11, fontWeight: 700, margin: "4px 0 0", fontFamily: "monospace" }}>
                {selectedAirport.iata}
              </p>
            </div>
          </Html>
        </group>
      )}
    </group>
  );
};

export default AirportMarkers;
