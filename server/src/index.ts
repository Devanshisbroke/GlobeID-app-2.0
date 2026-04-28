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
import { copilotRouter } from "./routes/copilot.js";
import { plannerRouter } from "./routes/planner.js";
import { contextRouter } from "./routes/context.js";
import { lifecycleRouter } from "./routes/lifecycle.js";
import { walletRouter } from "./routes/wallet.js";
import { loyaltyRouter } from "./routes/loyalty.js";
import { safetyRouter } from "./routes/safety.js";
import { scoreRouter } from "./routes/score.js";
import { weatherRouter } from "./routes/weather.js";
import { budgetRouter } from "./routes/budget.js";
import { fraudRouter } from "./routes/fraud.js";
import { exchangeRouter } from "./routes/exchange.js";
import { visaRouter } from "./routes/visa.js";
import { insuranceRouter } from "./routes/insurance.js";
import { esimRouter } from "./routes/esim.js";
import { hotelsRouter } from "./routes/hotels.js";
import { foodRouter } from "./routes/food.js";
import { ridesRouter } from "./routes/rides.js";
import { localRouter } from "./routes/local.js";
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
api.route("/copilot", copilotRouter);
api.route("/planner/trips", plannerRouter);
api.route("/context", contextRouter);
api.route("/lifecycle", lifecycleRouter);
api.route("/wallet", walletRouter);
api.route("/loyalty", loyaltyRouter);
api.route("/safety", safetyRouter);
api.route("/score", scoreRouter);
api.route("/weather", weatherRouter);
api.route("/budget", budgetRouter);
api.route("/fraud", fraudRouter);
api.route("/exchange", exchangeRouter);
api.route("/visa", visaRouter);
api.route("/insurance", insuranceRouter);
api.route("/esim", esimRouter);
api.route("/hotels", hotelsRouter);
api.route("/food", foodRouter);
api.route("/rides", ridesRouter);
api.route("/local", localRouter);

app.route("/api/v1", api);

const seedResult = seedIfEmpty();
console.log(`[server] DB ready (seeded=${seedResult.seeded})`);

const port = Number(process.env.PORT ?? 4000);
serve({ fetch: app.fetch, port }, ({ port }) => {
  console.log(`[server] listening on http://localhost:${port}`);
});
