import * as React from "react";

/**
 * Phase 7 PR-γ — context + hook for the global command palette.
 *
 * Lives in its own file (separate from `CommandPalette.tsx`) so the
 * `react-refresh/only-export-components` lint rule stays clean for the
 * provider component.
 */

export type CommandPaletteCtx = {
  open: boolean;
  setOpen: (open: boolean) => void;
  toggle: () => void;
};

export const CommandPaletteContext =
  React.createContext<CommandPaletteCtx | null>(null);

export const useCommandPalette = (): CommandPaletteCtx => {
  const ctx = React.useContext(CommandPaletteContext);
  if (!ctx) {
    throw new Error(
      "useCommandPalette must be used inside <CommandPaletteProvider>",
    );
  }
  return ctx;
};
