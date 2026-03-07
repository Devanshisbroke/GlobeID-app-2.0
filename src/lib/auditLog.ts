export type AuditEventType =
  | "kiosk_scan_received"
  | "app_qr_generated"
  | "app_qr_scanned"
  | "session_verified"
  | "session_expired"
  | "session_failed"
  | "receipt_created"
  | "replay_rejected";

export interface AuditEvent {
  id: string;
  type: AuditEventType;
  payload: Record<string, unknown>;
  source: "kiosk" | "app" | "backend";
  createdAt: number;
}

const log: AuditEvent[] = [];

export function audit(type: AuditEventType, payload: Record<string, unknown>, source: AuditEvent["source"] = "backend") {
  const event: AuditEvent = {
    id: crypto.randomUUID(),
    type,
    payload,
    source,
    createdAt: Date.now(),
  };
  log.push(event);
  if (log.length > 500) log.shift();
  return event;
}

export function getAuditLog(): readonly AuditEvent[] {
  return log;
}

export function clearAuditLog() {
  log.length = 0;
}
