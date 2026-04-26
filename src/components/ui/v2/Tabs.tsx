import * as React from "react";
import * as TabsPrimitive from "@radix-ui/react-tabs";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";

/**
 * Tabs — segmented control with shared-layout sliding indicator.
 *
 * Built on `@radix-ui/react-tabs` so a11y (`role="tab"`, arrow-key
 * navigation, `aria-selected`, manual / automatic activation) is correct.
 *
 * The active-state indicator is a `motion.span` with `layoutId`. Only the
 * **active trigger** mounts the indicator; switching tabs unmounts it from
 * the previous trigger and mounts it inside the new one — `motion`'s
 * shared-layout system springs the position seamlessly. No JS measuring.
 *
 * Two visual styles:
 *  - `segmented` (default): pill chip behind the label, on a tinted track.
 *  - `underline`: 2px brand bar below the active label, on a hairline.
 *
 * The variant is selected on `<Tabs.List variant="…">`. The active tab's
 * value is shared via context so triggers can render the indicator.
 */

type TabsVariant = "segmented" | "underline";

type TabsCtx = {
  value: string | undefined;
  variant: TabsVariant;
  /**
   * Unique-per-`<Tabs>`-instance ID used to scope the shared-layout
   * `layoutId` on the active indicator. Without this, two Tabs components
   * of the same variant on the same page would have motion spring the
   * indicator between unrelated tab groups.
   */
  instanceId: string;
};

const TabsContext = React.createContext<TabsCtx | null>(null);
const useTabsCtx = () => {
  const ctx = React.useContext(TabsContext);
  if (!ctx) throw new Error("Tabs.Trigger must be rendered inside <Tabs>");
  return ctx;
};

/* ──────────────────── Root ──────────────────── */

type RootProps = React.ComponentPropsWithoutRef<typeof TabsPrimitive.Root>;

const Root = React.forwardRef<
  React.ComponentRef<typeof TabsPrimitive.Root>,
  RootProps
>(({ value, defaultValue, onValueChange, children, ...rest }, ref) => {
  const [internal, setInternal] = React.useState<string | undefined>(
    typeof defaultValue === "string" ? defaultValue : undefined,
  );
  const isControlled = value !== undefined;
  const current = isControlled ? value : internal;

  const handleChange = React.useCallback(
    (next: string) => {
      if (!isControlled) setInternal(next);
      onValueChange?.(next);
    },
    [isControlled, onValueChange],
  );

  // `variant` is passed down from the List by mutating the context after the
  // first render of <Tabs.List>. Default to segmented; List overrides.
  const [variant, setVariant] = React.useState<TabsVariant>("segmented");

  // Stable per-instance ID — scopes the shared-layout `layoutId` on the
  // active indicator so multiple <Tabs> on the same page don't cross-animate.
  const instanceId = React.useId();

  const ctx = React.useMemo<TabsCtx>(
    () => ({ value: current, variant, instanceId }),
    [current, variant, instanceId],
  );

  return (
    <TabsContext.Provider value={ctx}>
      <_VariantSetterContext.Provider value={setVariant}>
        <TabsPrimitive.Root
          ref={ref}
          value={current}
          onValueChange={handleChange}
          {...rest}
        >
          {children}
        </TabsPrimitive.Root>
      </_VariantSetterContext.Provider>
    </TabsContext.Provider>
  );
});
Root.displayName = "Tabs";

const _VariantSetterContext = React.createContext<
  ((v: TabsVariant) => void) | null
>(null);

/* ──────────────────── List ──────────────────── */

const ListPrimitive = React.forwardRef<
  React.ComponentRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List> & {
    variant?: TabsVariant;
  }
>(({ className, variant = "segmented", ...rest }, ref) => {
  const setVariant = React.useContext(_VariantSetterContext);
  React.useEffect(() => {
    setVariant?.(variant);
  }, [setVariant, variant]);

  return (
    <TabsPrimitive.List
      ref={ref}
      className={cn(
        "relative inline-flex items-stretch",
        variant === "segmented"
          ? "gap-1 rounded-p7-input bg-surface-overlay p-1"
          : "gap-6 border-b border-surface-hairline",
        className,
      )}
      {...rest}
    />
  );
});
ListPrimitive.displayName = "Tabs.List";

/* ──────────────────── Trigger ──────────────────── */

const TriggerPrimitive = React.forwardRef<
  React.ComponentRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, children, value, ...rest }, ref) => {
  const { value: active, variant, instanceId } = useTabsCtx();
  const isActive = active === value;

  return (
    <TabsPrimitive.Trigger
      ref={ref}
      value={value}
      className={cn(
        "relative inline-flex items-center justify-center whitespace-nowrap",
        "px-3 text-p7-callout font-medium",
        "text-ink-secondary",
        "transition-colors duration-p7-tap ease-p7-standard",
        "outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] rounded-[calc(var(--p7-radius-input)-2px)]",
        "data-[state=active]:text-ink-primary",
        variant === "segmented" ? "h-8" : "pb-2 px-0 h-9",
        className,
      )}
      {...rest}
    >
      {/* Active indicator — only mounted on the active trigger; motion's
          shared-layout system springs it across triggers via layoutId. */}
      {isActive ? (
        variant === "segmented" ? (
          <motion.span
            layoutId={`${instanceId}-seg`}
            transition={spring.default}
            className="absolute inset-0 -z-0 rounded-[calc(var(--p7-radius-input)-2px)] bg-surface-elevated shadow-p7-sm"
            aria-hidden
          />
        ) : (
          <motion.span
            layoutId={`${instanceId}-underline`}
            transition={spring.default}
            className="absolute inset-x-0 -bottom-px h-0.5 rounded-full bg-brand"
            aria-hidden
          />
        )
      ) : null}
      <span className="relative z-10 inline-flex items-center gap-1.5">
        {children}
      </span>
    </TabsPrimitive.Trigger>
  );
});
TriggerPrimitive.displayName = "Tabs.Trigger";

/* ──────────────────── Content ──────────────────── */

const ContentPrimitive = React.forwardRef<
  React.ComponentRef<typeof TabsPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content>
>(({ className, ...rest }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={cn("outline-none", className)}
    {...rest}
  />
));
ContentPrimitive.displayName = "Tabs.Content";

export const Tabs = Object.assign(Root, {
  List: ListPrimitive,
  Trigger: TriggerPrimitive,
  Content: ContentPrimitive,
});
