import React from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "motion/react";
import { ShieldCheck, User, Trophy, Sparkles, MapPin, Plane } from "lucide-react";
import { Surface, Pill, Text, spring } from "@/components/ui/v2";
import { useUserStore, selectVisitedCountries, selectCurrentLocation } from "@/store/userStore";
import { useInsightsStore } from "@/store/insightsStore";
import { calculateTravelScore } from "@/lib/travelSuggestions";
import { IdentityScore } from "@/components/ui/IdentityScore";

const ProfileCard: React.FC = () => {
  const navigate = useNavigate();
  const { profile, travelHistory } = useUserStore();
  const visitedCount = React.useMemo(
    () => selectVisitedCountries(travelHistory).length,
    [travelHistory],
  );
  const location = React.useMemo(
    () => selectCurrentLocation(travelHistory, { country: profile.nationality }),
    [travelHistory, profile.nationality],
  );
  const travelScore = calculateTravelScore(visitedCount, 45000, 3);
  const travelInsight = useInsightsStore((s) => s.travel);
  const daysUntil = travelInsight?.daysUntilNextTrip ?? null;
  const nextDest = travelInsight?.nextTrip?.destinationCountry ?? null;

  const greeting =
    new Date().getHours() < 12
      ? "Good morning"
      : new Date().getHours() < 18
        ? "Good afternoon"
        : "Good evening";

  return (
    <Surface
      variant="elevated"
      radius="sheet"
      className="relative overflow-hidden p-5 cursor-pointer"
      onClick={() => navigate("/profile")}
    >
      {/* Subtle ambient sweep — single soft gradient, not a fill */}
      <div className="pointer-events-none absolute -top-16 -right-16 w-48 h-48 rounded-full bg-brand/10 blur-3xl" />

      <div className="relative">
        {/* Greeting */}
        <div className="flex items-center gap-2 mb-1.5">
          <Sparkles
            className="w-3.5 h-3.5 text-[hsl(var(--p7-warning))]"
            strokeWidth={1.8}
          />
          <Text variant="caption-1" tone="tertiary" className="font-medium">
            {greeting},
          </Text>
        </div>
        <Text variant="title-2" tone="primary" className="tracking-tight">
          {profile.name}
        </Text>

        {daysUntil !== null && nextDest && daysUntil >= 0 && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring.default}
            className="mt-1.5 inline-block"
          >
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                navigate("/map");
              }}
            >
              <Pill tone="accent" weight="tinted">
                <Plane className="w-3 h-3" strokeWidth={2.2} />
                {daysUntil === 0
                  ? `Departing today — ${nextDest}`
                  : `Trip to ${nextDest} in ${daysUntil} day${daysUntil === 1 ? "" : "s"}`}
              </Pill>
            </button>
          </motion.div>
        )}

        {/* Identity row */}
        <div className="flex items-center gap-4 mt-3">
          <motion.div
            className="w-14 h-14 rounded-p7-sheet bg-brand-soft border border-brand/20 flex items-center justify-center shrink-0 cursor-pointer overflow-hidden"
            whileTap={{ scale: 0.92 }}
            transition={spring.snap}
          >
            {profile.avatarUrl ? (
              <img
                src={profile.avatarUrl}
                alt={profile.name}
                className="w-full h-full object-cover"
              />
            ) : (
              <User className="w-6 h-6 text-brand" />
            )}
          </motion.div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-1.5 mb-1">
              <Pill tone="brand" weight="tinted">
                {profile.verifiedStatus}
              </Pill>
              {profile.verifiedStatus === "verified" && (
                <ShieldCheck className="w-3.5 h-3.5 text-state-accent" />
              )}
            </div>
            <Text variant="caption-1" tone="tertiary">
              {profile.nationalityFlag} {profile.nationality} · Passport Linked
            </Text>
          </div>
          <IdentityScore score={profile.identityScore} size={64} strokeWidth={5} />
        </div>

        {/* Travel Score + Location */}
        <div className="mt-4 grid grid-cols-2 gap-2">
          <Surface
            variant="plain"
            radius="input"
            className="flex items-center gap-2.5 px-3 py-2.5"
          >
            <Trophy className="w-4 h-4 text-[hsl(var(--p7-warning))]" />
            <div>
              <Text variant="caption-2" tone="tertiary">
                Travel Score
              </Text>
              <Text variant="body-em" tone="primary" className="tabular-nums">
                {travelScore.score}
                <span className="text-p7-caption-2 text-ink-tertiary font-normal"> / 100</span>
              </Text>
            </div>
          </Surface>
          <Surface
            variant="plain"
            radius="input"
            className="flex items-center gap-2.5 px-3 py-2.5"
          >
            <MapPin className="w-4 h-4 text-state-accent" />
            <div className="min-w-0">
              <Text variant="caption-2" tone="tertiary">
                Currently in
              </Text>
              <Text variant="body-em" tone="primary" truncate>
                {location.countryFlag} {location.country}
              </Text>
            </div>
          </Surface>
        </div>
      </div>
    </Surface>
  );
};

export default ProfileCard;
