import { z } from "zod";

/** Canonical TravelRecord shape — backend authoritative as of Phase 4. */
export const travelRecordSchema = z.object({
  id: z.string().min(1),
  from: z.string().length(3),
  to: z.string().length(3),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  airline: z.string().min(1),
  duration: z.string().min(1),
  type: z.enum(["upcoming", "past", "current"]),
  flightNumber: z.string().optional(),
  source: z.enum(["history", "planner"]),
});

export type TravelRecord = z.infer<typeof travelRecordSchema>;

export const userProfileSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  fullName: z.string(),
  nationality: z.string(),
  passportNo: z.string().optional(),
  dateOfBirth: z.string().optional(),
});

export type UserProfile = z.infer<typeof userProfileSchema>;

export const apiOk = <T extends z.ZodTypeAny>(data: T) =>
  z.object({ ok: z.literal(true), data });
export const apiErr = z.object({
  ok: z.literal(false),
  error: z.object({ code: z.string(), message: z.string() }),
});

export type ApiEnvelope<T> =
  | { ok: true; data: T }
  | { ok: false; error: { code: string; message: string } };
