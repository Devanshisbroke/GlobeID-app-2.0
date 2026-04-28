import React, { useEffect, useState, useCallback } from "react";
import { Loader2, Phone, Plus, Star, Trash2 } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useSafetyStore } from "@/store/safetyStore";

const SafetyPanel: React.FC = () => {
  const contacts = useSafetyStore((s) => s.contacts);
  const hydrated = useSafetyStore((s) => s.hydrated);
  const hydrate = useSafetyStore((s) => s.hydrate);
  const add = useSafetyStore((s) => s.add);
  const patch = useSafetyStore((s) => s.patch);
  const remove = useSafetyStore((s) => s.remove);
  const lastError = useSafetyStore((s) => s.lastError);

  const [name, setName] = useState("");
  const [relationship, setRelationship] = useState("Family");
  const [phone, setPhone] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  const onAdd = useCallback(async () => {
    if (!name || !phone || !/^\+[1-9]\d{7,14}$/.test(phone)) return;
    setBusy(true);
    try {
      await add({ name, relationship, phoneE164: phone, email: null, isPrimary: contacts.length === 0 });
      setName("");
      setPhone("");
    } finally {
      setBusy(false);
    }
  }, [name, relationship, phone, add, contacts.length]);

  if (!hydrated) {
    return (
      <GlassCard className="p-4 flex items-center gap-2 text-sm text-muted-foreground">
        <Loader2 className="w-4 h-4 animate-spin" /> Loading contacts…
      </GlassCard>
    );
  }

  return (
    <div className="space-y-3">
      <GlassCard className="p-4">
        <div className="flex items-center gap-2 mb-3">
          <Phone className="w-5 h-5 text-primary" />
          <p className="text-sm font-bold text-foreground">Emergency contacts</p>
        </div>
        {contacts.length === 0 ? (
          <p className="text-xs text-muted-foreground">No contacts yet.</p>
        ) : (
          <div className="space-y-2">
            {contacts.map((c) => (
              <div key={c.id} className="flex items-center gap-3 py-1.5">
                <div className="w-9 h-9 rounded-xl bg-secondary/50 flex items-center justify-center">
                  <Phone className="w-4 h-4 text-foreground" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold text-foreground truncate">{c.name}</span>
                    {c.isPrimary && (
                      <span className="text-[10px] uppercase tracking-widest text-amber-400 flex items-center gap-0.5">
                        <Star className="w-3 h-3" /> primary
                      </span>
                    )}
                  </div>
                  <p className="text-[11px] text-muted-foreground">
                    {c.relationship} · <a className="font-mono" href={`tel:${c.phoneE164}`}>{c.phoneE164}</a>
                  </p>
                </div>
                {!c.isPrimary && (
                  <button
                    onClick={() => void patch(c.id, { isPrimary: true })}
                    className="text-[11px] text-muted-foreground hover:text-foreground"
                  >
                    set primary
                  </button>
                )}
                <button
                  onClick={() => void remove(c.id)}
                  className="text-[11px] text-muted-foreground hover:text-destructive"
                  aria-label="Remove contact"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        )}
      </GlassCard>

      <GlassCard className="p-4 space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Add contact</p>
        <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="Full name" className="text-xs" />
        <Input
          value={relationship}
          onChange={(e) => setRelationship(e.target.value)}
          placeholder="Relationship"
          className="text-xs"
        />
        <Input
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="+1xxxxxxxxxx (E.164)"
          className="text-xs font-mono"
        />
        <Button size="sm" disabled={busy} onClick={onAdd} className="w-full">
          <Plus className="w-3 h-3 mr-1" /> Save contact
        </Button>
        {lastError && <p className="text-[11px] text-destructive">{lastError}</p>}
      </GlassCard>
    </div>
  );
};

export default React.memo(SafetyPanel);
