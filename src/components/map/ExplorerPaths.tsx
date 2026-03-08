import React, { useMemo } from "react";
import * as THREE from "three";
import { latLngToVector3, createArcPoints } from "@/lib/airports";
import { explorationPaths, destinations } from "@/lib/explorerData";

const GLOBE_R = 1;

interface Props {
  activePathId?: string;
}

const ExplorerPaths: React.FC<Props> = ({ activePathId }) => {
  const lines = useMemo(() => {
    const paths = activePathId
      ? explorationPaths.filter((p) => p.id === activePathId)
      : explorationPaths;

    return paths.flatMap((path) => {
      const segments: { geo: THREE.BufferGeometry; color: string }[] = [];
      for (let i = 0; i < path.stops.length - 1; i++) {
        const fromDest = destinations.find((d) => d.id === path.stops[i]);
        const toDest = destinations.find((d) => d.id === path.stops[i + 1]);
        if (!fromDest || !toDest) continue;
        const from = latLngToVector3(fromDest.lat, fromDest.lng, GLOBE_R);
        const to = latLngToVector3(toDest.lat, toDest.lng, GLOBE_R);
        const pts = createArcPoints(from, to, 64, 0.12);
        const geo = new THREE.BufferGeometry().setFromPoints(pts.map((p) => new THREE.Vector3(...p)));
        segments.push({ geo, color: path.color });
      }
      return segments;
    });
  }, [activePathId]);

  return (
    <group>
      {lines.map((line, i) => (
        <primitive
          key={i}
          object={new THREE.Line(
            line.geo,
            new THREE.LineBasicMaterial({ color: line.color, transparent: true, opacity: 0.4 })
          )}
        />
      ))}
    </group>
  );
};

export default ExplorerPaths;
