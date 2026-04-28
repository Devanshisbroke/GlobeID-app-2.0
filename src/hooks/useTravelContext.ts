/**
 * Phase 9-β — Selector hook for the context engine snapshot.
 *
 * Wraps `useContextStore` so screens don't import zustand internals. Callers
 * can subscribe to the whole snapshot or to individual derivations.
 */
import { useContextStore } from "@/store/contextStore";

export function useTravelContext() {
  return useContextStore((s) => s.snapshot);
}

export function useTravelContextStatus() {
  return useContextStore((s) => s.status);
}

export function useAutomationFlags() {
  return useContextStore((s) => s.snapshot?.automationFlags ?? []);
}

export function useLocationContext() {
  return useContextStore((s) => s.snapshot?.location ?? null);
}

export function usePredictiveNextTrip() {
  return useContextStore((s) => s.snapshot?.predictiveNextTrip ?? null);
}
