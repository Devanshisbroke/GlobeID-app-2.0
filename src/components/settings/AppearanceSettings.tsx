import React, { useState } from "react";
import AccentPicker from "./AccentPicker";
import { Surface, Text, Toggle } from "@/components/ui/v2";
import {
  getThemePrefs,
  setReduceTransparency,
  setDensity,
  setHighContrast,
  setAutoTimeOfDay,
  type Density,
} from "@/lib/themePrefs";
import {
  getQuietHours,
  setQuietHours,
  type QuietHoursPrefs,
} from "@/core/scheduledJobs";
import {
  CHANNEL_LABELS,
  NOTIFICATION_CHANNELS,
  getChannelPrefs,
  setChannelPref,
  type NotificationChannel,
  type NotificationChannelPrefs,
} from "@/lib/notificationChannels";
import { haptics } from "@/utils/haptics";

/**
 * AppearanceSettings — single panel surfacing every persisted user
 * preference shipped in this PR:
 *
 *  - Accent picker (8 hues; live-updates `--p7-brand` token).
 *  - Reduce transparency toggle (replaces glass with solid surfaces).
 *  - Quiet hours toggle (gates the nightly + weekly scheduled-jobs
 *    push during the user-defined window).
 *
 * Each control is wired to the underlying lib so the change persists
 * to localStorage and is applied immediately. ≥44px hit targets,
 * focus rings, haptics on each interaction.
 */
