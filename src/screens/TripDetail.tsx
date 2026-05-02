import React, { useEffect, useMemo } from "react";
import { useVisibleClock } from "@/hooks/useVisibleClock";
import { useNavigate, useParams } from "react-router-dom";
import {
  ArrowLeft,
  MapPin,
  Clock,
  Plane,
  AlertCircle,
  CalendarPlus,
  Share2,
  ScanLine,
} from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import TripLifecycleBadge from "@/components/travel/TripLifecycleBadge";
import ItineraryView from "@/components/trip/ItineraryView";
import QRBoardingPass from "@/components/trip/QRBoardingPass";
import TripGlobePreview from "@/components/trip/TripGlobePreview";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useUserStore } from "@/store/userStore";
import { travelRecordToLifecycle } from "@/lib/tripLifecycle";
import { countdownTo, formatCountdown } from "@/lib/countdown";
import { tripToIcs } from "@/lib/ics";
import { shareOrDownload } from "@/lib/shareSheet";
import { haptics } from "@/utils/haptics";
import { toast } from "sonner";
import type { TripLifecycle } from "@shared/types/lifecycle";

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

// useTickingClock removed: callers now use `useVisibleClock`, which is
// rAF-driven and pauses on Page Visibility hidden — same behaviour
// without burning a 1Hz timer when the screen is off.

