import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { issueToken, DEMO_USER_ID } from "./auth/token.js";
import { seedIfEmpty } from "./db/seed.js";
import { userRouter } from "./routes/user.js";
import { tripsRouter } from "./routes/trips.js";
import { insightsRouter } from "./routes/insights.js";
import { recommendationsRouter } from "./routes/recommendations.js";
import { alertsRouter } from "./routes/alerts.js";
import { ok } from "./lib/validate.js";

const app = new Hono();
app.use("*", logger());
app.use(
  "*",
  cors({
    origin: (process.env.ALLOWED_ORIGIN ?? "http://localhost:8080").split(","),
    allowHeaders: ["Authorization", "Content-Type"],
    allowMethods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    credentials: false,
  })
);

const api = new Hono();

api.get("/health", (c) => ok(c, { status: "ok", uptime: process.uptime() }));

/** Demo auth — returns a static HMAC-signed token bound to the demo user. */
api.post("/auth/demo", (c) => ok(c, { token: issueToken(DEMO_USER_ID), userId: DEMO_USER_ID }));

api.route("/user", userRouter);
api.route("/trips", tripsRouter);
api.route("/insights", insightsRouter);
api.route("/recommendations", recommendationsRouter);
api.route("/alerts", alertsRouter);

app.route("/api/v1", api);

const seedResult = seedIfEmpty();
console.log(`[server] DB ready (seeded=${seedResult.seeded})`);

const port = Number(process.env.PORT ?? 4000);
serve({ fetch: app.fetch, port }, ({ port }) => {
  console.log(`[server] listening on http://localhost:${port}`);
});
