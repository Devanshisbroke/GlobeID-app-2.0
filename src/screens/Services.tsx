import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import {
  Car,
  UtensilsCrossed,
  MapPin,
  Shield,
  ChevronRight,
  Star,
  Clock,
  Check,
  Phone,
  Globe,
  Wifi,
  CreditCard,
  Umbrella,
  ArrowLeftRight,
  Sparkles,
} from "lucide-react";
import {
  Surface,
  Button,
  Pill,
  Tabs,
  Text,
  spring,
  stagger as v2Stagger,
} from "@/components/ui/v2";
import {
  demoRideProviders,
  demoRestaurants,
  demoEmergencyContacts,
  simulateRideRequest,
  type RideRequest,
} from "@/lib/demoServices";
import { detectCurrentLocation } from "@/lib/locationEngine";
import { getIcon } from "@/lib/iconMap";
import { cn } from "@/lib/utils";
import ServiceCard from "@/components/services/ServiceCard";

type Tab = "rides" | "food" | "services" | "safety";

const travelServices: {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  /**
   * Slice-G – wire every service tile to a real, full-screen detail
   * route. No more dead tiles. The route resolves through the same
   * `<Routes>` graph in App.tsx; each detail screen integrates wallet
   * + context + lifecycle on its own.
   */
  route: string;
}[] = [
  {
    id: "ts-1",
    title: "Visa Assistance",
    description: "Apply for e-visas and track applications",
    icon: <Globe className="w-5 h-5" strokeWidth={1.8} />,
    route: "/services/super",
  },
  {
    id: "ts-2",
    title: "Travel Insurance",
    description: "Compare and purchase travel coverage",
    icon: <Umbrella className="w-5 h-5" strokeWidth={1.8} />,
    route: "/services/super",
  },
  {
    id: "ts-3",
    title: "Airport Lounge Access",
    description: "Book premium lounge passes worldwide",
    icon: <CreditCard className="w-5 h-5" strokeWidth={1.8} />,
    route: "/services/activities",
  },
  {
    id: "ts-4",
    title: "Global SIM",
    description: "eSIM data plans for 190+ countries",
    icon: <Wifi className="w-5 h-5" strokeWidth={1.8} />,
    route: "/services/super",
  },
  {
    id: "ts-5",
    title: "Currency Exchange",
    description: "Real-time rates and instant conversion",
    icon: <ArrowLeftRight className="w-5 h-5" strokeWidth={1.8} />,
    route: "/multi-currency",
  },
];

const containerVariants = {
  initial: {},
  animate: { transition: { staggerChildren: v2Stagger.default } },
};

const itemVariants = {
  initial: { opacity: 0, y: 6 },
  animate: { opacity: 1, y: 0, transition: spring.default },
};

/**
 * Services — Phase 7 PR-ε.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - 4-tab segmented (Services / Rides / Food / Safety) — same state.
 *  - `simulateRideRequest` flow + `activeRide` state preserved.
 *  - `detectCurrentLocation` + pickup/dropoff defaults preserved.
 *  - `ServiceCard` sub-component preserved unchanged.
 *  - All store / data reads (`demoRideProviders`, `demoRestaurants`,
 *    `demoEmergencyContacts`) preserved.
 *
 * Visual changes:
 *  - Glass-pill tab toggle → `Tabs.Root` segmented.
 *  - Hub CTA → `Surface elevated` row.
 *  - GlassCard ride/food cards → `Surface` (variant per density).
 *  - Status / rating chips → `Pill tone="..." weight="tinted"`.
 *  - Emergency contacts list → `Surface elevated` table.
 *  - Section headings → `Text variant="caption-1"` uppercase eyebrow.
 *  - Drops the gradient-brand icon-square pattern in service cards.
 */
