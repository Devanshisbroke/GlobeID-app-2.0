import React, { useEffect, useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, MapPin, Clock, Plane, AlertCircle } from "lucide-react";
import { AnimatedPage } from "@/components/layout/AnimatedPage";
import TripLifecycleBadge from "@/components/travel/TripLifecycleBadge";
import ItineraryView from "@/components/trip/ItineraryView";
import QRBoardingPass from "@/components/trip/QRBoardingPass";
import TripGlobePreview from "@/components/trip/TripGlobePreview";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useUserStore } from "@/store/userStore";
import type { TripLifecycle } from "@shared/types/lifecycle";

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

const TripDetail: React.FC = () => {
  const { tripId } = useParams<{ tripId: string }>();
  const navigate = useNavigate();
  const trips = useLifecycleStore((s) => s.trips);
  const status = useLifecycleStore((s) => s.status);
  const hydrate = useLifecycleStore((s) => s.hydrate);
  const profile = useUserStore((s) => s.profile);

  useEffect(() => {
    if (status === "idle") hydrate().catch(() => undefined);
  }, [status, hydrate]);

  const trip = useMemo<TripLifecycle | null>(() => {
    if (!tripId) return null;
    if (tripId === "adhoc") {
      return trips.find((t) => t.tripId === null) ?? null;
    }
    return trips.find((t) => t.tripId === tripId) ?? null;
  }, [tripId, trips]);

  const today = todayIso();

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

  const upcomingLegs = trip.legs.filter((l) => l.date >= today);
  const upcomingFirst = upcomingLegs[0] ?? null;

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
