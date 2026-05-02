import React, { useState } from "react";
import AccentPicker from "./AccentPicker";
import { Surface, Text, Toggle } from "@/components/ui/v2";
import {
  getThemePrefs,
  setReduceTransparency,
} from "@/lib/themePrefs";
import {
  getQuietHours,
  setQuietHours,
  type QuietHoursPrefs,
} from "@/core/scheduledJobs";
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
  const [quiet, setLocalQuiet] = useState<QuietHoursPrefs>(getQuietHours);

  const onToggleReduce = (next: boolean) => {
    setLocalReduceTransparency(next);
    setReduceTransparency(next);
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
    </div>
  );
};

export default AppearanceSettings;
