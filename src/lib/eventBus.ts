import type { VerificationSession, EntryReceipt } from "./verificationSession";

/**
 * Compile-time event-payload contract. Adding a new event means adding a new
 * key here, which then forces every `emit` / `on` call site to typecheck.
 */
export interface EventMap {
  "session:created": [session: VerificationSession];
  "session:verified": [session: VerificationSession, receipt: EntryReceipt];
  "session:failed": [session: VerificationSession, error: string];
  "session:expired": [session: VerificationSession];
}

type Listener<TArgs extends unknown[]> = (...args: TArgs) => void;

class EventBus<TEvents extends Record<string, unknown[]>> {
  private listeners = new Map<keyof TEvents, Set<Listener<unknown[]>>>();

  on<K extends keyof TEvents>(event: K, fn: Listener<TEvents[K]>) {
    if (!this.listeners.has(event)) this.listeners.set(event, new Set());
    this.listeners.get(event)!.add(fn as Listener<unknown[]>);
    return () => this.off(event, fn);
  }

  off<K extends keyof TEvents>(event: K, fn: Listener<TEvents[K]>) {
    this.listeners.get(event)?.delete(fn as Listener<unknown[]>);
  }

  emit<K extends keyof TEvents>(event: K, ...args: TEvents[K]) {
    this.listeners.get(event)?.forEach((fn) => (fn as Listener<TEvents[K]>)(...args));
  }
}

export const eventBus = new EventBus<EventMap>();
