import type { FraudFinding, FraudRule } from "../../../shared/types/fraud.js";

/**
 * Slice-B Phase-15 — deterministic fraud rules.
 *
 * No ML, no per-user model. The same input always produces the same
 * findings, which makes them auditable and replayable. Each finding has
 * a stable signature so re-running the scan never duplicates an alert.
 */

interface DebitRow {
  id: string;
  amount: number;
  currency: string;
  merchant: string | null;
  country: string | null;
  date: string;
  createdAt: number;
}

const VELOCITY_WINDOW_MS = 10 * 60 * 1000;
const VELOCITY_COUNT = 5;
const DUPLICATE_WINDOW_MS = 5 * 60 * 1000;
const GEO_JUMP_WINDOW_MS = 60 * 60 * 1000;
const Z_SCORE_THRESHOLD = 3;
const OFF_HOURS_LOCAL_START = 2;
const OFF_HOURS_LOCAL_END = 5;

export function evaluateFraudRules(rows: DebitRow[]): FraudFinding[] {
  const findings: FraudFinding[] = [];
  if (rows.length === 0) return findings;

  // 1. velocity — >N debits within 10 min window.
  for (let i = 0; i < rows.length; i++) {
    const cur = rows[i];
    if (!cur) continue;
    const window = rows.filter(
      (r) =>
        r.createdAt <= cur.createdAt &&
        cur.createdAt - r.createdAt <= VELOCITY_WINDOW_MS,
    );
    if (window.length > VELOCITY_COUNT) {
      findings.push({
        rule: "velocity",
        transactionId: cur.id,
        severity: "high",
        message: `${window.length} debits within 10 minutes — possible card-cycling.`,
        signature: `fraud:velocity:${cur.id}`,
        context: { windowSize: window.length, windowMs: VELOCITY_WINDOW_MS },
      });
      break;
    }
  }

  // 2. duplicate — identical (merchant, amount, currency) within 5 min.
  for (let i = 0; i < rows.length; i++) {
    const a = rows[i];
    if (!a) continue;
    for (let j = i + 1; j < rows.length; j++) {
      const b = rows[j];
      if (!b || a.id === b.id) continue;
      const dt = Math.abs(b.createdAt - a.createdAt);
      if (
        dt <= DUPLICATE_WINDOW_MS &&
        a.amount === b.amount &&
        a.currency === b.currency &&
        a.merchant !== null &&
        a.merchant === b.merchant
      ) {
        findings.push({
          rule: "duplicate",
          transactionId: b.id,
          severity: "medium",
          message: `Identical ${b.amount} ${b.currency} debit at "${b.merchant ?? ""}" within 5 minutes.`,
          signature: `fraud:duplicate:${a.id}:${b.id}`,
          context: { firstId: a.id, dtMs: dt },
        });
      }
    }
  }

  // 3. amount-z — debit |amount| > 3 stdev above the user's mean.
  if (rows.length >= 5) {
    const amounts = rows.map((r) => r.amount);
    const mean = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = amounts.reduce((s, a) => s + (a - mean) ** 2, 0) / amounts.length;
    const stdev = Math.sqrt(variance);
    if (stdev > 0) {
      for (const r of rows) {
        const z = (r.amount - mean) / stdev;
        if (z > Z_SCORE_THRESHOLD) {
          findings.push({
            rule: "amount_z",
            transactionId: r.id,
            severity: "high",
            message: `Debit ${r.amount} ${r.currency} is ${z.toFixed(1)}σ above your average.`,
            signature: `fraud:amount_z:${r.id}`,
            context: {
              z: Math.round(z * 100) / 100,
              mean: Math.round(mean * 100) / 100,
              stdev: Math.round(stdev * 100) / 100,
            },
          });
        }
      }
    }
  }

  // 4. geo-jump — consecutive debits in different countries within 1h.
  for (let i = 1; i < rows.length; i++) {
    const a = rows[i - 1];
    const b = rows[i];
    if (!a || !b) continue;
    if (
      a.country !== null &&
      b.country !== null &&
      a.country !== b.country &&
      b.createdAt - a.createdAt <= GEO_JUMP_WINDOW_MS
    ) {
      findings.push({
        rule: "geo_jump",
        transactionId: b.id,
        severity: "high",
        message: `Debit jumped ${a.country} → ${b.country} within an hour.`,
        signature: `fraud:geo_jump:${a.id}:${b.id}`,
        context: {
          fromCountry: a.country,
          toCountry: b.country,
          dtMs: b.createdAt - a.createdAt,
        },
      });
    }
  }

  // 5. off-hours — debit between 02:00-05:00 local AND >2 stdev above mean.
  if (rows.length >= 3) {
    const amounts = rows.map((r) => r.amount);
    const mean = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = amounts.reduce((s, a) => s + (a - mean) ** 2, 0) / amounts.length;
    const stdev = Math.sqrt(variance);
    if (stdev > 0) {
      for (const r of rows) {
        const localHour = new Date(r.createdAt).getUTCHours();
        const z = (r.amount - mean) / stdev;
        if (
          localHour >= OFF_HOURS_LOCAL_START &&
          localHour < OFF_HOURS_LOCAL_END &&
          z > 2
        ) {
          findings.push({
            rule: "off_hours",
            transactionId: r.id,
            severity: "medium",
            message: `Large debit (${r.amount} ${r.currency}) at ${localHour}:00 UTC — outside typical hours.`,
            signature: `fraud:off_hours:${r.id}`,
            context: { hourUtc: localHour, z: Math.round(z * 100) / 100 },
          });
        }
      }
    }
  }

  return findings;
}

export const FRAUD_RULES: FraudRule[] = ["velocity", "duplicate", "amount_z", "geo_jump", "off_hours"];
