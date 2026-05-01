/**
 * RFC 5545 (iCalendar) generator for trips and individual flight legs.
 *
 * No external library — the spec is small enough that hand-rolling is
 * cheaper than another ~80 KB of bundle. Output is emitted as
 * `Content-Type: text/calendar; charset=utf-8`. Caller is responsible
 * for serving / sharing the produced text.
 *
 * Folding (RFC 5545 §3.1): physical lines are limited to 75 octets and
 * folded with `\r\n ` (space). UID is generated stably from the input
 * so re-exports of the same trip update calendar entries instead of
 * duplicating them.
 */

import type { TripLifecycle, TripLeg } from "@shared/types/lifecycle";
import { getAirport } from "@/lib/airports";

export interface IcsEvent {
  /** Stable UID. Re-using the same UID updates the existing entry. */
  uid: string;
  /** ISO date (YYYY-MM-DD) or full ISO 8601 with `Z`. */
  start: string;
  /** Same shape as `start`. Exclusive end per RFC 5545 §3.8.2.2. */
  end: string;
  summary: string;
  description?: string;
  location?: string;
  /** Number of minutes before `start` to alarm. Omit to skip alarm. */
  alarmMinutesBefore?: number;
}

const CRLF = "\r\n";

function escape(text: string): string {
  return text
    .replace(/\\/g, "\\\\")
    .replace(/\r\n|\n|\r/g, "\\n")
    .replace(/,/g, "\\,")
    .replace(/;/g, "\\;");
}

function formatDate(input: string): string {
  if (/^\d{4}-\d{2}-\d{2}$/.test(input)) {
    // VALUE=DATE form: YYYYMMDD
    return input.replace(/-/g, "");
  }
  const d = new Date(input);
  // UTC compact form: YYYYMMDDTHHMMSSZ
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const hh = String(d.getUTCHours()).padStart(2, "0");
  const mi = String(d.getUTCMinutes()).padStart(2, "0");
  const ss = String(d.getUTCSeconds()).padStart(2, "0");
  return `${yyyy}${mm}${dd}T${hh}${mi}${ss}Z`;
}

function isAllDay(input: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(input);
}

function fold(line: string): string {
  // Fold at 75 octets; downstream parsers join folded lines that begin
  // with a space.
  if (line.length <= 75) return line;
  const chunks: string[] = [];
  let rest = line;
  chunks.push(rest.slice(0, 75));
  rest = rest.slice(75);
  while (rest.length > 0) {
    chunks.push(` ${rest.slice(0, 74)}`);
    rest = rest.slice(74);
  }
  return chunks.join(CRLF);
}

function emitEvent(ev: IcsEvent, now: string): string[] {
  const lines: string[] = [];
  lines.push("BEGIN:VEVENT");
  lines.push(`UID:${ev.uid}`);
  lines.push(`DTSTAMP:${now}`);
  if (isAllDay(ev.start)) {
    lines.push(`DTSTART;VALUE=DATE:${formatDate(ev.start)}`);
    lines.push(`DTEND;VALUE=DATE:${formatDate(ev.end)}`);
  } else {
    lines.push(`DTSTART:${formatDate(ev.start)}`);
    lines.push(`DTEND:${formatDate(ev.end)}`);
  }
  lines.push(`SUMMARY:${escape(ev.summary)}`);
  if (ev.description) lines.push(`DESCRIPTION:${escape(ev.description)}`);
  if (ev.location) lines.push(`LOCATION:${escape(ev.location)}`);
  if (ev.alarmMinutesBefore !== undefined && ev.alarmMinutesBefore > 0) {
    lines.push("BEGIN:VALARM");
    lines.push("ACTION:DISPLAY");
    lines.push(`DESCRIPTION:${escape(ev.summary)}`);
    lines.push(`TRIGGER:-PT${ev.alarmMinutesBefore}M`);
    lines.push("END:VALARM");
  }
  lines.push("END:VEVENT");
  return lines;
}

/** Wrap one or more events into a complete VCALENDAR document. */
export function buildIcs(events: IcsEvent[]): string {
  const now = formatDate(new Date().toISOString());
  const lines: string[] = [];
  lines.push("BEGIN:VCALENDAR");
  lines.push("VERSION:2.0");
  lines.push("PRODID:-//GlobeID//Travel Companion//EN");
  lines.push("CALSCALE:GREGORIAN");
  for (const ev of events) lines.push(...emitEvent(ev, now));
  lines.push("END:VCALENDAR");
  return lines.map(fold).join(CRLF);
}

/** End-of-day exclusive: an all-day VEVENT runs DTSTART → next day. */
function nextDay(yyyymmdd: string): string {
  const d = new Date(`${yyyymmdd}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

function legSummary(leg: TripLeg): string {
  const parts = [leg.airline, leg.flightNumber].filter(Boolean).join(" ");
  return `${parts ? parts + " · " : ""}${leg.fromIata} → ${leg.toIata}`;
}

function legLocation(leg: TripLeg): string {
  const a = getAirport(leg.fromIata);
  const b = getAirport(leg.toIata);
  if (a && b) return `${a.city} → ${b.city}`;
  return `${leg.fromIata} → ${leg.toIata}`;
}

/** Convert a TripLifecycle into an array of IcsEvents (one per leg). */
export function tripToIcsEvents(trip: TripLifecycle): IcsEvent[] {
  return trip.legs.map((leg) => ({
    uid: `globeid-leg-${leg.id}@globeid.io`,
    start: leg.date,
    end: nextDay(leg.date),
    summary: legSummary(leg),
    description: trip.name,
    location: legLocation(leg),
    alarmMinutesBefore: 180, // 3h pre-flight
  }));
}

/** Convenience: full trip → ICS string. */
export function tripToIcs(trip: TripLifecycle): string {
  return buildIcs(tripToIcsEvents(trip));
}
