import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { latLngToVector3, createArcPoints } from "@/lib/airports";

const GLOBE_R = 1;

/** Continental coordinates (approx center) */
const CONTINENT_CENTERS: [string, number, number][] = [
  ["NA", 39.8, -98.5],
  ["EU", 50.1, 9.7],
  ["AS", 34.0, 100.6],
  ["ME", 25.3, 51.0],
  ["OC", -25.3, 134.8],
  ["SA", -14.2, -51.9],
  ["AF", 1.6, 17.4],
];

/** Major intercontinental streams */
const STREAMS: [number, number, string][] = [
  [0, 1, "#38bdf8"], // NA → EU
  [1, 2, "#818cf8"], // EU → AS
  [2, 3, "#facc15"], // AS → ME
  [0, 2, "#34d399"], // NA → AS
  [1, 3, "#fb923c"], // EU → ME
  [2, 4, "#a78bfa"], // AS → OC
  [0, 5, "#f87171"], // NA → SA
  [1, 6, "#fbbf24"], // EU → AF
];

const StreamArc: React.FC<{ from: [number, number, number]; to: [number, number, number]; color: string; idx: number }> = ({ from, to, color, idx }) => {
  const lineRef = useRef<THREE.Line>(null);
  const progress = useRef(Math.random());

  const geo = useMemo(() => {
    const pts = createArcPoints(from, to, 80, 0.35);
    return new THREE.BufferGeometry().setFromPoints(pts.map((p) => new THREE.Vector3(...p)));
  }, [from, to]);

  const mat = useMemo(() => new THREE.LineBasicMaterial({
    color,
    transparent: true,
    opacity: 0.25,
    linewidth: 1,
  }), [color]);

  useFrame((_, delta) => {
    if (!lineRef.current) return;
    progress.current = (progress.current + delta * 0.04) % 1;
    (lineRef.current.material as THREE.LineBasicMaterial).opacity = 0.12 + Math.sin(progress.current * Math.PI) * 0.2;
  });

  return <primitive ref={lineRef} object={new THREE.Line(geo, mat)} />;
};

const TravelStreams: React.FC = () => {
  const centers = useMemo(() =>
    CONTINENT_CENTERS.map(([, lat, lng]) => latLngToVector3(lat, lng, GLOBE_R)),
  []);

  return (
    <group>
      {STREAMS.map(([fi, ti, color], i) => (
        <StreamArc key={i} from={centers[fi]} to={centers[ti]} color={color} idx={i} />
      ))}
    </group>
  );
};

export default TravelStreams;
