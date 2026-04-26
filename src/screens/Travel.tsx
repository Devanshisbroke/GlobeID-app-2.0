import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import {
  Plane,
  Hotel,
  Search,
  Star,
  Clock,
  ChevronRight,
  QrCode,
  History,
  CalendarDays,
  Map as MapIcon,
  Sparkles,
} from "lucide-react";
import {
  Surface,
  Button,
  Pill,
  Tabs,
  Text,
  spring,
} from "@/components/ui/v2";
import { useUserStore } from "@/store/userStore";
import { demoBookings } from "@/lib/demoData";
import { demoFlightResults, demoHotelResults } from "@/lib/demoServices";
import { getIcon } from "@/lib/iconMap";
import TripCard from "@/components/travel/TripCard";

type Tab = "history" | "bookings" | "flights" | "hotels" | "pass";

/**
 * Travel — Phase 7 PR-δ.
 *
 * Visual reset against the v2 design system. Functional surface
 * preserved verbatim:
 *  - 5-tab segmented (Trips / Bookings / Flights / Hotels / Pass) — same
 *    state machine.
 *  - All store reads (`useUserStore.travelHistory`, `demoBookings`,
 *    `demoFlightResults`, `demoHotelResults`) preserved.
 *  - `TripCard` sub-component preserved unchanged (data-dense; migrates
 *    in a follow-up PR).
 *
 * Visual changes:
 *  - Tab toggle → `Tabs.Root` segmented (shared-layout indicator).
 *  - GlassCard hubs (Timeline / Planner / Copilot CTA) → `Surface
 *    variant="elevated"` rows with `Button asChild` arrow.
 *  - GlassCard cards everywhere → `Surface variant="elevated|plain"`
 *    with consistent radius. Drops the 108× `gradient-brand` icon-
 *    square pattern flagged in the Phase 7 audit.
 *  - Status chips → `Pill tone="..." weight="tinted"`.
 *  - Headings → `Text variant="caption-1" tone="tertiary"`.
 */
