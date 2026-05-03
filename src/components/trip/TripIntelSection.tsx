/**
 * Trip-detail enrichment block — wraps five BACKLOG items into one cohesive
 * section under the boarding pass:
 *   D 43 — Time-zone delta + local-time card
 *   D 44 — Currency converter prefilled with destination currency
 *   D 46 — Packing list (climate × duration aware)
 *   D 49 — Ground transport deep-links (Uber/Lyft/Bolt/Grab/Didi)
 *   D 50 — Lounge access lookup by alliance × airport
 *
 * Pure presentation; data comes from `lib/tripIntel.ts`. Each sub-section
 * is collapsible to keep the trip detail screen scannable.
 */
import React, { useMemo, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Clock,
  Globe2,
  ListChecks,
  Coins,
  Car,
  Sofa,
  ChevronRight,
  ExternalLink,
  Check,
} from "lucide-react";
import { useVisibleClock } from "@/hooks/useVisibleClock";
import {
  timezoneDelta,
  localTimeAt,
  generatePackingList,
  loungesAt,
  groundTransportFor,
  currencyForAirport,
  type PackingItem,
} from "@/lib/tripIntel";
import { findAirport } from "@shared/data/airports";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";

interface Props {
  /** IATA of the destination — passed in by parent. */
  destIata: string;
  /** IATA of the user's home base (origin of first leg), defaults to SFO. */
  homeIata: string;
  /** Departure date (ISO yyyy-mm-dd). */
  departDate: string;
  /** Trip duration in days, used by packing list rules. */
  durationDays: number;
  /** Storage key prefix so per-trip toggles persist. */
  storageKey: string;
}

