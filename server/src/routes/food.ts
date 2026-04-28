/**
 * Slice-B Phase-11 — restaurants search + cart pricing.
 *
 *   GET  /food/restaurants?city=&cuisine=&priceTier=&minRating=&sort=
 *   GET  /food/restaurants/:id
 *   POST /food/quote { items: [{ menuItemId, qty }], deliveryFeeUsd? }
 *
 * Real menu pricing math (subtotal + tax + delivery + tip). Order placement
 * is intentionally absent — without partner APIs we can't dispatch a courier.
 */
import { Hono } from "hono";
import { z } from "zod";
import { authMiddleware } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import { restaurantsCatalog, type Restaurant } from "../../../shared/data/foodCatalog.js";

export const foodRouter = new Hono();
foodRouter.use("*", authMiddleware);

type FoodSort = "rating_desc" | "eta_asc" | "price_asc";

function applyFilters(rows: Restaurant[], q: URLSearchParams): Restaurant[] {
  const city = q.get("city")?.toUpperCase();
  const cuisine = q.get("cuisine")?.toLowerCase();
  const priceTier = q.get("priceTier") ?? null;
  const minRating = Number(q.get("minRating") ?? 0);
  return rows.filter((r) => {
    if (city && r.cityIata !== city) return false;
    if (cuisine && r.cuisine !== cuisine) return false;
    if (priceTier && r.priceTier !== priceTier) return false;
    if (r.rating < minRating) return false;
    return true;
  });
}

function applySort(rows: Restaurant[], sort: FoodSort): Restaurant[] {
  const out = [...rows];
  if (sort === "rating_desc") out.sort((a, b) => b.rating - a.rating);
  else if (sort === "eta_asc") out.sort((a, b) => a.etaMinutes - b.etaMinutes);
  else if (sort === "price_asc")
    out.sort(
      (a, b) =>
        ["$", "$$", "$$$"].indexOf(a.priceTier) -
        ["$", "$$", "$$$"].indexOf(b.priceTier),
    );
  return out;
}

foodRouter.get("/restaurants", (c) => {
  const q = new URLSearchParams(c.req.url.split("?")[1] ?? "");
  const sort = (q.get("sort") ?? "rating_desc") as FoodSort;
  if (sort && !["rating_desc", "eta_asc", "price_asc"].includes(sort)) {
    return err(c, "invalid_sort", `unknown sort key: ${sort}`, 400);
  }
  const filtered = applyFilters(restaurantsCatalog, q);
  const sorted = applySort(filtered, sort);
  return ok(c, { total: sorted.length, sort, results: sorted });
});

foodRouter.get("/restaurants/:id", (c) => {
  const id = c.req.param("id");
  const r = restaurantsCatalog.find((x) => x.id === id);
  if (!r) return err(c, "not_found", `Restaurant ${id} not in catalog`, 404);
  return ok(c, r);
});

const quoteSchema = z.object({
  restaurantId: z.string().min(1),
  items: z
    .array(
      z.object({
        menuItemId: z.string().min(1),
        qty: z.number().int().positive().max(50),
      }),
    )
    .min(1),
  taxRate: z.number().min(0).max(0.5).optional(),
  tipFraction: z.number().min(0).max(0.5).optional(),
});

foodRouter.post("/quote", async (c) => {
  const parsed = await parseBody(c, quoteSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;
  const restaurant = restaurantsCatalog.find((r) => r.id === body.restaurantId);
  if (!restaurant) return err(c, "not_found", `Restaurant ${body.restaurantId} not in catalog`, 404);

  let subtotal = 0;
  const lines: Array<{ menuItemId: string; name: string; qty: number; lineTotalUsd: number }> = [];
  for (const item of body.items) {
    const menuItem = restaurant.menu.find((m) => m.id === item.menuItemId);
    if (!menuItem) return err(c, "menu_item_missing", `Menu item ${item.menuItemId} not on this restaurant`, 400);
    const lineTotal = menuItem.priceUsd * item.qty;
    lines.push({
      menuItemId: menuItem.id,
      name: menuItem.name,
      qty: item.qty,
      lineTotalUsd: Math.round(lineTotal * 100) / 100,
    });
    subtotal += lineTotal;
  }
  const tax = subtotal * (body.taxRate ?? 0.05);
  const tip = subtotal * (body.tipFraction ?? 0);
  const delivery = restaurant.deliveryFeeUsd;
  const total = subtotal + tax + tip + delivery;
  return ok(c, {
    restaurantId: restaurant.id,
    lines,
    subtotalUsd: Math.round(subtotal * 100) / 100,
    taxUsd: Math.round(tax * 100) / 100,
    tipUsd: Math.round(tip * 100) / 100,
    deliveryUsd: delivery,
    totalUsd: Math.round(total * 100) / 100,
    etaMinutes: restaurant.etaMinutes,
  });
});
