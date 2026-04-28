import React, { useState, useMemo, lazy, Suspense } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, Loader2 } from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import { cn } from "@/lib/utils";

// Lazy-load every panel so the hub itself stays lean. Each panel is its
// own chunk and only loads when its tab is opened — keeps initial paint
// well under our perf budget on slow devices while letting individual
// panels carry heavier visualisations / charts later.
const IntelligencePanel = lazy(() => import("@/components/services/IntelligencePanel"));
const LoyaltyPanel = lazy(() => import("@/components/services/LoyaltyPanel"));
const ScorePanel = lazy(() => import("@/components/services/ScorePanel"));
const BudgetPanel = lazy(() => import("@/components/services/BudgetPanel"));
const FraudPanel = lazy(() => import("@/components/services/FraudPanel"));
const SafetyPanel = lazy(() => import("@/components/services/SafetyPanel"));
const WeatherPanel = lazy(() => import("@/components/services/WeatherPanel"));
const VisaPanel = lazy(() => import("@/components/services/VisaPanel"));
const InsurancePanel = lazy(() => import("@/components/services/InsurancePanel"));
const EsimPanel = lazy(() => import("@/components/services/EsimPanel"));
const ExchangePanel = lazy(() => import("@/components/services/ExchangePanel"));
const HotelsPanel = lazy(() => import("@/components/services/HotelsPanel"));
const RidesPanel = lazy(() => import("@/components/services/RidesPanel"));
const FoodPanel = lazy(() => import("@/components/services/FoodPanel"));
const LocalServicesPanel = lazy(() => import("@/components/services/LocalServicesPanel"));

type TabKey =
  | "intel"
  | "loyalty"
  | "score"
  | "budget"
  | "fraud"
  | "safety"
  | "weather"
  | "visa"
  | "insurance"
  | "esim"
  | "exchange"
  | "hotels"
  | "rides"
  | "food"
  | "local";

interface TabSpec {
  key: TabKey;
  label: string;
  group: "intel" | "money" | "travel";
}

const TABS: TabSpec[] = [
  { key: "intel", label: "Intelligence", group: "intel" },
  { key: "score", label: "Score", group: "intel" },
  { key: "loyalty", label: "Loyalty", group: "intel" },
  { key: "fraud", label: "Fraud", group: "intel" },
  { key: "weather", label: "Weather", group: "intel" },
  { key: "safety", label: "Safety", group: "intel" },
  { key: "budget", label: "Budget", group: "money" },
  { key: "exchange", label: "FX", group: "money" },
  { key: "visa", label: "Visa", group: "travel" },
  { key: "insurance", label: "Insurance", group: "travel" },
  { key: "esim", label: "eSIM", group: "travel" },
  { key: "hotels", label: "Hotels", group: "travel" },
  { key: "rides", label: "Rides", group: "travel" },
  { key: "food", label: "Food", group: "travel" },
  { key: "local", label: "Local", group: "travel" },
];

const Loader: React.FC = () => (
  <div className="flex items-center gap-2 text-sm text-muted-foreground p-6">
    <Loader2 className="w-4 h-4 animate-spin" /> Loading panel…
  </div>
);

const SuperServicesHub: React.FC = () => {
  const navigate = useNavigate();
  const [active, setActive] = useState<TabKey>("intel");
  const groups = useMemo(() => {
    const out: Record<string, TabSpec[]> = { intel: [], money: [], travel: [] };
    for (const t of TABS) out[t.group]!.push(t);
    return out;
  }, []);

  const Panel = useMemo(() => {
    switch (active) {
      case "intel":
        return <IntelligencePanel />;
      case "loyalty":
        return <LoyaltyPanel />;
      case "score":
        return <ScorePanel />;
      case "budget":
        return <BudgetPanel />;
      case "fraud":
        return <FraudPanel />;
      case "safety":
        return <SafetyPanel />;
      case "weather":
        return <WeatherPanel />;
      case "visa":
        return <VisaPanel />;
      case "insurance":
        return <InsurancePanel />;
      case "esim":
        return <EsimPanel />;
      case "exchange":
        return <ExchangePanel />;
      case "hotels":
        return <HotelsPanel />;
      case "rides":
        return <RidesPanel />;
      case "food":
        return <FoodPanel />;
      case "local":
        return <LocalServicesPanel />;
    }
  }, [active]);

  return (
    <div className="px-4 py-6 pb-28 space-y-4">
      <AnimatedPage>
        <div className="flex items-center gap-3 mb-1">
          <button
            onClick={() => navigate(-1)}
            className="w-9 h-9 rounded-xl glass border border-border/30 flex items-center justify-center"
          >
            <ArrowLeft className="w-4 h-4 text-foreground" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-foreground">Super Services</h1>
            <p className="text-xs text-muted-foreground">Phase-11 + Phase-15 — every backend service in one hub</p>
          </div>
        </div>
      </AnimatedPage>

      <div className="space-y-2">
        {(["intel", "money", "travel"] as const).map((g) => (
          <div key={g} className="space-y-1.5">
            <p className="text-[10px] uppercase tracking-widest text-muted-foreground px-1">
              {g === "intel" ? "Intelligence" : g === "money" ? "Money" : "Travel services"}
            </p>
            <div className="flex gap-1.5 overflow-x-auto pb-1 -mx-1 px-1">
              {groups[g]!.map((t) => (
                <button
                  key={t.key}
                  onClick={() => setActive(t.key)}
                  className={cn(
                    "shrink-0 text-[11px] px-3 py-1.5 rounded-full border whitespace-nowrap transition-colors",
                    active === t.key
                      ? "bg-primary text-primary-foreground border-primary shadow-depth-sm"
                      : "border-border/40 text-foreground/80 hover:bg-secondary/40",
                  )}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>

      <Suspense fallback={<Loader />}>{Panel}</Suspense>
    </div>
  );
};

export default SuperServicesHub;
