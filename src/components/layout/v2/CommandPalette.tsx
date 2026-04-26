import * as React from "react";
import { useNavigate } from "react-router-dom";
import {
  Home,
  Shield,
  Wallet,
  Plane,
  LayoutGrid,
  Globe2,
  ScanLine,
  Sparkles,
  History,
  MapPin,
  CreditCard,
  Building2,
  Car,
  UtensilsCrossed,
  Compass,
  BookOpen,
  Users,
  Briefcase,
  type LucideIcon,
} from "lucide-react";
import { CommandBar } from "@/components/ui/v2/CommandBar";
import {
  CommandPaletteContext,
  type CommandPaletteCtx,
} from "./use-command-palette";

/**
 * CommandPalette — Phase 7 PR-γ.
 *
 * Raycast-style global command palette wired into the app shell. Composed of:
 *  - A `CommandPaletteProvider` that owns the open/closed state and exposes
 *    it via context.
 *  - A `useCommandPalette` hook for opt-in callers (e.g. a header button).
 *  - A `<Cmd+K>` global keyboard listener that toggles open.
 *  - A static registry of all 25 routes + curated quick actions.
 *
 * The registry is intentionally a plain const — adding a new route requires
 * editing the array, which forces a code review surface for new commands
 * (we don't want app-internal screens to silently leak into the palette).
 *
 * The visual primitive is `CommandBar` from PR-β. This file is the
 * route registry + global hotkey wrapper, not the visual primitive.
 */

type CommandEntry = {
  id: string;
  label: string;
  /** Free-text keywords for fuzzy matching beyond the label. */
  keywords?: string[];
  icon?: LucideIcon;
  /** Display-only keyboard shortcut for the row. */
  shortcut?: string;
} & (
  | { kind: "navigate"; path: string }
  | { kind: "action"; perform: (nav: ReturnType<typeof useNavigate>) => void }
);

type CommandGroup = {
  heading: string;
  entries: CommandEntry[];
};

/* ──────────────────── Registry ──────────────────── */

const COMMANDS: CommandGroup[] = [
  {
    heading: "Navigate",
    entries: [
      { id: "nav-home", kind: "navigate", path: "/", label: "Home", icon: Home, keywords: ["dashboard", "today"] },
      { id: "nav-identity", kind: "navigate", path: "/identity", label: "Identity", icon: Shield, keywords: ["passport", "kyc", "verify"] },
      { id: "nav-wallet", kind: "navigate", path: "/wallet", label: "Wallet", icon: Wallet, keywords: ["money", "cards", "balance"] },
      { id: "nav-travel", kind: "navigate", path: "/travel", label: "Travel", icon: Plane, keywords: ["trips", "flights"] },
      { id: "nav-map", kind: "navigate", path: "/map", label: "Map", icon: Globe2, keywords: ["globe", "world"] },
      { id: "nav-services", kind: "navigate", path: "/services", label: "Services", icon: LayoutGrid, keywords: ["concierge", "hub"] },
    ],
  },
  {
    heading: "Quick actions",
    entries: [
      { id: "act-plan", kind: "navigate", path: "/planner", label: "Plan a trip", icon: Sparkles, shortcut: "⌘T", keywords: ["new", "create", "itinerary"] },
      { id: "act-scan", kind: "navigate", path: "/kiosk-sim", label: "Scan at kiosk", icon: ScanLine, keywords: ["entry", "passport scan", "border"] },
      { id: "act-receipt", kind: "navigate", path: "/receipt", label: "Open last entry receipt", icon: History, keywords: ["receipt", "border", "stamp"] },
      { id: "act-pay", kind: "navigate", path: "/wallet", label: "Add payment method", icon: CreditCard, shortcut: "⌘P", keywords: ["card", "money"] },
      { id: "act-copilot", kind: "navigate", path: "/copilot", label: "Ask Travel Copilot", icon: Sparkles, shortcut: "⌘K K", keywords: ["ai", "chat", "assistant"] },
    ],
  },
  {
    heading: "Services",
    entries: [
      { id: "srv-hotels", kind: "navigate", path: "/services/hotels", label: "Find a hotel", icon: Building2, keywords: ["stay", "accommodation"] },
      { id: "srv-rides", kind: "navigate", path: "/services/rides", label: "Book a ride", icon: Car, keywords: ["taxi", "uber", "transport"] },
      { id: "srv-food", kind: "navigate", path: "/services/food", label: "Discover food", icon: UtensilsCrossed, keywords: ["restaurant", "eat", "dining"] },
      { id: "srv-act", kind: "navigate", path: "/services/activities", label: "Find activities", icon: Compass, keywords: ["tour", "experience", "things to do"] },
      { id: "srv-trans", kind: "navigate", path: "/services/transport", label: "Local transport", icon: Briefcase, keywords: ["bus", "metro", "rail"] },
    ],
  },
  {
    heading: "Discover",
    entries: [
      { id: "dis-explore", kind: "navigate", path: "/explore", label: "Explore", icon: Compass, keywords: ["discover", "map", "places"] },
      { id: "dis-social", kind: "navigate", path: "/social", label: "Social feed", icon: Users, keywords: ["friends", "feed"] },
      { id: "dis-intel", kind: "navigate", path: "/intelligence", label: "Travel intelligence", icon: MapPin, keywords: ["alerts", "insights"] },
      { id: "dis-vault", kind: "navigate", path: "/passport-book", label: "Passport book", icon: BookOpen, keywords: ["stamps", "history"] },
      { id: "dis-explorer", kind: "navigate", path: "/explorer", label: "Planet explorer", icon: Globe2, keywords: ["3d", "globe"] },
    ],
  },
];

