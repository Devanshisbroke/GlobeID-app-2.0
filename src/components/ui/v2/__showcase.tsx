/**
 * v2 primitives — visual showcase / smoke route.
 *
 * Mounted at `/__v2` only when `import.meta.env.DEV` is true. This is
 * NOT a user-facing feature — it's the visual review surface for PR-β
 * and the migration reference for PR-δ / ε / ζ.
 *
 * Removed in PR-ζ along with the legacy shadcn primitives once all
 * screens have migrated.
 */
import { useState } from "react";
import {
  Avatar,
  Button,
  CommandBar,
  Field,
  Input,
  List,
  Modal,
  Pill,
  Sheet,
  Surface,
  Tabs,
  Text,
  Textarea,
  Toast,
  Toggle,
} from "@/components/ui/v2";
import {
  ArrowRight,
  Bell,
  Compass,
  CreditCard,
  Globe2,
  Plane,
  Settings,
  Shield,
  User,
  Wallet as WalletIcon,
} from "lucide-react";

export default function V2Showcase() {
  return (
    <div className="min-h-dvh bg-surface-base text-ink-primary">
      <div className="mx-auto max-w-3xl px-4 py-8 space-y-8">
        <header className="flex items-center justify-between">
          <div className="flex flex-col">
            <Text variant="display" tone="primary">
              v2 primitives
            </Text>
            <Text variant="callout" tone="secondary">
              Phase 7 PR-β · dev-only smoke route at /__v2
            </Text>
          </div>
          <Pill tone="brand" weight="solid" dot pulse>
            β
          </Pill>
        </header>

        <Section title="Type scale">
          <TypeRow />
        </Section>

        <Section title="Surfaces">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <Surface variant="plain" className="p-4">
              <Text variant="title-3">Plain</Text>
              <Text variant="callout" tone="secondary">
                Hairline border. Most cards.
              </Text>
            </Surface>
            <Surface variant="elevated" className="p-4">
              <Text variant="title-3">Elevated</Text>
              <Text variant="callout" tone="secondary">
                Lifted with soft shadow.
              </Text>
            </Surface>
            <Surface variant="glass" className="p-4">
              <Text variant="title-3">Glass</Text>
              <Text variant="callout" tone="secondary">
                Chrome-only — nav, palette.
              </Text>
            </Surface>
          </div>
        </Section>

        <Section title="Buttons">
          <ButtonGrid />
        </Section>

        <Section title="Pills">
          <PillGrid />
        </Section>

        <Section title="List">
          <Surface variant="plain" radius="surface" className="overflow-hidden">
            <List>
              <List.Item
                leading={<User />}
                trailing={<ArrowRight />}
                description="Profile, identity, security keys"
                onClick={() => undefined}
              >
                Account
              </List.Item>
              <List.Item
                leading={<WalletIcon />}
                trailing={<Pill tone="accent">Synced</Pill>}
                description="3 connected accounts · last hydrate 2 min ago"
                onClick={() => undefined}
              >
                Wallet
              </List.Item>
              <List.Item
                leading={<Plane />}
                trailing={<Pill tone="brand">7 upcoming</Pill>}
                description="LHR → CDG → DXB · departs Tue 9:40am"
                onClick={() => undefined}
              >
                Travel
              </List.Item>
              <List.Item
                leading={<Bell />}
                trailing={<Toggle defaultChecked />}
                interactive={false}
              >
                Alerts
              </List.Item>
            </List>
          </Surface>
        </Section>

        <Section title="Avatars">
          <div className="flex items-end gap-3">
            <Avatar size="xs" alt="Aria Stone" />
            <Avatar size="sm" alt="Ben Lee" />
            <Avatar size="md" alt="Cara Doe" />
            <Avatar size="lg" alt="Devansh Barai" />
            <Avatar size="xl" alt="Elena Park" />
          </div>
        </Section>

        <Section title="Toggles">
          <div className="flex items-center gap-6">
            <Toggle defaultChecked aria-label="Enabled" />
            <Toggle aria-label="Disabled" />
          </div>
        </Section>

        <Section title="Field & inputs">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Field label="Full name" hint="As shown on your passport.">
              <Input placeholder="Devansh Barai" defaultValue="" />
            </Field>
            <Field
              label="Passport number"
              error="Format must match XXNNNNNNN"
              required
            >
              <Input placeholder="L4521389" invalid />
            </Field>
            <Field label="Notes" htmlFor="notes" className="sm:col-span-2">
              <Textarea
                id="notes"
                placeholder="Anything we should know about this trip?"
              />
            </Field>
          </div>
        </Section>

        <Section title="Tabs">
          <TabsRow />
        </Section>

        <Section title="Overlays">
          <OverlayRow />
        </Section>
      </div>
    </div>
  );
}