const Travel: React.FC = () => {
  const navigate = useNavigate();
  const { travelHistory } = useUserStore();
  const [tab, setTab] = useState<Tab>("history");
  const flights = demoBookings.filter((b) => b.type === "flight");
  const hotels = demoBookings.filter((b) => b.type === "hotel");

  const upcomingTrips = travelHistory.filter(
    (t) => t.type === "upcoming" || t.type === "current",
  );
  const pastTrips = travelHistory.filter((t) => t.type === "past");

  return (
    <div className="px-4 py-6 space-y-5">
      <Tabs value={tab} onValueChange={(next) => setTab(next as Tab)}>
        <Tabs.List variant="segmented" className="w-full overflow-x-auto">
          <Tabs.Trigger value="history" className="flex-1">
            <History className="w-4 h-4" strokeWidth={1.8} />
            Trips
          </Tabs.Trigger>
          <Tabs.Trigger value="bookings" className="flex-1">
            <Plane className="w-4 h-4" strokeWidth={1.8} />
            Bookings
          </Tabs.Trigger>
          <Tabs.Trigger value="flights" className="flex-1">
            <Search className="w-4 h-4" strokeWidth={1.8} />
            Flights
          </Tabs.Trigger>
          <Tabs.Trigger value="hotels" className="flex-1">
            <Hotel className="w-4 h-4" strokeWidth={1.8} />
            Hotels
          </Tabs.Trigger>
          <Tabs.Trigger value="pass" className="flex-1">
            <QrCode className="w-4 h-4" strokeWidth={1.8} />
            Pass
          </Tabs.Trigger>
        </Tabs.List>

        {/* History (Trips) */}
        <Tabs.Content value="history" className="mt-5 space-y-4">
          <NavRow
            icon={<CalendarDays />}
            title="Travel Timeline"
            subtitle="View your journey & achievements"
            onClick={() => navigate("/timeline")}
          />
          <NavRow
            icon={<MapIcon />}
            title="Trip Planner"
            subtitle="Design your next journey"
            onClick={() => navigate("/planner")}
          />
          <NavRow
            icon={<Sparkles />}
            title="AI Copilot"
            subtitle="Let AI plan your trip"
            tone="brand"
            onClick={() => navigate("/copilot")}
          />

          {upcomingTrips.length > 0 ? (
            <section className="space-y-3">
              <SectionHeading>Upcoming</SectionHeading>
              {upcomingTrips.map((trip) => (
                <TripCard key={trip.id} trip={trip} />
              ))}
            </section>
          ) : null}

          {pastTrips.length > 0 ? (
            <section className="space-y-3">
              <SectionHeading>Past Trips</SectionHeading>
              {pastTrips.map((trip) => (
                <TripCard key={trip.id} trip={trip} />
              ))}
            </section>
          ) : null}
        </Tabs.Content>

        {/* Bookings */}
        <Tabs.Content value="bookings" className="mt-5 space-y-4">
          <section className="space-y-3">
            <SectionHeading>Upcoming Flights</SectionHeading>
            {flights.map((bk) => (
              <Surface
                key={bk.id}
                variant="elevated"
                radius="surface"
                className="p-4 space-y-3"
              >
                <div className="flex items-center gap-3">
                  <Plane
                    className="w-5 h-5 text-brand shrink-0"
                    strokeWidth={1.8}
                  />
                  <div className="flex-1 min-w-0">
                    <Text variant="body-em" tone="primary" truncate>
                      {bk.title}
                    </Text>
                    <Text variant="caption-1" tone="tertiary" truncate>
                      {bk.subtitle}
                    </Text>
                  </div>
                  <ChevronRight className="w-4 h-4 text-ink-tertiary shrink-0" />
                </div>
                <DetailGrid details={bk.details} />
                <div className="flex items-center justify-between">
                  <Text variant="mono" tone="tertiary">
                    {bk.code}
                  </Text>
                  <BookingStatusPill status={bk.status} />
                </div>
              </Surface>
            ))}
          </section>

          <section className="space-y-3">
            <SectionHeading>Hotels</SectionHeading>
            {hotels.map((bk) => (
              <Surface
                key={bk.id}
                variant="elevated"
                radius="surface"
                className="overflow-hidden"
              >
                {bk.image ? (
                  <div className="relative">
                    <img
                      src={bk.image}
                      alt={bk.title}
                      className="w-full h-36 object-cover"
                      loading="lazy"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-surface-elevated via-transparent to-transparent" />
                  </div>
                ) : null}
                <div className="p-4 space-y-3">
                  <div>
                    <Text variant="body-em" tone="primary">
                      {bk.title}
                    </Text>
                    <Text variant="caption-1" tone="tertiary">
                      {bk.subtitle}
                    </Text>
                  </div>
                  <DetailGrid details={bk.details} cols={2} />
                  <div className="flex items-center justify-between">
                    <Text variant="mono" tone="tertiary">
                      {bk.code}
                    </Text>
                    <BookingStatusPill status={bk.status} />
                  </div>
                </div>
              </Surface>
            ))}
          </section>
        </Tabs.Content>

        {/* Flights search */}
        <Tabs.Content value="flights" className="mt-5 space-y-3">
          <Surface
            variant="elevated"
            radius="surface"
            className="p-4 space-y-3"
          >
            <Text variant="body-em" tone="primary">
              Search Flights
            </Text>
            <div className="grid grid-cols-2 gap-2">
              <SearchTile label="From" value="SIN" />
              <SearchTile label="To" value="BOM" />
            </div>
            <SearchTile label="Date" value="Mar 15, 2026" />
          </Surface>

          {demoFlightResults.map((fl) => {
            const FlIcon = getIcon(fl.icon);
            return (
              <Surface
                key={fl.id}
                variant="plain"
                radius="surface"
                className="p-4 space-y-3"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-2.5">
                    <FlIcon
                      className="w-5 h-5 text-brand shrink-0"
                      strokeWidth={1.8}
                    />
                    <div>
                      <Text variant="body-em" tone="primary">
                        {fl.airline}
                      </Text>
                      <Text variant="caption-1" tone="tertiary">
                        {fl.airlineCode} · {fl.class}
                      </Text>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <Text variant="body-em" tone="brand">
                      ${fl.price}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {fl.currency}
                    </Text>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="text-center">
                    <Text variant="body-em" tone="primary" className="tabular-nums">
                      {fl.departure}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {fl.from}
                    </Text>
                  </div>
                  <div className="flex-1 mx-3 flex flex-col items-center">
                    <span className="inline-flex items-center gap-1 text-p7-caption-2 text-ink-tertiary">
                      <Clock className="w-3 h-3" /> {fl.duration}
                    </span>
                    <span className="my-1.5 h-px w-full bg-surface-hairline relative">
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-brand" />
                      <span className="absolute right-0 top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-brand" />
                    </span>
                    <Text variant="caption-2" tone="tertiary">
                      {fl.stops === 0 ? "Direct" : `${fl.stops} stop`}
                    </Text>
                  </div>
                  <div className="text-center">
                    <Text variant="body-em" tone="primary" className="tabular-nums">
                      {fl.arrival}
                    </Text>
                    <Text variant="caption-2" tone="tertiary">
                      {fl.to}
                    </Text>
                  </div>
                </div>
              </Surface>
            );
          })}
        </Tabs.Content>

        {/* Hotels search */}
        <Tabs.Content value="hotels" className="mt-5 space-y-3">
          <Surface
            variant="elevated"
            radius="surface"
            className="p-4 space-y-3"
          >
            <Text variant="body-em" tone="primary">
              Search Hotels
            </Text>
            <SearchTile label="Destination" value="Mumbai, India" />
            <div className="grid grid-cols-2 gap-2">
              <SearchTile label="Check-in" value="Mar 15" />
              <SearchTile label="Check-out" value="Mar 18" />
            </div>
          </Surface>

          {demoHotelResults.map((h) => (
            <Surface
              key={h.id}
              variant="elevated"
              radius="surface"
              className={
                "overflow-hidden " + (!h.available ? "opacity-60" : "")
              }
            >
              <div className="relative">
                <img
                  src={h.image}
                  alt={h.name}
                  className="w-full h-36 object-cover"
                  loading="lazy"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-surface-elevated via-transparent to-transparent" />
                <span className="absolute top-3 right-3">
                  <Pill tone="warning" weight="tinted">
                    <Star className="w-3 h-3" /> {h.rating}
                  </Pill>
                </span>
              </div>
              <div className="p-4 space-y-3">
                <div>
                  <Text variant="body-em" tone="primary">
                    {h.name}
                  </Text>
                  <Text variant="caption-1" tone="tertiary">
                    {h.location}
                  </Text>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {h.amenities.map((a) => (
                    <Pill key={a} tone="neutral" weight="outline">
                      {a}
                    </Pill>
                  ))}
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-baseline gap-1">
                    <Text variant="title-3" tone="primary" className="tabular-nums">
                      ${h.price}
                    </Text>
                    <Text variant="caption-1" tone="tertiary">
                      /night
                    </Text>
                  </div>
                  {h.available ? (
                    <Button variant="primary" size="sm">
                      Book Now
                    </Button>
                  ) : (
                    <Text variant="caption-1" tone="tertiary">
                      Sold out
                    </Text>
                  )}
                </div>
              </div>
            </Surface>
          ))}
        </Tabs.Content>

        {/* Pass */}
        <Tabs.Content value="pass" className="mt-5">
          <Surface
            variant="elevated"
            radius="sheet"
            className="px-6 py-7 text-center space-y-5"
          >
            <span
              aria-hidden
              className="mx-auto flex h-12 w-12 items-center justify-center rounded-p7-input bg-brand-soft"
            >
              <QrCode className="w-5 h-5 text-brand" strokeWidth={2} />
            </span>
            <div>
              <Text variant="title-3" tone="primary">
                Travel Pass
              </Text>
              <Text variant="caption-1" tone="tertiary">
                Your unified boarding pass &amp; hotel reservation
              </Text>
            </div>
            <PassRow
              caption="Next Flight"
              title="SFO → SIN"
              meta="SQ31 · Mar 10, 2026 · 10:35 AM"
              accent="Seat 12A · Business"
            />
            <PassRow
              caption="Hotel"
              title="Marina Bay Sands"
              meta="Room 4012 · Mar 10–14"
              accent="Confirmed"
            />
          </Surface>
        </Tabs.Content>
      </Tabs>
    </div>
  );
};

