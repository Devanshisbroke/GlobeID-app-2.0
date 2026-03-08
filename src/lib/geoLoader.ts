import { latLngToVector3 } from "@/lib/airports";

export type PositionTuple = [number, number, number];

interface GeoJSONFeature {
  properties?: { name?: string };
  geometry?: {
    type: "Polygon" | "MultiPolygon";
    coordinates: number[][][] | number[][][][];
  };
}

interface GeoJSONFeatureCollection {
  features?: GeoJSONFeature[];
}

export interface CountryPolygon {
  name: string;
  positions: PositionTuple[];
  centroid: { lat: number; lng: number };
}

export interface GlobeGeoData {
  landPolygons: PositionTuple[][];
  countryPolygons: CountryPolygon[];
  countryBorders: PositionTuple[][];
  coastlines: PositionTuple[][];
}

let cache: GlobeGeoData | null = null;
let cachePromise: Promise<GlobeGeoData> | null = null;

const extractRings = (feature: GeoJSONFeature): number[][][] => {
  if (!feature.geometry) return [];
  if (feature.geometry.type === "Polygon") return feature.geometry.coordinates as number[][][];
  return (feature.geometry.coordinates as number[][][][]).flatMap((poly) => poly);
};

const ringToSphere = (ring: number[][], radius: number): PositionTuple[] =>
  ring.filter((pt) => pt.length >= 2).map(([lng, lat]) => latLngToVector3(lat, lng, radius));

const ringCentroid = (ring: number[][]): { lat: number; lng: number } => {
  let lat = 0;
  let lng = 0;
  let count = 0;
  ring.forEach((pt) => {
    if (pt.length >= 2) {
      lng += pt[0];
      lat += pt[1];
      count += 1;
    }
  });
  if (!count) return { lat: 0, lng: 0 };
  return { lat: lat / count, lng: lng / count };
};

export const loadGlobeGeoData = async (radius = 1): Promise<GlobeGeoData> => {
  if (cache) return cache;
  if (!cachePromise) {
    cachePromise = (async () => {
      const [landRes, countriesRes] = await Promise.all([
        fetch("/assets/geo/land.geojson"),
        fetch("/assets/geo/countries.geojson"),
      ]);
      if (!landRes.ok || !countriesRes.ok) throw new Error("GeoJSON fetch failed");

      const [landJson, countriesJson] = (await Promise.all([
        landRes.json(),
        countriesRes.json(),
      ])) as [GeoJSONFeatureCollection, GeoJSONFeatureCollection];

      const landPolygons: PositionTuple[][] = [];
      const countryPolygons: CountryPolygon[] = [];
      const countryBorders: PositionTuple[][] = [];
      const coastlines: PositionTuple[][] = [];

      (landJson.features ?? []).forEach((feature) => {
        extractRings(feature).forEach((ring) => {
          const mapped = ringToSphere(ring, radius + 0.002);
          if (mapped.length > 2) {
            landPolygons.push(mapped);
            coastlines.push(ringToSphere(ring, radius + 0.004));
          }
        });
      });

      (countriesJson.features ?? []).forEach((feature) => {
        extractRings(feature).forEach((ring) => {
          const mapped = ringToSphere(ring, radius + 0.002);
          if (mapped.length > 2) {
            countryPolygons.push({
              name: feature.properties?.name ?? "Unknown",
              positions: mapped,
              centroid: ringCentroid(ring),
            });
          }
          const border = ringToSphere(ring, radius + 0.003);
          if (border.length > 1) countryBorders.push(border);
        });
      });

      cache = { landPolygons, countryPolygons, countryBorders, coastlines };
      return cache;
    })();
  }
  return cachePromise;
};
