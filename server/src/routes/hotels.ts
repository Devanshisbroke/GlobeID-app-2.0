/**
 * Slice-B Phase-11 — hotels search/filter/sort.
 *
 *   GET /hotels/search?city=SIN&checkIn=&checkOut=&minStar=&maxPrice=&amenities=&sort=
 *
 * Real catalog. Booking is a separate concern (would require a partner
 * like Booking.com / Expedia / Hotelbeds).
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { hotelsCatalog, type Hotel } from "../../../shared/data/hotelsCatalog.js";

export const hotelsRouter = new Hono();
hotelsRouter.use("*", authMiddleware);

type SortKey = "price_asc" | "price_desc" | "rating_desc" | "stars_desc" | "distance_asc";

function applyFilters(rows: Hotel[], q: URLSearchParams): Hotel[] {
  const city = q.get("city")?.toUpperCase();
  const country = q.get("country")?.toUpperCase();
  const minStar = Number(q.get("minStar") ?? 0);
  const maxPrice = Number(q.get("maxPrice") ?? Number.POSITIVE_INFINITY);
  const minRating = Number(q.get("minRating") ?? 0);
  const amenitiesStr = q.get("amenities") ?? "";
  const amenities = amenitiesStr ? amenitiesStr.split(",").map((s) => s.trim()).filter(Boolean) : [];

  return rows.filter((h) => {
    if (city && h.cityIata !== city) return false;
    if (country && h.countryIso2 !== country) return false;
    if (h.starRating < minStar) return false;
    if (h.pricePerNightUsd > maxPrice) return false;
    if (h.rating < minRating) return false;
    for (const a of amenities) {
      if (!h.amenities.includes(a)) return false;
    }
    return true;
  });
}

function applySort(rows: Hotel[], sort: SortKey): Hotel[] {
  const out = [...rows];
  switch (sort) {
    case "price_asc":
      return out.sort((a, b) => a.pricePerNightUsd - b.pricePerNightUsd);
    case "price_desc":
      return out.sort((a, b) => b.pricePerNightUsd - a.pricePerNightUsd);
    case "rating_desc":
      return out.sort((a, b) => b.rating - a.rating);
    case "stars_desc":
      return out.sort((a, b) => b.starRating - a.starRating);
    case "distance_asc":
      return out.sort((a, b) => a.cityCentreKm - b.cityCentreKm);
  }
}

hotelsRouter.get("/search", (c) => {
  const q = new URLSearchParams(c.req.url.split("?")[1] ?? "");
  const checkIn = q.get("checkIn") ?? null;
  const checkOut = q.get("checkOut") ?? null;
  const sort = (q.get("sort") ?? "rating_desc") as SortKey;
  if (sort && !["price_asc", "price_desc", "rating_desc", "stars_desc", "distance_asc"].includes(sort)) {
    return err(c, "invalid_sort", `unknown sort key: ${sort}`, 400);
  }

  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (checkIn && !dateRegex.test(checkIn)) return err(c, "invalid_date", "checkIn must be YYYY-MM-DD", 400);
  if (checkOut && !dateRegex.test(checkOut)) return err(c, "invalid_date", "checkOut must be YYYY-MM-DD", 400);

  const filtered = applyFilters(hotelsCatalog, q);
  const sorted = applySort(filtered, sort);

  // Compute total nights + prices when dates are provided.
  let nights: number | null = null;
  if (checkIn && checkOut) {
    const days = Math.round((new Date(checkOut).getTime() - new Date(checkIn).getTime()) / 86_400_000);
    nights = days > 0 ? days : null;
  }
  const results = sorted.map((h) => ({
    ...h,
    totalUsd: nights ? Math.round(h.pricePerNightUsd * nights * 100) / 100 : null,
    nights,
  }));

  return ok(c, {
    total: results.length,
    nights,
    sort,
    results,
  });
});

hotelsRouter.get("/:id", (c) => {
  const id = c.req.param("id");
  const hotel = hotelsCatalog.find((h) => h.id === id);
  if (!hotel) return err(c, "not_found", `Hotel ${id} not in catalog`, 404);
  return ok(c, hotel);
});