/* ──────────────────── Helpers ──────────────────── */

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="space-y-3">
      <Text variant="caption-2" tone="tertiary" className="uppercase tracking-[0.08em]">
        {title}
      </Text>
      {children}
    </section>
  );
}

function TypeRow() {
  const rows: Array<{
    variant:
      | "display"
      | "title-1"
      | "title-2"
      | "title-3"
      | "body"
      | "body-em"
      | "callout"
      | "caption-1"
      | "caption-2";
    label: string;
    sample: string;
  }> = [
    { variant: "display", label: "Display 40 / 600", sample: "GlobeID" },
    { variant: "title-1", label: "Title 1 28 / 600", sample: "Welcome back, Aria" },
    { variant: "title-2", label: "Title 2 22 / 600", sample: "Upcoming flights" },
    { variant: "title-3", label: "Title 3 17 / 600", sample: "Connected accounts" },
    { variant: "body-em", label: "Body em 15 / 500", sample: "Boarding starts in 32 minutes." },
    { variant: "body", label: "Body 15 / 400", sample: "Your identity is verified across 14 borders." },
    { variant: "callout", label: "Callout 14 / 400", sample: "Sync runs hourly while online." },
    { variant: "caption-1", label: "Caption 1 12 / 400", sample: "Last sync · 2 min ago" },
    { variant: "caption-2", label: "Caption 2 11 / 500", sample: "TX-LHR-CDG-04A" },
  ];
  return (
    <Surface variant="plain" className="divide-y divide-surface-hairline">
      {rows.map((r) => (
        <div key={r.variant} className="flex items-baseline justify-between gap-6 px-4 py-3">
          <Text variant={r.variant} tone="primary" truncate>
            {r.sample}
          </Text>
          <Text variant="caption-2" tone="tertiary" className="shrink-0 font-mono">
            {r.label}
          </Text>
        </div>
      ))}
    </Surface>
  );
}

function ButtonGrid() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
      <div className="flex flex-col gap-2">
        <Text variant="caption-1" tone="tertiary">Variants</Text>
        <div className="flex flex-wrap gap-2">
          <Button variant="primary">Primary</Button>
          <Button variant="secondary">Secondary</Button>
          <Button variant="ghost">Ghost</Button>
          <Button variant="subtle">Subtle</Button>
          <Button variant="critical">Critical</Button>
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Text variant="caption-1" tone="tertiary">Sizes</Text>
        <div className="flex flex-wrap items-center gap-2">
          <Button size="sm">Small</Button>
          <Button size="md">Medium</Button>
          <Button size="lg">Large</Button>
          <Button size="icon" aria-label="Settings"><Settings /></Button>
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Text variant="caption-1" tone="tertiary">With glyphs</Text>
        <div className="flex flex-wrap gap-2">
          <Button leading={<Compass />}>Explore</Button>
          <Button trailing={<ArrowRight />} variant="secondary">Continue</Button>
          <Button leading={<Shield />} variant="subtle">Verify</Button>
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Text variant="caption-1" tone="tertiary">States</Text>
        <div className="flex flex-wrap gap-2">
          <Button loading>Loading</Button>
          <Button disabled>Disabled</Button>
        </div>
      </div>
    </div>
  );
}

function PillGrid() {
  const tones: Array<"neutral" | "brand" | "accent" | "warning" | "critical"> = [
    "neutral",
    "brand",
    "accent",
    "warning",
    "critical",
  ];
  const weights: Array<"tinted" | "solid" | "outline"> = [
    "tinted",
    "solid",
    "outline",
  ];
  return (
    <div className="space-y-3">
      {weights.map((w) => (
        <div key={w} className="flex items-center gap-3 flex-wrap">
          <Text variant="caption-1" tone="tertiary" className="w-16 shrink-0">
            {w}
          </Text>
          {tones.map((t) => (
            <Pill key={t} tone={t} weight={w}>
              {t}
            </Pill>
          ))}
          <Pill tone="accent" weight={w} dot pulse>
            live
          </Pill>
        </div>
      ))}
    </div>
  );
}

