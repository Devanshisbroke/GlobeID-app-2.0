import * as React from "react";
import { Drawer as Vaul } from "vaul";
import { cn } from "@/lib/utils";

/**
 * Sheet — bottom-anchored drawer with native drag-to-dismiss.
 *
 * Built on `vaul` (already a project dependency) which provides the
 * physics-correct drag interaction iOS users expect: rubber-band at the
 * top, velocity-based dismiss, snap-back to the open state when the drag
 * ends below the dismissal velocity threshold.
 *
 * The sheet is always full-bleed at the bottom and rounds only the top
 * corners; this is the established Detail→Modal morph target chosen in
 * Q4 ("vaul-sheet"). Use `Sheet` for any flow that lifts up from the
 * bottom: filters, edit dialogs, action sheets, picker overlays.
 *
 * For center-screen dialogs with no drag affordance, use `Modal` instead.
 */

const Root = Vaul.Root;
const Trigger = Vaul.Trigger;
const Close = Vaul.Close;
const Portal = Vaul.Portal;
const Overlay = React.forwardRef<
  React.ComponentRef<typeof Vaul.Overlay>,
  React.ComponentPropsWithoutRef<typeof Vaul.Overlay>
>(({ className, ...rest }, ref) => (
  <Vaul.Overlay
    ref={ref}
    className={cn(
      "fixed inset-0 z-50 bg-black/40 backdrop-blur-[2px]",
      className,
    )}
    {...rest}
  />
));
Overlay.displayName = "Sheet.Overlay";

type ContentProps = React.ComponentPropsWithoutRef<typeof Vaul.Content> & {
  title?: React.ReactNode;
  description?: React.ReactNode;
  /** Show the small drag handle at the top of the sheet. Defaults true. */
  showHandle?: boolean;
};

const Content = React.forwardRef<
  React.ComponentRef<typeof Vaul.Content>,
  ContentProps
>(
  (
    { className, children, title, description, showHandle = true, ...rest },
    ref,
  ) => (
    <Portal>
      <Overlay />
      <Vaul.Content
        ref={ref}
        className={cn(
          "fixed inset-x-0 bottom-0 z-50",
          "flex flex-col",
          "max-h-[92vh] outline-none",
          "rounded-t-p7-sheet border-t border-x border-surface-hairline",
          "bg-surface-elevated text-ink-primary shadow-p7-overlay",
          // Safe-area padding (Android nav bar / iOS home indicator)
          "pb-[max(env(safe-area-inset-bottom),0px)]",
          className,
        )}
        {...rest}
      >
        {showHandle ? (
          <div className="mx-auto mt-2 mb-1 h-1 w-10 rounded-full bg-surface-hairline" />
        ) : null}
        {(title || description) && (
          <header className="px-6 pt-3 pb-2 flex flex-col gap-1">
            {title ? (
              <Vaul.Title className="text-p7-title-2 text-ink-primary">
                {title}
              </Vaul.Title>
            ) : null}
            {description ? (
              <Vaul.Description className="text-p7-callout text-ink-secondary">
                {description}
              </Vaul.Description>
            ) : null}
          </header>
        )}
        <div className="flex-1 overflow-y-auto px-6 pb-6">{children}</div>
      </Vaul.Content>
    </Portal>
  ),
);
Content.displayName = "Sheet.Content";

export const Sheet = Object.assign(Root, {
  Trigger,
  Close,
  Content,
});
