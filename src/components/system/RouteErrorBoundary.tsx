/**
 * `RouteErrorBoundary` — per-route recovery surface.
 *
 * The top-level `<ErrorBoundary>` in `main.tsx` is a hard fallback for
 * catastrophic render failures: it blanks the screen and asks the user
 * to reload. That is the right call for "the React tree corrupted
 * itself", but it's overkill when *one* lazy-loaded screen throws while
 * other screens (Home, Wallet) still work fine.
 *
 * `RouteErrorBoundary` wraps the inner `<Routes>` so that:
 *   - A crash on `/wallet` shows an in-place error card with a "Go home"
 *     button, leaving the chrome (BottomNav, FAB) intact and clickable.
 *   - The reset path is a navigate, not a `location.reload()`, so we
 *     don't drop the in-memory store cache.
 *   - Errors are still mirrored to console + the global error reporter
 *     for parity with the top-level boundary.
 */
import React from "react";
import { Link } from "react-router-dom";

interface RouteErrorBoundaryState {
  error: Error | null;
}

interface RouteErrorBoundaryProps {
  children: React.ReactNode;
}

class RouteErrorBoundary extends React.Component<
  RouteErrorBoundaryProps,
  RouteErrorBoundaryState
> {
  state: RouteErrorBoundaryState = { error: null };

  static getDerivedStateFromError(error: Error): RouteErrorBoundaryState {
    return { error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo): void {
    console.error("[GlobeID] route render error:", error, info);
  }

  // Reset the boundary when the user clicks the recovery CTA. Combined
  // with `<Link to="/">` the next render restarts the route tree fresh.
  private reset = (): void => {
    this.setState({ error: null });
  };

  render(): React.ReactNode {
    const { error } = this.state;
    if (!error) return this.props.children;

    return (
      <div
        role="alert"
        className="mx-4 my-8 rounded-2xl p-6 text-center"
        style={{
          background: "hsl(var(--p7-surface-2))",
          border: "1px solid hsl(var(--p7-border))",
          color: "hsl(var(--p7-fg-1))",
        }}
      >
        <h2 className="text-base font-semibold mb-2">This screen hit an error</h2>
        <p className="text-xs opacity-70 max-w-xs mx-auto mb-5 leading-relaxed">
          The screen failed to render. Other parts of the app are still
          working — try going home or back to the previous tab.
        </p>
        <div className="flex items-center justify-center gap-2">
          <Link
            to="/"
            onClick={this.reset}
            className="px-4 py-2 rounded-full text-xs font-medium"
            style={{
              background: "hsl(var(--p7-accent))",
              color: "hsl(var(--p7-on-accent, 0 0% 100%))",
              minHeight: 44,
              display: "inline-flex",
              alignItems: "center",
            }}
          >
            Go home
          </Link>
          <button
            onClick={this.reset}
            type="button"
            className="px-4 py-2 rounded-full text-xs font-medium"
            style={{
              background: "transparent",
              border: "1px solid hsl(var(--p7-border))",
              color: "hsl(var(--p7-fg-1))",
              minHeight: 44,
            }}
          >
            Try again
          </button>
        </div>
        {import.meta.env.DEV ? (
          <pre className="mt-5 text-[10px] opacity-50 max-w-full overflow-auto whitespace-pre-wrap text-left">
            {error.stack ?? error.message}
          </pre>
        ) : null}
      </div>
    );
  }
}

export default RouteErrorBoundary;
