/**
 * Slice-G – onboarding completion flag.
 * Kept in its own module so the two helpers don't break fast-refresh
 * for the Onboarding screen component.
 */

const ONBOARDED_KEY = "globeid:onboarded";

export function markOnboardingComplete(): void {
  try {
    localStorage.setItem(ONBOARDED_KEY, "1");
  } catch {
    // localStorage can throw in private mode; swallow.
  }
}

export function hasCompletedOnboarding(): boolean {
  try {
    return localStorage.getItem(ONBOARDED_KEY) === "1";
  } catch {
    return false;
  }
}
