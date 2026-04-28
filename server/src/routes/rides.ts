/**
 * Slice-B Phase-11 — rides.
 *
 *   POST /rides/estimate { fromIata, toLat, toLng, vehicle }
 *
 * Real estimator: haversine distance × per-km × surge × vehicle multiplier.
 * No dispatch — without a partner (Uber, Bolt) we can't request a real driver.
 *
 * "vehicle" is one of: bike | auto | sedan | suv | premium.
 */
import { Hono } from "hono";
import { z } from "zod";
import { authMiddleware } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import { findAirport, greatCircleKm } from "../lib/geo.js";

export const ridesRouter = new Hono();
ridesRouter.use("*", authMiddleware);

const VEHICLES = {
  bike: { perKmUsd: 0.4, baseFare: 0.5, capacity: 1, etaMinPerKm: 1.6, label: "Motorbike" },
  auto: { perKmUsd: 0.55, baseFare: 0.7, capacity: 3, etaMinPerKm: 1.9, label: "Auto rickshaw" },
  sedan: { perKmUsd: 0.85, baseFare: 1.2, capacity: 4, etaMinPerKm: 1.5, label: "Sedan" },
  suv: { perKmUsd: 1.25, baseFare: 1.8, capacity: 6, etaMinPerKm: 1.7, label: "SUV" },
  premium: { perKmUsd: 1.85, baseFare: 3.0, capacity: 4, etaMinPerKm: 1.4, label: "Premium" },
} as const;
type Vehicle = keyof typeof VEHICLES;

const estimateSchema = z.object({
  fromIata: z.string().length(3).optional(),
  fromLat: z.number().optional(),
  fromLng: z.number().optional(),
  toLat: z.number(),
  toLng: z.number(),
  vehicle: z.enum(["bike", "auto", "sedan", "suv", "premium"]),
  /** 1.0 = baseline; values above 1 simulate surge. */
  surge: z.number().min(0.5).max(5).optional(),
});

ridesRouter.post("/estimate", async (c) => {
  const parsed = await parseBody(c, estimateSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  let fromLat: number;
  let fromLng: number;
  if (body.fromIata) {
    const a = findAirport(body.fromIata);
    if (!a) return err(c, "unknown_origin", `Origin IATA ${body.fromIata} unknown`, 400);
    fromLat = a.lat;
    fromLng = a.lng;
  } else if (typeof body.fromLat === "number" && typeof body.fromLng === "number") {
    fromLat = body.fromLat;
    fromLng = body.fromLng;
  } else {
    return err(c, "missing_origin", "Provide fromIata OR fromLat+fromLng", 400);
  }

  const km = greatCircleKm(
    { name: "from", iata: "FROM", lat: fromLat, lng: fromLng, country: "", city: "" },
    { name: "to", iata: "TO", lat: body.toLat, lng: body.toLng, country: "", city: "" },
  );
  const v = VEHICLES[body.vehicle as Vehicle];
  const surge = body.surge ?? 1.0;
  const fare = (v.baseFare + km * v.perKmUsd) * surge;
  const etaMin = Math.max(3, Math.round(km * v.etaMinPerKm + 4));

  return ok(c, {
    distanceKm: Math.round(km * 10) / 10,
    fareUsd: Math.round(fare * 100) / 100,
    etaMinutes: etaMin,
    vehicle: body.vehicle,
    label: v.label,
    capacity: v.capacity,
    surge,
  });
});

ridesRouter.get("/vehicles", (c) =>
  ok(c, {
    vehicles: (Object.keys(VEHICLES) as Vehicle[]).map((k) => ({
      id: k,
      ...VEHICLES[k],
    })),
  }),
);
