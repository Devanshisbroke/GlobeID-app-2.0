import { z } from "zod";

/**
 * Slice-B — emergency contacts.
 *
 * Phone validation is E.164 (`+` then 8–15 digits). The first contact added
 * is automatically primary; clients can override with `isPrimary: true` and
 * the server demotes any other primary contact in the same transaction.
 */

const e164Regex = /^\+[1-9]\d{7,14}$/;

export const emergencyContactSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(120),
  relationship: z.string().min(1).max(60),
  phoneE164: z.string().regex(e164Regex, "phone must be E.164 (+countrycode…)"),
  email: z.string().email().nullable(),
  isPrimary: z.boolean(),
  createdAt: z.string(),
});
export type EmergencyContact = z.infer<typeof emergencyContactSchema>;

export const emergencyContactCreateSchema = z.object({
  name: z.string().min(1).max(120),
  relationship: z.string().min(1).max(60),
  phoneE164: z.string().regex(e164Regex),
  email: z.string().email().optional().nullable(),
  isPrimary: z.boolean().optional(),
});
export type EmergencyContactCreate = z.infer<typeof emergencyContactCreateSchema>;

export const emergencyContactPatchSchema = emergencyContactCreateSchema.partial();
export type EmergencyContactPatch = z.infer<typeof emergencyContactPatchSchema>;