/* ──────────────────── Provider ──────────────────── */

interface ProviderProps {
  children: React.ReactNode;
}

const CommandPaletteProvider: React.FC<ProviderProps> = ({ children }) => {
  const [open, setOpen] = React.useState(false);
  const navigate = useNavigate();

  const toggle = React.useCallback(() => setOpen((o) => !o), []);

  // Global Cmd+K / Ctrl+K hotkey. We listen at window level so the palette
  // is reachable from anywhere — input fields included (preventDefault on
  // the modifier combination).
  React.useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      // Skip auto-repeated keydown events so long-press doesn't toggle wildly.
      if (event.repeat) return;

      const isCmdK =
        event.key.toLowerCase() === "k" && (event.metaKey || event.ctrlKey);
      if (!isCmdK) return;

      event.preventDefault();
      setOpen((prev) => !prev);
    };

    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  const ctx = React.useMemo<CommandPaletteCtx>(
    () => ({ open, setOpen, toggle }),
    [open, toggle],
  );

  const handleSelect = React.useCallback(
    (entry: CommandEntry) => {
      setOpen(false);
      // Defer the navigation by one tick so the close animation can start
      // before route change kicks off — prevents a perceptible jank on
      // slower Android WebViews.
      window.setTimeout(() => {
        if (entry.kind === "navigate") {
          navigate(entry.path);
        } else {
          entry.perform(navigate);
        }
      }, 0);
    },
    [navigate],
  );

  return (
    <CommandPaletteContext.Provider value={ctx}>
      {children}
      <CommandBar open={open} onOpenChange={setOpen}>
        {COMMANDS.map((group) => (
          <CommandBar.Group key={group.heading} heading={group.heading}>
            {group.entries.map((entry) => {
              const Icon = entry.icon;
              return (
                <CommandBar.Item
                  key={entry.id}
                  value={`${entry.label} ${entry.keywords?.join(" ") ?? ""}`}
                  icon={Icon ? <Icon /> : undefined}
                  shortcut={entry.shortcut}
                  onSelect={() => handleSelect(entry)}
                >
                  {entry.label}
                </CommandBar.Item>
              );
            })}
          </CommandBar.Group>
        ))}
      </CommandBar>
    </CommandPaletteContext.Provider>
  );
};

export default CommandPaletteProvider;
