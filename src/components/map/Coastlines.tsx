import React, { useEffect, useMemo, useState } from "react";
import * as THREE from "three";
import { latLngToVector3 } from "@/lib/airports";

type PositionTuple = [number, number, number];

interface GeoJSONFeature {
  geometry?: {
    type: "Polygon" | "MultiPolygon";
    coordinates: number[][][] | number[][][][];
  };
}

interface GeoJSONFeatureCollection {
  features?: GeoJSONFeature[];
}

const COAST_RADIUS = 1.003;

const extractRings = (feature: GeoJSONFeature): number[][][] => {
  if (!feature.geometry) return [];
  if (feature.geometry.type === "Polygon") return feature.geometry.coordinates as number[][][];
  return (feature.geometry.coordinates as number[][][][]).flatMap((poly) => poly);
};

const Coastlines: React.FC = () => {
  const [rings, setRings] = useState<PositionTuple[][]>([]);

  useEffect(() => {
    let cancelled = false;

    fetch("/assets/geo/countries.geojson")
      .then((res) => {
        if (!res.ok) throw new Error("Failed to load coastlines");
        return res.json();
      })
      .then((json: GeoJSONFeatureCollection) => {
        if (cancelled) return;
        const mapped: PositionTuple[][] = [];
        (json.features ?? []).forEach((feature) => {
          extractRings(feature).forEach((ring) => {
            const positions = ring
              .filter((point) => point.length >= 2)
              .map(([lng, lat]) => latLngToVector3(lat, lng, COAST_RADIUS));
            if (positions.length > 1) mapped.push(positions);
          });
        });
        setRings(mapped);
      })
      .catch(() => setRings([]));

    return () => {
      cancelled = true;
    };
  }, []);

  const positions = useMemo(() => {
    const values: number[] = [];
    rings.forEach((ring) => {
      for (let i = 0; i < ring.length; i += 1) {
        const a = ring[i];
        const b = i === ring.length - 1 ? ring[0] : ring[i + 1];
        values.push(a[0], a[1], a[2], b[0], b[1], b[2]);
      }
    });
    return new Float32Array(values);
  }, [rings]);

  if (positions.length === 0) return null;

  return (
    <lineSegments raycast={() => null}>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          count={positions.length / 3}
          array={positions}
          itemSize={3}
        />
      </bufferGeometry>
      <lineBasicMaterial
        color="#00e6ff"
        transparent
        opacity={0.45}
        blending={THREE.AdditiveBlending}
        depthWrite={false}
      />
    </lineSegments>
  );
};

export default Coastlines;
