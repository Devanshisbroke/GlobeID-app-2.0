import React, { useState, useCallback } from "react";
import { motion } from "motion/react";
import { Check } from "lucide-react";
import { ACCENTS, getThemePrefs, setAccent, type AccentOption } from "@/lib/themePrefs";
import { Surface, Text } from "@/components/ui/v2";
import { haptics } from "@/utils/haptics";
import { cn } from "@/lib/utils";

/**
 * Apple-style accent picker — 8 hue swatches in a single row that
 * scrolls horizontally on narrow screens. Tap a swatch to set the
 * `--p7-brand` HSL token globally; persisted to localStorage.
 *
 * - 44px hit target on every swatch (`min-h-[44px] min-w-[44px]`).
 * - layoutId on the selected ring so it springs across when you pick a
 *   different swatch.
 * - haptics.medium() on selection so the change feels confirmed.
 * - honours prefers-reduced-motion via motion@12's automatic ramp-down
 *   (we don't animate large layout, just the ring).
 */
const AccentPicker: React.FC = () => {
  const [accentId, setAccentId] = useState<string>(getThemePrefs().accentId);

  const choose = useCallback((accent: AccentOption) => {
    setAccent(accent.id);
    setAccentId(accent.id);
    haptics.medium();
  }, []);

  return (
    <Surface variant="plain" radius="surface" className="px-4 py-4">
      <Text variant="caption-1" tone="tertiary" className="uppercase tracking-[0.18em]">
        Accent
      </Text>
      <div className="mt-3 flex gap-3 overflow-x-auto pb-1 -mx-1 px-1">
        {ACCENTS.map((a) => {
          const selected = a.id === accentId;
          return (
            <button
              key={a.id}
              type="button"
              onClick={() => choose(a)}
              aria-label={`Set accent ${a.name}`}
              aria-pressed={selected}
              className={cn(
                "relative shrink-0 inline-flex items-center justify-center",
                "min-h-[44px] min-w-[44px] rounded-full",
                "transition-transform active:scale-[0.92] focus:outline-none",
                "focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] focus-visible:ring-offset-2 focus-visible:ring-offset-surface-base",
              )}
              style={{
                backgroundColor: `hsl(${a.hsl})`,
                touchAction: "manipulation",
              }}
            >
              {selected ? (
                <motion.span
                  layoutId="accent-ring"
                  className="absolute inset-0 rounded-full ring-2 ring-white/95 ring-offset-2 ring-offset-surface-base pointer-events-none"
                  transition={{ type: "spring", stiffness: 480, damping: 32 }}
                />
              ) : null}
              {selected ? (
                <Check className="w-4 h-4 text-white drop-shadow-[0_1px_3px_rgba(0,0,0,0.5)]" strokeWidth={3} />
              ) : null}
            </button>
          );
        })}
      </div>
    </Surface>
  );
};

export default AccentPicker;