const TripIntelSection: React.FC<Props> = ({
  destIata,
  homeIata,
  departDate,
  durationDays,
  storageKey,
}) => {
  const dest = findAirport(destIata);
  const home = findAirport(homeIata);
  const departMonth = useMemo(() => {
    const d = new Date(departDate);
    return Number.isFinite(d.getTime()) ? d.getMonth() : new Date().getMonth();
  }, [departDate]);

  // Tick once a minute so the destination clock stays current. The hook
  // pauses when the page is hidden — no setInterval polling.
  const nowTick = useVisibleClock(60_000);
  const local = useMemo(() => localTimeAt(destIata, new Date(nowTick)), [destIata, nowTick]);
  const tz = useMemo(() => timezoneDelta(homeIata, destIata), [homeIata, destIata]);

  const packing = useMemo(
    () => generatePackingList(destIata, durationDays, departMonth),
    [destIata, durationDays, departMonth],
  );
  const lounges = useMemo(() => loungesAt(destIata), [destIata]);
  const transport = useMemo(() => groundTransportFor(destIata), [destIata]);
  const destCurrency = useMemo(() => currencyForAirport(destIata), [destIata]);

  // Persist packing-list checks per trip
  const [checked, setChecked] = useState<Set<string>>(() => loadChecked(storageKey));
  const toggle = (id: string) => {
    haptics.selection();
    setChecked((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      saveChecked(storageKey, next);
      return next;
    });
  };

  if (!dest) return null;

  return (
    <section className="space-y-3">
      <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
        Destination intel
      </h2>

      {/* D 43 — Local time + timezone delta */}
      <Card title="Local time" Icon={Clock} accent>
        <div className="flex items-baseline justify-between gap-3">
          <p className="text-3xl font-semibold tabular-nums text-foreground">
            {pad2(local.hours)}:{pad2(local.minutes)}
          </p>
          <div className="text-right">
            <p className="text-[11px] uppercase tracking-wider text-muted-foreground">
              vs {homeIata}
            </p>
            <p className="text-sm font-mono text-foreground">{tz.pretty}</p>
          </div>
        </div>
        <p className="mt-1 text-[11px] text-muted-foreground">
          {dest.city}, {dest.country}
        </p>
      </Card>

      {/* D 44 — Currency hint */}
      <Card title="Local currency" Icon={Coins}>
        <div className="flex items-center justify-between">
          <p className="text-base font-semibold text-foreground">
            {destCurrency}
            <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">
              prefilled in converter
            </span>
          </p>
          <a
            href={`/wallet?convert=${destCurrency}`}
            className="inline-flex items-center gap-1 text-[12px] font-medium text-[hsl(var(--p7-brand))]"
            onClick={() => haptics.selection()}
          >
            Open wallet
            <ChevronRight className="w-3.5 h-3.5" />
          </a>
        </div>
      </Card>

      {/* D 46 — Packing list */}
      <Card title={`Packing list · ${packing.length} items`} Icon={ListChecks}>
        <ul className="space-y-1.5">
          {packing.map((item) => (
            <PackingRow
              key={item.id}
              item={item}
              checked={checked.has(item.id)}
              onToggle={() => toggle(item.id)}
            />
          ))}
        </ul>
        <p className="mt-3 text-[11px] text-muted-foreground">
          {checked.size}/{packing.length} packed
        </p>
      </Card>

      {/* D 49 — Ground transport */}
      {transport.length > 0 ? (
        <Card title="Ground transport" Icon={Car}>
          <div className="grid grid-cols-2 gap-2">
            {transport.map((t) => (
              <a
                key={t.id}
                href={t.url}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => haptics.selection()}
                className="inline-flex items-center justify-between gap-2 rounded-xl border border-border bg-surface-elevated px-3 py-2.5 text-[12px] font-medium text-foreground active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
              >
                <span>{t.label}</span>
                <ExternalLink className="w-3 h-3 text-muted-foreground" />
              </a>
            ))}
          </div>
        </Card>
      ) : null}

      {/* D 50 — Lounges */}
      {lounges.length > 0 ? (
        <Card title="Airport lounges" Icon={Sofa}>
          <ul className="space-y-1.5">
            {lounges.map((l) => (
              <li
                key={`${l.iata}-${l.alliance}-${l.loungeName}`}
                className="flex items-start justify-between gap-3 rounded-xl border border-border/60 bg-surface-base/60 px-3 py-2"
              >
                <div className="min-w-0 flex-1">
                  <p className="text-[13px] font-medium text-foreground truncate">
                    {l.loungeName}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {l.alliance}
                    {l.terminal ? ` · Terminal ${l.terminal}` : ""}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
    </section>
  );
};

const Card: React.FC<{
  title: string;
  Icon: React.ComponentType<{ className?: string }>;
  accent?: boolean;
  children: React.ReactNode;
}> = ({ title, Icon, accent, children }) => (
  <div
    className={cn(
      "rounded-2xl border bg-surface-base p-3.5",
      accent ? "border-[hsl(var(--p7-brand))]/30 bg-[hsl(var(--p7-brand))]/[0.04]" : "border-border",
    )}
  >
    <div className="mb-2 flex items-center gap-2">
      <Icon
        className={cn(
          "w-3.5 h-3.5",
          accent ? "text-[hsl(var(--p7-brand))]" : "text-muted-foreground",
        )}
      />
      <h3 className="text-[10px] uppercase tracking-wider text-muted-foreground">{title}</h3>
    </div>
    {children}
  </div>
);

const PackingRow: React.FC<{
  item: PackingItem;
  checked: boolean;
  onToggle: () => void;
}> = ({ item, checked, onToggle }) => (
  <li>
    <button
      type="button"
      onClick={onToggle}
      aria-pressed={checked}
      className={cn(
        "w-full inline-flex items-center gap-3 rounded-xl px-3 py-2 text-left transition-colors min-h-[44px]",
        "focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
        checked
          ? "bg-[hsl(var(--p7-brand))]/[0.08] text-foreground"
          : "bg-surface-elevated/60 text-foreground hover:bg-surface-elevated",
      )}
    >
      <span
        className={cn(
          "flex h-5 w-5 shrink-0 items-center justify-center rounded-full border transition-colors",
          checked
            ? "border-[hsl(var(--p7-brand))] bg-[hsl(var(--p7-brand))] text-white"
            : "border-border bg-transparent",
        )}
      >
        <AnimatePresence>
          {checked ? (
            <motion.span
              key="check"
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0, opacity: 0 }}
              transition={{ type: "spring", stiffness: 600, damping: 28 }}
            >
              <Check className="w-3 h-3" strokeWidth={3} />
            </motion.span>
          ) : null}
        </AnimatePresence>
      </span>
      <span className="flex-1 min-w-0 text-[13px]">{item.label}</span>
      {item.count > 1 ? (
        <span className="font-mono text-[11px] text-muted-foreground tabular-nums">×{item.count}</span>
      ) : null}
      <span className="text-[10px] uppercase tracking-wider text-muted-foreground">
        {item.category}
      </span>
    </button>
  </li>
);

function pad2(n: number): string {
  return String(n).padStart(2, "0");
}

function loadChecked(key: string): Set<string> {
  try {
    const raw = localStorage.getItem(`globeid:trip-pack:${key}`);
    if (!raw) return new Set();
    const arr = JSON.parse(raw) as unknown;
    if (!Array.isArray(arr)) return new Set();
    return new Set(arr.filter((x): x is string => typeof x === "string"));
  } catch {
    return new Set();
  }
}

function saveChecked(key: string, value: Set<string>): void {
  try {
    localStorage.setItem(
      `globeid:trip-pack:${key}`,
      JSON.stringify(Array.from(value)),
    );
  } catch {
    /* ignore */
  }
}

// Re-export icon dual-use also unused
void Globe2;

export default TripIntelSection;
