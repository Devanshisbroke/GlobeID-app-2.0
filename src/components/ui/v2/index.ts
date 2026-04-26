/**
 * v2 component primitives — Phase 7 PR-β.
 *
 * Live alongside the legacy shadcn primitives in `src/components/ui/`;
 * existing screens keep importing the old ones until each migrates in
 * PR-δ / PR-ε / PR-ζ. Once Phase 7 closes, the legacy primitives can be
 * removed in a final cleanup pass.
 *
 * Convention: import primitives by name, not as a namespace, so the
 * tree-shake is clean:
 *
 *   import { Surface, Button, Pill, List } from "@/components/ui/v2";
 *
 * Compound components (Tabs, List, Modal, Sheet, Toast, CommandBar) are
 * exported as a single object whose static fields are the sub-parts:
 *
 *   <Tabs.List variant="underline">
 *     <Tabs.Trigger value="a">A</Tabs.Trigger>
 *   </Tabs.List>
 */

export { Surface, type SurfaceProps } from "./Surface";
export { Button, type ButtonProps } from "./Button";
export { Pill, type PillProps } from "./Pill";
export { Avatar, type AvatarProps } from "./Avatar";
export { Toggle, type ToggleProps } from "./Toggle";
export { Field, Input, Textarea, type FieldProps, type InputProps, type TextareaProps } from "./Field";
export { List, type ListProps, type ListItemProps } from "./List";
export { Tabs } from "./Tabs";
export { Modal } from "./Modal";
export { Sheet } from "./Sheet";
export { Toast } from "./Toast";
export { CommandBar } from "./CommandBar";
export { Text, type TextProps } from "./Text";

// Re-export motion tokens so screens migrating in PR-δ/ε/ζ can pull
// `spring`, `ease`, `duration` from a single import alongside the
// primitives they consume.
export { spring, ease, duration, stagger } from "@/lib/motion-tokens";
