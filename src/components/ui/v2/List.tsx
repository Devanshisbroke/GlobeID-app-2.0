import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";
import { spring } from "@/lib/motion-tokens";

/**
 * List — composable, hairline-separated row group.
 *
 * Usage:
 *   <List>
 *     <List.Item leading={…} trailing={…}>Title</List.Item>
 *     <List.Item asChild><a href="…">Linked</a></List.Item>
 *   </List>
 *
 * Items are full-bleed (no internal padding on the List wrapper) so they
 * stretch to the rounded surface they live inside. Hairline separators
 * are applied via `divide-y` on the List rather than per-item borders so
 * the first / last items stay clean.
 *
 * Items consume `motion`'s spring tap response when they're interactive
 * (have an `onClick`, `href`, etc.). Non-interactive items (display-only
 * meta rows) skip the press animation entirely.
 */

export type ListProps = React.HTMLAttributes<HTMLUListElement> & {
  asChild?: boolean;
};

const ListRoot = React.forwardRef<HTMLUListElement, ListProps>(
  ({ className, asChild, ...rest }, ref) => {
    const Comp = asChild ? Slot : "ul";
    return (
      <Comp
        ref={ref as React.Ref<HTMLUListElement>}
        className={cn(
          "flex flex-col divide-y divide-surface-hairline",
          className,
        )}
        {...(rest as React.HTMLAttributes<HTMLElement>)}
      />
    );
  },
);
ListRoot.displayName = "List";

/* ──────────────────── Item ──────────────────── */

export type ListItemProps = React.LiHTMLAttributes<HTMLLIElement> & {
  asChild?: boolean;
  leading?: React.ReactNode;
  trailing?: React.ReactNode;
  /** Subtitle rendered below the main label in caption-1 ink-secondary. */
  description?: React.ReactNode;
  /**
   * If `true`, applies tap-press animation. Inferred from `onClick`, `href`,
   * or `tabIndex`; explicit `interactive={false}` suppresses it.
   */
  interactive?: boolean;
};

const ListItem = React.forwardRef<HTMLLIElement, ListItemProps>(
  (
    {
      className,
      asChild,
      leading,
      trailing,
      description,
      interactive,
      onClick,
      children,
      ...rest
    },
    ref,
  ) => {
    const isInteractive =
      interactive ?? Boolean(onClick || (rest as { href?: string }).href);

    const inner = (
      <>
        {leading ? (
          <span className="shrink-0 [&>svg]:h-5 [&>svg]:w-5 text-ink-secondary">
            {leading}
          </span>
        ) : null}
        <span className="flex min-w-0 flex-1 flex-col">
          <span className="truncate text-p7-body-em text-ink-primary">
            {children}
          </span>
          {description ? (
            <span className="truncate text-p7-caption-1 text-ink-tertiary">
              {description}
            </span>
          ) : null}
        </span>
        {trailing ? (
          <span className="shrink-0 [&>svg]:h-5 [&>svg]:w-5 text-ink-tertiary">
            {trailing}
          </span>
        ) : null}
      </>
    );

    const wrapperClass = cn(
      "flex items-center gap-3 px-4 py-3",
      isInteractive
        ? "cursor-pointer select-none transition-colors duration-p7-tap ease-p7-standard hover:bg-surface-overlay/60 active:bg-surface-overlay"
        : "",
      className,
    );

    if (asChild) {
      return (
        <li className={wrapperClass} {...rest}>
          <Slot ref={ref as React.Ref<HTMLElement>} className="contents">
            {children as React.ReactElement}
          </Slot>
        </li>
      );
    }

    if (isInteractive) {
      return (
        <motion.li
          ref={ref}
          whileTap={{ backgroundColor: "hsl(var(--p7-surface-overlay))" }}
          transition={spring.snap}
          className={wrapperClass}
          onClick={onClick}
          {...(rest as Omit<typeof rest, "onAnimationStart" | "onDragStart" | "onDragEnd" | "onDrag">)}
        >
          {inner}
        </motion.li>
      );
    }

    return (
      <li ref={ref} className={wrapperClass} {...rest}>
        {inner}
      </li>
    );
  },
);
ListItem.displayName = "List.Item";

export const List = Object.assign(ListRoot, { Item: ListItem });