export default Travel;

/* ──────────────────── Local sub-components ──────────────────── */

const SectionHeading: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => (
  <Text
    as="h3"
    variant="caption-1"
    tone="tertiary"
    className="px-1 uppercase tracking-[0.18em]"
  >
    {children}
  </Text>
);

interface NavRowProps {
  icon: React.ReactNode;
  title: string;
  subtitle: string;
  tone?: "neutral" | "brand";
  onClick: () => void;
}

const NavRow: React.FC<NavRowProps> = ({
  icon,
  title,
  subtitle,
  tone = "neutral",
  onClick,
}) => (
  <motion.button
    type="button"
    onClick={onClick}
    whileTap={{ scale: 0.98 }}
    transition={spring.snap}
    className="w-full text-left"
  >
    <Surface
      variant="elevated"
      radius="surface"
      className="flex items-center gap-3 px-4 py-3.5"
    >
      <span
        aria-hidden
        className={
          "flex h-9 w-9 items-center justify-center rounded-p7-input " +
          (tone === "brand"
            ? "bg-state-accent-soft text-state-accent"
            : "bg-brand-soft text-brand")
        }
      >
        <span className="[&>svg]:w-4 [&>svg]:h-4">{icon}</span>
      </span>
      <span className="flex-1">
        <Text variant="body-em" tone="primary">
          {title}
        </Text>
        <Text variant="caption-1" tone="tertiary">
          {subtitle}
        </Text>
      </span>
      <ChevronRight className="w-4 h-4 text-ink-tertiary" />
    </Surface>
  </motion.button>
);