function TabsRow() {
  const [seg, setSeg] = useState("balance");
  const [und, setUnd] = useState("upcoming");
  return (
    <div className="space-y-4">
      <div>
        <Tabs value={seg} onValueChange={setSeg}>
          <Tabs.List variant="segmented">
            <Tabs.Trigger value="balance">Balance</Tabs.Trigger>
            <Tabs.Trigger value="activity">Activity</Tabs.Trigger>
            <Tabs.Trigger value="analytics">Analytics</Tabs.Trigger>
          </Tabs.List>
          <div className="mt-3">
            <Surface variant="plain" className="p-4">
              <Text variant="callout" tone="secondary">
                Active: {seg}
              </Text>
            </Surface>
          </div>
        </Tabs>
      </div>
      <div>
        <Tabs value={und} onValueChange={setUnd}>
          <Tabs.List variant="underline">
            <Tabs.Trigger value="upcoming">Upcoming</Tabs.Trigger>
            <Tabs.Trigger value="past">Past</Tabs.Trigger>
            <Tabs.Trigger value="all">All</Tabs.Trigger>
          </Tabs.List>
          <div className="mt-3">
            <Surface variant="plain" className="p-4">
              <Text variant="callout" tone="secondary">
                Active: {und}
              </Text>
            </Surface>
          </div>
        </Tabs>
      </div>
    </div>
  );
}

function OverlayRow() {
  const [modal, setModal] = useState(false);
  const [sheet, setSheet] = useState(false);
  const [cmd, setCmd] = useState(false);
  const [toast, setToast] = useState(false);
  return (
    <Toast.Provider>
      <div className="flex flex-wrap gap-2">
        <Button variant="secondary" onClick={() => setModal(true)}>
          Open modal
        </Button>
        <Button variant="secondary" onClick={() => setSheet(true)}>
          Open sheet
        </Button>
        <Button variant="secondary" onClick={() => setCmd(true)}>
          Open command bar
        </Button>
        <Button variant="secondary" onClick={() => setToast(true)}>
          Show toast
        </Button>
      </div>
      <Modal open={modal} onOpenChange={setModal}>
        <Modal.Content
          title="Confirm passport sync"
          description="Your latest border crossing will be uploaded to GlobeID."
        >
          <div className="space-y-3">
            <Text variant="body" tone="secondary">
              We'll sync the metadata only — your raw scan never leaves the
              device.
            </Text>
            <div className="flex justify-end gap-2">
              <Modal.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Modal.Close>
              <Modal.Close asChild>
                <Button>Confirm</Button>
              </Modal.Close>
            </div>
          </div>
        </Modal.Content>
      </Modal>
      <Sheet open={sheet} onOpenChange={setSheet}>
        <Sheet.Content title="Filters" description="Narrow your visible trips.">
          <div className="space-y-4 py-2">
            <Field label="Date range">
              <Input placeholder="Anytime" />
            </Field>
            <Field label="Region">
              <Input placeholder="All regions" />
            </Field>
            <div className="flex justify-end gap-2 pt-2">
              <Sheet.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Sheet.Close>
              <Sheet.Close asChild>
                <Button>Apply</Button>
              </Sheet.Close>
            </div>
          </div>
        </Sheet.Content>
      </Sheet>
      <CommandBar open={cmd} onOpenChange={setCmd}>
        <CommandBar.Group heading="Navigate">
          <CommandBar.Item icon={<Globe2 />} onSelect={() => setCmd(false)}>
            Open Map
          </CommandBar.Item>
          <CommandBar.Item icon={<WalletIcon />} onSelect={() => setCmd(false)}>
            Open Wallet
          </CommandBar.Item>
          <CommandBar.Item icon={<Shield />} onSelect={() => setCmd(false)}>
            Open Identity
          </CommandBar.Item>
        </CommandBar.Group>
        <CommandBar.Separator />
        <CommandBar.Group heading="Actions">
          <CommandBar.Item icon={<Plane />} shortcut="⌘T" onSelect={() => setCmd(false)}>
            Plan a trip
          </CommandBar.Item>
          <CommandBar.Item icon={<CreditCard />} shortcut="⌘P" onSelect={() => setCmd(false)}>
            Add payment method
          </CommandBar.Item>
        </CommandBar.Group>
      </CommandBar>
      <Toast.Viewport />
      {toast ? (
        <Toast
          tone="success"
          title="Saved"
          description="Your trip has been synced."
          onOpenChange={(o) => !o && setToast(false)}
        />
      ) : null}
    </Toast.Provider>
  );
}
