import { z } from "zod";

/** Canonical alert shape — backend-authoritative.
 *  `source: "system"` means lazily derived from current state at read time.
 *  `signature` is the dedup key for system alerts so re-derivation is idempotent. */
export const alertSchema = z.object({
  id: z.string(),
  category: z.enum([
    "visa",
    "flight",
    "wallet",
    "advisory",
    "info",
    "system",
  ]),
  title: z.string(),
  message: z.string(),
  severity: z.enum(["low", "medium", "high"]).default("low"),
  source: z.enum(["seed", "system"]).default("seed"),
  signature: z.string().optional(),
  createdAt: z.number().int(),
  read: z.boolean().default(false),
  dismissed: z.boolean().default(false),
});
export type Alert = z.infer<typeof alertSchema>;

export const alertPatchSchema = z.object({
  read: z.boolean().optional(),
  dismissed: z.boolean().optional(),
});
export type AlertPatch = z.infer<typeof alertPatchSchema>;