const AppearanceSettings: React.FC = () => {
  const [reduceTransparency, setLocalReduceTransparency] = useState<boolean>(
    () => getThemePrefs().reduceTransparency,
  );
  const [density, setLocalDensity] = useState<Density>(
    () => getThemePrefs().density,
  );
  const [highContrast, setLocalHighContrast] = useState<boolean>(
    () => getThemePrefs().highContrast,
  );
  const [autoTime, setLocalAutoTime] = useState<boolean>(
    () => getThemePrefs().autoTimeOfDay,
  );
  const [quiet, setLocalQuiet] = useState<QuietHoursPrefs>(getQuietHours);
  const [channelPrefs, setChannelPrefsState] = useState<NotificationChannelPrefs>(
    () => getChannelPrefs(),
  );

  const onToggleChannel = (channel: NotificationChannel, next: boolean) => {
    const updated = setChannelPref(channel, next);
    setChannelPrefsState(updated);
    haptics.selection();
  };

  const onToggleReduce = (next: boolean) => {
    setLocalReduceTransparency(next);
    setReduceTransparency(next);
    haptics.light();
  };

  const onChangeDensity = (next: Density) => {
    setLocalDensity(next);
    setDensity(next);
    haptics.selection();
  };

  const onToggleHighContrast = (next: boolean) => {
    setLocalHighContrast(next);
    setHighContrast(next);
    haptics.light();
  };

  const onToggleAutoTime = (next: boolean) => {
    setLocalAutoTime(next);
    setAutoTimeOfDay(next);
    haptics.light();
  };

  const onToggleQuiet = (next: boolean) => {
    const updated = { ...quiet, enabled: next };
    setLocalQuiet(updated);
    setQuietHours(updated);
    haptics.light();
  };

  const onChangeQuietRange = (kind: "startHour" | "endHour", value: number) => {
    const updated = { ...quiet, [kind]: value };
    setLocalQuiet(updated);
    setQuietHours(updated);
  };

  return (
    <div className="space-y-3">
      <AccentPicker />

      {/* Density — Apple-style segmented control. Gates layout-spacing
          tokens via [data-density] CSS rules in index.css. */}
      <Surface variant="plain" radius="surface" className="px-4 py-3">
        <Text variant="body-em" tone="primary">
          Density
        </Text>
        <Text variant="caption-1" tone="tertiary" className="mb-2">
          Adjust UI spacing across every screen.
        </Text>
        <div
          role="radiogroup"
          aria-label="Density"
          className="flex gap-1.5 p-1 rounded-xl bg-surface-overlay/50"
        >
          {(["compact", "comfortable", "spacious"] as const).map((d) => (
            <button
              key={d}
              type="button"
              role="radio"
              aria-checked={density === d}
              onClick={() => onChangeDensity(d)}
              className={`flex-1 capitalize text-[12px] font-medium py-2 rounded-lg min-h-[44px] focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] ${
                density === d
                  ? "bg-[hsl(var(--p7-brand))] text-white"
                  : "text-foreground hover:bg-surface-elevated"
              }`}
            >
              {d}
            </button>
          ))}
        </div>
      </Surface>

      <Surface variant="plain" radius="surface" className="px-4 py-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex-1 min-w-0">
            <Text variant="body-em" tone="primary">
              Reduce transparency
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Replace glass surfaces with solid backgrounds.
            </Text>
          </div>
          <Toggle
            checked={reduceTransparency}
            onCheckedChange={onToggleReduce}
            aria-label="Toggle reduce transparency"
          />
        </div>
      </Surface>

      <Surface variant="plain" radius="surface" className="px-4 py-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex-1 min-w-0">
            <Text variant="body-em" tone="primary">
              High contrast
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Stronger borders, opaque text on every surface.
            </Text>
          </div>
          <Toggle
            checked={highContrast}
            onCheckedChange={onToggleHighContrast}
            aria-label="Toggle high contrast"
          />
        </div>
      </Surface>

      <Surface variant="plain" radius="surface" className="px-4 py-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex-1 min-w-0">
            <Text variant="body-em" tone="primary">
              Auto theme by time of day
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Light from 06:00, dark after 19:00 — follows your local clock.
            </Text>
          </div>
          <Toggle
            checked={autoTime}
            onCheckedChange={onToggleAutoTime}
            aria-label="Toggle auto theme by time of day"
          />
        </div>
      </Surface>

      <Surface variant="plain" radius="surface" className="px-4 py-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex-1 min-w-0">
            <Text variant="body-em" tone="primary">
              Quiet hours
            </Text>
            <Text variant="caption-1" tone="tertiary">
              Suppress non-urgent push between {String(quiet.startHour).padStart(2, "0")}:00 and {String(quiet.endHour).padStart(2, "0")}:00.
            </Text>
          </div>
          <Toggle
            checked={quiet.enabled}
            onCheckedChange={onToggleQuiet}
            aria-label="Toggle quiet hours"
          />
        </div>
        {quiet.enabled ? (
          <div className="mt-3 grid grid-cols-2 gap-3">
            <label className="block">
              <Text variant="caption-2" tone="tertiary">
                From
              </Text>
              <select
                value={quiet.startHour}
                onChange={(e) => onChangeQuietRange("startHour", Number(e.target.value))}
                className="mt-1 w-full rounded-p7-input border border-border bg-card text-foreground text-sm py-2 px-3 min-h-[44px] focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                aria-label="Quiet hours start"
              >
                {Array.from({ length: 24 }, (_, h) => (
                  <option key={h} value={h}>
                    {String(h).padStart(2, "0")}:00
                  </option>
                ))}
              </select>
            </label>
            <label className="block">
              <Text variant="caption-2" tone="tertiary">
                To
              </Text>
              <select
                value={quiet.endHour}
                onChange={(e) => onChangeQuietRange("endHour", Number(e.target.value))}
                className="mt-1 w-full rounded-p7-input border border-border bg-card text-foreground text-sm py-2 px-3 min-h-[44px] focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                aria-label="Quiet hours end"
              >
                {Array.from({ length: 24 }, (_, h) => (
                  <option key={h} value={h}>
                    {String(h).padStart(2, "0")}:00
                  </option>
                ))}
              </select>
            </label>
          </div>
        ) : null}
      </Surface>

      {/* Per-channel notification preferences (BACKLOG O 164). */}
      <Surface variant="plain" className="px-4 py-4">
        <Text variant="headline" tone="primary" className="font-semibold">
          Notification channels
        </Text>
        <Text variant="caption-1" tone="tertiary" className="mt-1">
          Pick which alerts the app may surface. Quiet hours still apply.
        </Text>
        <ul className="mt-3 divide-y divide-border/40">
          {NOTIFICATION_CHANNELS.map((channel) => {
            const meta = CHANNEL_LABELS[channel];
            return (
              <li
                key={channel}
                className="flex items-start justify-between gap-3 py-3"
              >
                <div className="flex-1 min-w-0">
                  <Text variant="body-1" tone="primary" className="font-medium">
                    {meta.title}
                  </Text>
                  <Text variant="caption-1" tone="tertiary" className="mt-0.5">
                    {meta.description}
                  </Text>
                </div>
                <Toggle
                  checked={channelPrefs[channel]}
                  onCheckedChange={(next) => onToggleChannel(channel, next)}
                  aria-label={`Toggle ${meta.title}`}
                />
              </li>
            );
          })}
        </ul>
      </Surface>
    </div>
  );
};

export default AppearanceSettings;
