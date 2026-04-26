import * as React from "react";
import * as SwitchPrimitive from "@radix-ui/react-switch";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";

/**
 * Toggle — on/off switch.
 *
 * Built on `@radix-ui/react-switch` so a11y (`role="switch"`,
 * `aria-checked`, keyboard) is correct without intervention. The thumb
 * uses a `motion.span` with a spring transition so the slide reads as
 * physical rather than ducktyped tween.
 *
 * The track shows a soft brand fill when checked; unchecked uses
 * `surface-overlay` so it sits visibly on either Paper or Atmosphere
 * without a heavy border.
 */

export type ToggleProps = React.ComponentPropsWithoutRef<
  typeof SwitchPrimitive.Root
>;

export const Toggle = React.forwardRef<
  React.ComponentRef<typeof SwitchPrimitive.Root>,
  ToggleProps
>(({ className, ...rest }, ref) => {
  return (
    <SwitchPrimitive.Root
      ref={ref}
      className={cn(
        "peer relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full",
        "border border-transparent",
        "data-[state=unchecked]:bg-surface-overlay",
        "data-[state=checked]:bg-brand",
        "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]",
        "focus-visible:ring-offset-2 focus-visible:ring-offset-[hsl(var(--p7-ring-offset))]",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "transition-colors duration-p7-pop ease-p7-standard",
        className,
      )}
      {...rest}
    >
      <SwitchPrimitive.Thumb asChild>
        <motion.span
          layout
          transition={spring.snap}
          className={cn(
            "pointer-events-none block h-5 w-5 rounded-full bg-surface-elevated shadow-p7-sm",
            "data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0",
          )}
        />
      </SwitchPrimitive.Thumb>
    </SwitchPrimitive.Root>
  );
});
Toggle.displayName = "Toggle";