const Services: React.FC = () => {
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>("services");
  const [activeRide, setActiveRide] = useState<RideRequest | null>(null);
  const location = React.useMemo(() => detectCurrentLocation(), []);
  const [pickup] = useState(`${location.city} City Center`);
  const [dropoff] = useState(`${location.iata} Airport`);

  const handleRequestRide = (providerId: string) => {
    const ride = simulateRideRequest(providerId, pickup, dropoff);
    setActiveRide(ride);
  };

  return (
    <div className="px-4 py-6 space-y-5">
      <header>
        <Text as="h1" variant="title-2" tone="primary">
          Services
        </Text>
        <Text variant="caption-1" tone="tertiary" className="mt-1 inline-flex items-center gap-1.5">
          <MapPin className="w-3 h-3 text-state-accent" strokeWidth={2} />
          {location.city} — Local services available
        </Text>
      </header>

      <Tabs value={tab} onValueChange={(next) => setTab(next as Tab)}>
        <Tabs.List variant="segmented" className="w-full">
          <Tabs.Trigger value="services" className="flex-1">
            <Globe className="w-4 h-4" strokeWidth={1.8} />
            Services
          </Tabs.Trigger>
          <Tabs.Trigger value="rides" className="flex-1">
            <Car className="w-4 h-4" strokeWidth={1.8} />
            Rides
          </Tabs.Trigger>
          <Tabs.Trigger value="food" className="flex-1">
            <UtensilsCrossed className="w-4 h-4" strokeWidth={1.8} />
            Food
          </Tabs.Trigger>
          <Tabs.Trigger value="safety" className="flex-1">
            <Shield className="w-4 h-4" strokeWidth={1.8} />
            Safety
          </Tabs.Trigger>
        </Tabs.List>

        {/* Services hub + travel services */}
        <Tabs.Content value="services" className="mt-5 space-y-3">
          <Surface
            variant="elevated"
            radius="surface"
            onClick={() => navigate("/services/hub")}
            className="flex items-center gap-3 px-4 py-3.5 cursor-pointer"
          >
            <span
              aria-hidden
              className="flex h-10 w-10 items-center justify-center rounded-p7-input bg-brand-soft"
            >
              <Sparkles className="w-4 h-4 text-brand" strokeWidth={2} />
            </span>
            <div className="flex-1 min-w-0">
              <Text variant="body-em" tone="primary">
                Services Hub
              </Text>
              <Text variant="caption-1" tone="tertiary">
                Hotels, rides, food, activities &amp; more
              </Text>
            </div>
            <ChevronRight className="w-4 h-4 text-ink-tertiary" />
          </Surface>

          <Text
            as="h3"
            variant="caption-1"
            tone="tertiary"
            className="px-1 uppercase tracking-[0.18em] pt-1"
          >
            Travel Services
          </Text>

          <motion.div
            variants={containerVariants}
            initial="initial"
            animate="animate"
            className="space-y-3"
          >
            {travelServices.map((svc) => (
              <motion.div key={svc.id} variants={itemVariants}>
                <ServiceCard
                  title={svc.title}
                  description={svc.description}
                  icon={svc.icon}
                  tone="brand"
                  onAction={() => navigate(svc.route)}
                />
              </motion.div>
            ))}
          </motion.div>
        </Tabs.Content>

        {/* Rides */}
        <Tabs.Content value="rides" className="mt-5 space-y-3">
          {activeRide ? (
            <Surface
              variant="elevated"
              radius="surface"
              className="px-4 py-4 space-y-3"
            >
              <div className="flex items-center gap-2">
                <span
                  aria-hidden
                  className="flex h-6 w-6 items-center justify-center rounded-full bg-state-accent-soft"
                >
                  <Check
                    className="w-3.5 h-3.5 text-state-accent"
                    strokeWidth={2.2}
                  />
                </span>
                <Text variant="body-em" tone="accent">
                  Ride Confirmed
                </Text>
              </div>
              <div className="space-y-2">
                <RideDetail
                  label="Driver"
                  value={activeRide.driver?.name ?? "—"}
                />
                <RideDetail
                  label="Vehicle"
                  value={`${activeRide.driver?.vehicle ?? "—"} · ${activeRide.driver?.plate ?? "—"}`}
                />
                <RideDetail label="ETA" value={activeRide.eta} />
                <RideDetail
                  label="Price"
                  value={`${activeRide.currency} ${activeRide.price}`}
                  emphasis
                />
              </div>
            </Surface>
          ) : null}

          <Surface
            variant="plain"
            radius="surface"
            className="px-4 py-3 space-y-2"
          >
            <div className="flex items-center gap-2.5">
              <span className="w-2 h-2 rounded-full bg-brand" />
              <Text variant="callout" tone="primary">
                {pickup}
              </Text>
            </div>
            <div className="ml-[3px] border-l border-dashed border-surface-hairline h-4" />
            <div className="flex items-center gap-2.5">
              <span className="w-2 h-2 rounded-full bg-state-critical" />
              <Text variant="callout" tone="primary">
                {dropoff}
              </Text>
            </div>
          </Surface>

          {demoRideProviders.map((provider) => {
            const PIcon = getIcon(provider.icon);
            const disabled = !provider.available;
            return (
              <Surface
                key={provider.id}
                variant="plain"
                radius="surface"
                onClick={() =>
                  provider.available && handleRequestRide(provider.id)
                }
                className={cn(
                  "flex items-center gap-3 px-4 py-3.5",
                  provider.available && "cursor-pointer",
                  disabled && "opacity-50",
                )}
              >
                <span
                  aria-hidden
                  className="flex h-9 w-9 items-center justify-center rounded-p7-input bg-brand-soft shrink-0"
                >
                  <PIcon className="w-4 h-4 text-brand" strokeWidth={1.8} />
                </span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <Text variant="body-em" tone="primary">
                      {provider.name}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {provider.vehicleType}
                    </Text>
                  </div>
                  <div className="mt-0.5 flex items-center gap-3 text-p7-caption-2 text-ink-tertiary">
                    <span className="inline-flex items-center gap-1">
                      <Clock className="w-3 h-3" /> {provider.eta}
                    </span>
                    <span className="inline-flex items-center gap-1">
                      <Star className="w-3 h-3 text-[hsl(var(--p7-warning))]" />
                      {provider.rating}
                    </span>
                  </div>
                </div>
                <div className="text-right shrink-0">
                  <Text variant="body-em" tone="primary">
                    {provider.currency} {provider.price}
                  </Text>
                  {disabled ? (
                    <Text variant="caption-2" tone="tertiary">
                      Unavailable
                    </Text>
                  ) : null}
                </div>
              </Surface>
            );
          })}
        </Tabs.Content>

        {/* Food */}
        <Tabs.Content value="food" className="mt-5 space-y-3">
          {demoRestaurants.map((r) => {
            const RIcon = getIcon(r.icon);
            return (
              <Surface
                key={r.id}
                variant="elevated"
                radius="surface"
                className="overflow-hidden"
              >
                <div className="relative">
                  <img
                    src={r.image}
                    alt={r.name}
                    className="w-full h-36 object-cover"
                    loading="lazy"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-surface-elevated via-transparent to-transparent" />
                  <span className="absolute top-3 right-3">
                    <Pill tone="neutral" weight="solid">
                      {r.provider}
                    </Pill>
                  </span>
                </div>
                <div className="p-4 space-y-2">
                  <div className="flex items-center gap-2">
                    <RIcon
                      className="w-4 h-4 text-ink-tertiary"
                      strokeWidth={1.8}
                    />
                    <Text variant="body-em" tone="primary">
                      {r.name}
                    </Text>
                  </div>
                  <Text variant="caption-1" tone="tertiary">
                    {r.cuisine}
                  </Text>
                  <div className="flex items-center gap-3 text-p7-caption-1 text-ink-tertiary">
                    <span className="inline-flex items-center gap-1">
                      <Star className="w-3 h-3 text-[hsl(var(--p7-warning))]" />
                      {r.rating}
                    </span>
                    <span className="inline-flex items-center gap-1">
                      <Clock className="w-3 h-3" /> {r.deliveryTime}
                    </span>
                    <span>{r.deliveryFee}</span>
                    <span>{r.priceRange}</span>
                  </div>
                </div>
              </Surface>
            );
          })}
        </Tabs.Content>

        {/* Safety */}
        <Tabs.Content value="safety" className="mt-5 space-y-3">
          <Surface variant="elevated" radius="surface" className="p-4">
            <Text
              as="h3"
              variant="body-em"
              tone="primary"
              className="mb-3 inline-flex items-center gap-2"
            >
              <Shield
                className="w-4 h-4 text-state-accent"
                strokeWidth={2}
              />
              Emergency Contacts — {location.city}
            </Text>
            <div className="divide-y divide-surface-hairline">
              {demoEmergencyContacts.map((c) => {
                const CIcon = getIcon(c.icon);
                return (
                  <div
                    key={c.id}
                    className="flex items-center gap-3 py-2.5 first:pt-0 last:pb-0"
                  >
                    <span
                      aria-hidden
                      className="flex h-8 w-8 items-center justify-center rounded-p7-input bg-surface-overlay"
                    >
                      <CIcon
                        className="w-4 h-4 text-ink-tertiary"
                        strokeWidth={1.8}
                      />
                    </span>
                    <Text variant="callout" tone="primary" className="flex-1">
                      {c.name}
                    </Text>
                    <Button
                      variant="secondary"
                      size="sm"
                      asChild
                      leading={<Phone />}
                    >
                      <a href={`tel:${c.number}`}>{c.number}</a>
                    </Button>
                  </div>
                );
              })}
            </div>
          </Surface>

          <Surface variant="plain" radius="surface" className="p-4 space-y-2">
            <Button variant="critical" size="lg" className="w-full">
              Share Live Location
            </Button>
            <Text
              variant="caption-2"
              tone="tertiary"
              className="text-center"
            >
              Shares your location with trusted contacts for 1 hour
            </Text>
          </Surface>
        </Tabs.Content>
      </Tabs>
    </div>
  );
};

export default Services;

const RideDetail: React.FC<{
  label: string;
  value: string;
  emphasis?: boolean;
}> = ({ label, value, emphasis }) => (
  <div className="flex items-center justify-between">
    <Text variant="caption-1" tone="tertiary">
      {label}
    </Text>
    <Text
      variant={emphasis ? "body-em" : "callout"}
      tone="primary"
    >
      {value}
    </Text>
  </div>
);
