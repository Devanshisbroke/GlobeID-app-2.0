import React, { useMemo } from "react";
import {
  MapContainer,
  TileLayer,
  Polyline,
  CircleMarker,
  Tooltip,
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { getAirport } from "@/lib/airports";
import type { TravelRecord } from "@/store/userStore";

/**
 * Phase 9-γ — 2D world map rendered with Leaflet + OpenStreetMap tiles.
 *
 * Routes from the user's TravelRecord[] become great-circle approximated
 * polylines (Leaflet doesn't natively curve lines across the antimeridian
 * — we densify each segment so it reads as an arc).
 */

const colorByType: Record<TravelRecord["type"], string> = {
  upcoming: "#3fa9ff",
  current: "#ff7a00",
  past: "#5a7fa8",
};

/**
 * Generates points along a great-circle path between two lat/lng pairs.
 * Slerp via vector interpolation keeps it cheap; antimeridian-aware
 * because we project to 3D unit sphere first.
 */
function greatCirclePoints(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
  steps = 64,
): [number, number][] {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const f = {
    x: Math.cos(toRad(fromLat)) * Math.cos(toRad(fromLng)),
    y: Math.cos(toRad(fromLat)) * Math.sin(toRad(fromLng)),
    z: Math.sin(toRad(fromLat)),
  };
  const t = {
    x: Math.cos(toRad(toLat)) * Math.cos(toRad(toLng)),
    y: Math.cos(toRad(toLat)) * Math.sin(toRad(toLng)),
    z: Math.sin(toRad(toLat)),
  };
  const dot = Math.max(-1, Math.min(1, f.x * t.x + f.y * t.y + f.z * t.z));
  const angle = Math.acos(dot);
  if (angle < 1e-6) return [[fromLat, fromLng]];

  const out: [number, number][] = [];
  for (let i = 0; i <= steps; i++) {
    const a = i / steps;
    const sinA = Math.sin(angle);
    const k1 = Math.sin((1 - a) * angle) / sinA;
    const k2 = Math.sin(a * angle) / sinA;
    const x = k1 * f.x + k2 * t.x;
    const y = k1 * f.y + k2 * t.y;
    const z = k1 * f.z + k2 * t.z;
    const lat = toDeg(Math.atan2(z, Math.sqrt(x * x + y * y)));
    const lng = toDeg(Math.atan2(y, x));
    out.push([lat, lng]);
  }
  return out;
}

export interface Map2DViewProps {
  records: TravelRecord[];
  className?: string;
}

const Map2DView: React.FC<Map2DViewProps> = ({ records, className }) => {
  const arcs = useMemo(() => {
    return records
      .map((r) => {
        const fromA = getAirport(r.from);
        const toA = getAirport(r.to);
        if (!fromA || !toA) return null;
        const points = greatCirclePoints(
          fromA.lat,
          fromA.lng,
          toA.lat,
          toA.lng,
        );
        return {
          id: r.id,
          color: colorByType[r.type],
          weight: r.type === "upcoming" || r.type === "current" ? 3 : 2,
          opacity: r.type === "past" ? 0.6 : 0.9,
          dashArray: r.type === "upcoming" ? "6 4" : undefined,
          points,
          flightNumber: r.flightNumber ?? "",
          airline: r.airline,
          fromIata: fromA.iata,
          toIata: toA.iata,
          date: r.date,
        };
      })
      .filter((a): a is NonNullable<typeof a> => a !== null);
  }, [records]);

  const airportSet = useMemo(() => {
    const seen = new Map<
      string,
      { iata: string; lat: number; lng: number; city: string }
    >();
    for (const r of records) {
      for (const iata of [r.from, r.to]) {
        if (seen.has(iata)) continue;
        const a = getAirport(iata);
        if (a) seen.set(iata, { iata, lat: a.lat, lng: a.lng, city: a.city });
      }
    }
    return [...seen.values()];
  }, [records]);

  return (
    <div
      className={`rounded-2xl border border-border bg-card overflow-hidden ${
        className ?? ""
      }`}
      data-map-2d
    >
      <MapContainer
        center={[20, 0]}
        zoom={2}
        minZoom={2}
        worldCopyJump
        scrollWheelZoom
        style={{ width: "100%", height: "100%" }}
        attributionControl={false}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="&copy; OpenStreetMap"
          crossOrigin
        />
        {arcs.map((a) => (
          <Polyline
            key={a.id}
            positions={a.points}
            pathOptions={{
              color: a.color,
              weight: a.weight,
              opacity: a.opacity,
              dashArray: a.dashArray,
              lineCap: "round",
            }}
          >
            <Tooltip direction="top" offset={L.point(0, -4)}>
              <span className="text-[11px] font-mono">
                {a.fromIata} → {a.toIata} · {a.flightNumber || a.airline} · {a.date}
              </span>
            </Tooltip>
          </Polyline>
        ))}
        {airportSet.map((a) => (
          <CircleMarker
            key={a.iata}
            center={[a.lat, a.lng]}
            radius={4}
            pathOptions={{
              color: "#3fa9ff",
              fillColor: "#3fa9ff",
              fillOpacity: 0.85,
              weight: 1.5,
            }}
          >
            <Tooltip>
              <span className="text-[11px] font-semibold">
                {a.iata} · {a.city}
              </span>
            </Tooltip>
          </CircleMarker>
        ))}
      </MapContainer>
    </div>
  );
};

export default Map2DView;