const DetailGrid: React.FC<{
  details: Record<string, string>;
  cols?: 2 | 3 | 4;
}> = ({ details, cols = 3 }) => (
  <div
    className={
      "grid gap-2 pt-3 border-t border-surface-hairline " +
      (cols === 4
        ? "grid-cols-4"
        : cols === 2
          ? "grid-cols-2"
          : "grid-cols-3")
    }
  >
    {Object.entries(details).map(([k, v]) => (
      <div key={k}>
        <Text variant="caption-2" tone="tertiary" className="capitalize">
          {k}
        </Text>
        <Text variant="callout" tone="primary">
          {v}
        </Text>
      </div>
    ))}
  </div>
);

const SearchTile: React.FC<{ label: string; value: string }> = ({
  label,
  value,
}) => (
  <Surface
    variant="plain"
    radius="input"
    className="px-3 py-2.5 bg-surface-overlay"
  >
    <Text variant="caption-2" tone="tertiary">
      {label}
    </Text>
    <Text variant="body-em" tone="primary">
      {value}
    </Text>
  </Surface>
);

const PassRow: React.FC<{
  caption: string;
  title: string;
  meta: string;
  accent: string;
}> = ({ caption, title, meta, accent }) => (
  <Surface
    variant="plain"
    radius="surface"
    className="px-4 py-4 text-left bg-surface-overlay"
  >
    <Text
      variant="caption-2"
      tone="tertiary"
      className="uppercase tracking-[0.18em]"
    >
      {caption}
    </Text>
    <Text variant="title-3" tone="primary" className="mt-1">
      {title}
    </Text>
    <Text variant="caption-1" tone="tertiary" className="mt-1">
      {meta}
    </Text>
    <Text variant="callout" tone="accent" className="mt-1 font-semibold">
      {accent}
    </Text>
  </Surface>
);

const BookingStatusPill: React.FC<{ status: string }> = ({ status }) => {
  const tone =
    status === "confirmed"
      ? "accent"
      : status === "upcoming"
        ? "brand"
        : "neutral";
  return (
    <Pill tone={tone as "accent" | "brand" | "neutral"} weight="tinted">
      {status}
    </Pill>
  );
};