const TripDetail: React.FC = () => {
  const { tripId } = useParams<{ tripId: string }>();
  const navigate = useNavigate();
  const trips = useLifecycleStore((s) => s.trips);
  const status = useLifecycleStore((s) => s.status);
  const hydrate = useLifecycleStore((s) => s.hydrate);
  const profile = useUserStore((s) => s.profile);
  const travelHistory = useUserStore((s) => s.travelHistory);

  useEffect(() => {
    if (status === "idle") hydrate().catch(() => undefined);
  }, [status, hydrate]);

  const trip = useMemo<TripLifecycle | null>(() => {
    if (!tripId) return null;
    if (tripId === "adhoc") {
      return trips.find((t) => t.tripId === null) ?? null;
    }
    const lifecycleHit = trips.find((t) => t.tripId === tripId);
    if (lifecycleHit) return lifecycleHit;
    // Fallback: a TripCard rendered from `userStore.travelHistory`
    // navigates here with the source `TravelRecord.id` (e.g. `tr-f1`).
    // Synthesise a single-leg lifecycle so the same detail view still
    // renders meaningfully — boarding pass + globe arc + summary tiles.
    const recordHit = travelHistory.find((r) => r.id === tripId);
    if (recordHit) return travelRecordToLifecycle(recordHit);
    return null;
  }, [tripId, trips, travelHistory]);

  const today = todayIso();

  // Hooks must run unconditionally — derive upcoming-leg ahead of any
  // early return so the countdown/share handlers can rely on a stable
  // hook order across render cycles. `null` trip is handled below.
  const upcomingFirst = useMemo(() => {
    if (!trip) return null;
    const upcoming = trip.legs.filter((l) => l.date >= today);
    return upcoming[0] ?? null;
  }, [trip, today]);

  // Tick once a minute pre-trip; the countdown component renders
  // nothing when there's no upcoming leg, so a passive tick is cheap.
  const nowTick = useVisibleClock(60_000);
  const cd = useMemo(() => {
    if (!upcomingFirst) return null;
    return countdownTo(upcomingFirst.date, new Date(nowTick));
  }, [upcomingFirst, nowTick]);

  if (!trip) {
    return (
      <div className="px-4 py-6 space-y-4">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-1.5 text-xs text-muted-foreground min-h-[44px]"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          Back
        </button>
        <div className="rounded-2xl border border-dashed border-border bg-card/50 p-6 text-center text-sm text-muted-foreground">
          {status === "loading"
            ? "Loading trip…"
            : "Trip not found. It may have been deleted, or your session needs to refresh."}
        </div>
      </div>
    );
  }

  const handleAddToCalendar = async () => {
    haptics.selection();
    const ics = tripToIcs(trip);
    const slug = trip.tripId ?? "trip";
    const result = await shareOrDownload("ics", {
      title: trip.name,
      text: `${trip.legs.length} flight${trip.legs.length === 1 ? "" : "s"}`,
      icsContent: ics,
      filename: `${slug}.ics`,
    });
    if (result === "native") toast.success("Shared to calendar");
    else if (result === "download") toast.success("Calendar file ready");
    else if (result === "web-share") toast.success("Shared");
  };

  const handleShareTrip = async () => {
    haptics.selection();
    const summary =
      upcomingFirst && cd && !cd.past
        ? `Departs ${formatCountdown(cd)}`
        : `${trip.legs.length} legs`;
    const result = await shareOrDownload("text", {
      title: trip.name,
      text: `${trip.name} · ${summary}`,
      url: typeof window !== "undefined" ? window.location.href : undefined,
    });
    if (result === "native" || result === "web-share") toast.success("Shared");
    else if (result === "download") toast.success("Copied to clipboard");
  };

  const handleVerifyAtKiosk = () => {
    if (!upcomingFirst) return;
    haptics.selection();
    const params = new URLSearchParams({
      passenger: profile.name,
      flight: upcomingFirst.flightNumber ?? "",
      airline: upcomingFirst.airline,
      from: upcomingFirst.fromIata,
      to: upcomingFirst.toIata,
      date: upcomingFirst.date,
      legId: upcomingFirst.id,
      tripId: trip.tripId ?? "",
    });
    navigate(`/kiosk-sim?${params.toString()}`);
  };

  return (
    <div className="px-4 py-6 space-y-5 pb-12">
      <AnimatedPage>
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-1.5 text-xs text-muted-foreground mb-3 min-h-[44px]"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          Back
        </button>

        {/* Header */}
        <div className="flex items-start gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
            <Plane className="w-5 h-5 text-primary" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-xl font-semibold text-foreground truncate">
                {trip.name}
              </h1>
              <TripLifecycleBadge state={trip.state} />
            </div>
            {trip.theme ? (
              <p className="text-[12px] text-muted-foreground capitalize mt-0.5">
                {trip.theme.replace("_", " ")}
              </p>
            ) : null}
          </div>
        </div>

        {/* Summary row */}
        <div className="grid grid-cols-3 gap-2 mb-5">
          <SummaryTile
            icon={<MapPin className="w-3.5 h-3.5 text-primary" />}
            label="Stops"
            value={String(trip.destinations.length || trip.legs.length)}
          />
          <SummaryTile
            icon={<Plane className="w-3.5 h-3.5 text-primary" />}
            label="Legs"
            value={String(trip.legs.length)}
          />
          <SummaryTile
            icon={<Clock className="w-3.5 h-3.5 text-primary" />}
            label="Window"
            value={
              trip.startsAt && trip.endsAt
                ? trip.startsAt === trip.endsAt
                  ? trip.startsAt.slice(5)
                  : `${trip.startsAt.slice(5)} → ${trip.endsAt.slice(5)}`
                : "—"
            }
          />
        </div>

        {/* Live countdown — only when there's an upcoming leg. */}
        {upcomingFirst && cd ? (
          <section
            aria-live="polite"
            aria-label={`Time until departure: ${formatCountdown(cd)}`}
            className="mb-5 rounded-2xl border border-primary/20 bg-primary/5 px-4 py-3"
          >
            <p className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
              {cd.past ? "Trip in progress" : "Departure in"}
            </p>
            <p
              className="mt-1 text-2xl font-semibold tabular-nums text-foreground"
              data-testid="trip-countdown"
            >
              {formatCountdown(cd)}
            </p>
            <p className="mt-0.5 text-[11px] text-muted-foreground">
              {upcomingFirst.airline}
              {upcomingFirst.flightNumber ? ` · ${upcomingFirst.flightNumber}` : ""}
              {" · "}
              {upcomingFirst.fromIata} → {upcomingFirst.toIata}
            </p>
          </section>
        ) : null}

        {/* Action row — calendar, share, verify */}
        <section className="mb-5 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={handleAddToCalendar}
            className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card px-3.5 py-2 text-[12px] font-medium text-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
            aria-label="Add trip to calendar"
          >
            <CalendarPlus className="w-3.5 h-3.5" />
            Add to calendar
          </button>
          <button
            type="button"
            onClick={handleShareTrip}
            className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card px-3.5 py-2 text-[12px] font-medium text-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
            aria-label="Share trip"
          >
            <Share2 className="w-3.5 h-3.5" />
            Share
          </button>
          {upcomingFirst ? (
            <button
              type="button"
              onClick={handleVerifyAtKiosk}
              className="inline-flex items-center gap-1.5 rounded-full bg-primary px-3.5 py-2 text-[12px] font-medium text-primary-foreground min-h-[44px] active:scale-[0.98] transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
              aria-label="Verify boarding pass at kiosk"
            >
              <ScanLine className="w-3.5 h-3.5" />
              Verify at kiosk
            </button>
          ) : null}
        </section>

        {/* Globe preview */}
        <section className="mb-5">
          <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2">
            Path on globe
          </h2>
          <TripGlobePreview legs={trip.legs} today={today} />
        </section>

        {/* Boarding pass for first upcoming leg */}
        {upcomingFirst ? (
          <section className="mb-5">
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2">
              Next boarding pass
            </h2>
            <QRBoardingPass
              passenger={profile.name}
              passportNo={profile.passportNumber || null}
              flightNumber={upcomingFirst.flightNumber}
              airline={upcomingFirst.airline}
              fromIata={upcomingFirst.fromIata}
              toIata={upcomingFirst.toIata}
              scheduledDate={upcomingFirst.date}
              legId={upcomingFirst.id}
              tripId={trip.tripId}
            />
          </section>
        ) : trip.state === "complete" ? (
          <div className="mb-5 rounded-2xl border border-border bg-card/50 p-4 text-center">
            <p className="text-sm text-muted-foreground">
              Trip complete. Boarding passes are no longer available.
            </p>
          </div>
        ) : null}

        {/* Itinerary */}
        <section className="mb-5">
          <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2">
            Itinerary
          </h2>
          <ItineraryView
            legs={trip.legs}
            reminders={trip.reminders}
            today={today}
          />
        </section>

        {/* Reminders summary (if any not already day-tied) */}
        {trip.reminders.length > 0 ? (
          <section>
            <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2 inline-flex items-center gap-1.5">
              <AlertCircle className="w-3 h-3" />
              All reminders ({trip.reminders.length})
            </h2>
            <ul className="rounded-2xl border border-border bg-card divide-y divide-border">
              {trip.reminders.map((r) => (
                <li
                  key={r.id}
                  className="px-3 py-2.5 flex items-start gap-2 text-[12px]"
                >
                  <span className="font-mono text-[10.5px] text-muted-foreground shrink-0">
                    {r.dueOn.slice(5)}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-foreground">{r.title}</p>
                    <p className="text-[11px] text-muted-foreground leading-snug">
                      {r.description}
                    </p>
                  </div>
                </li>
              ))}
            </ul>
          </section>
        ) : null}
      </AnimatedPage>
    </div>
  );
};

const SummaryTile: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: string;
}> = ({ icon, label, value }) => (
  <div className="rounded-xl border border-border bg-card px-3 py-2.5">
    <div className="flex items-center gap-1.5 mb-1">
      {icon}
      <span className="text-[10px] uppercase tracking-wider text-muted-foreground">
        {label}
      </span>
    </div>
    <p className="text-[14px] font-semibold text-foreground font-mono truncate">
      {value}
    </p>
  </div>
);

export default TripDetail;
