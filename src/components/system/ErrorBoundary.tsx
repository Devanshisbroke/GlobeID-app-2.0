import React from "react";

/**
 * Top-level error boundary.
 *
 * Phase 6 PR-α — wrapped around <App /> in `src/main.tsx` so a single
 * thrown render error in any lazy-loaded screen no longer blanks the app.
 *
 * UX:
 *  - First crash within a session shows a calm "something went wrong" surface
 *    with a Reload button.
 *  - Errors are mirrored to `console.error` so device-attached debuggers
 *    (chrome://inspect, Android Studio Logcat) still see them.
 *  - Boundary deliberately does NOT auto-recover — auto-recovery loops are
 *    worse than a visible failure on a real device.
 */
interface ErrorBoundaryState {
  error: Error | null;
}

interface ErrorBoundaryProps {
  children: React.ReactNode;
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { error: null };

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo): void {
    // Log to console so it shows up in `chrome://inspect` + Android Logcat.
    // Do NOT swallow — visible failures are better than silent ones in prod.
    console.error("[GlobeID] uncaught render error:", error, info);
  }

  private handleReload = (): void => {
    // Full reload — clears the React tree and any stuck lazy chunks.
    window.location.reload();
  };

  render(): React.ReactNode {
    const { error } = this.state;
    if (!error) return this.props.children;

    return (
      <div
        role="alert"
        className="fixed inset-0 z-[200] flex flex-col items-center justify-center p-6 text-center"
        style={{
          background:
            "linear-gradient(135deg, hsl(228 20% 5%) 0%, hsl(228 18% 9%) 50%, hsl(228 20% 5%) 100%)",
          color: "hsl(0 0% 95%)",
          paddingTop: "calc(env(safe-area-inset-top, 0px) + 1.5rem)",
          paddingBottom: "calc(env(safe-area-inset-bottom, 0px) + 1.5rem)",
        }}
      >
        <div
          aria-hidden="true"
          className="w-12 h-12 rounded-full mb-5"
          style={{
            background: "radial-gradient(circle, hsl(220 80% 56% / 0.4) 0%, transparent 70%)",
            filter: "blur(2px)",
          }}
        />
        <h1 className="text-xl font-semibold mb-2">Something went wrong</h1>
        <p className="text-sm opacity-70 max-w-xs mb-6 leading-relaxed">
          GlobeID hit an unexpected error and couldn&rsquo;t recover. Reloading usually fixes it.
        </p>
        <button
          onClick={this.handleReload}
          className="px-5 py-2.5 rounded-full text-sm font-medium"
          style={{
            background: "hsl(220 80% 56%)",
            color: "hsl(0 0% 100%)",
          }}
        >
          Reload
        </button>
        {import.meta.env.DEV && (
          <pre className="mt-6 text-[10px] opacity-50 max-w-full overflow-auto whitespace-pre-wrap">
            {error.message}
          </pre>
        )}
      </div>
    );
  }
}

export default ErrorBoundary;
