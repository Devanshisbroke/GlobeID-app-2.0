import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, act } from "@testing-library/react";
import LazyMount from "@/components/system/LazyMount";

class StubObserver {
  static instances: StubObserver[] = [];
  cb: IntersectionObserverCallback;
  el?: Element;
  constructor(cb: IntersectionObserverCallback) {
    this.cb = cb;
    StubObserver.instances.push(this);
  }
  observe(el: Element) {
    this.el = el;
  }
  disconnect() {
    /* noop */
  }
  trigger(intersecting: boolean) {
    this.cb(
      [
        {
          isIntersecting: intersecting,
          target: this.el!,
        } as IntersectionObserverEntry,
      ],
      this as unknown as IntersectionObserver,
    );
  }
}

describe("<LazyMount>", () => {
  let originalIO: typeof IntersectionObserver | undefined;

  beforeEach(() => {
    StubObserver.instances = [];
    originalIO = (globalThis as { IntersectionObserver?: typeof IntersectionObserver })
      .IntersectionObserver;
    (
      globalThis as { IntersectionObserver?: unknown }
    ).IntersectionObserver = StubObserver as unknown as typeof IntersectionObserver;
  });

  afterEach(() => {
    if (originalIO) {
      (globalThis as { IntersectionObserver: typeof IntersectionObserver }).IntersectionObserver =
        originalIO;
    }
  });

  it("renders fallback before intersection, children after", () => {
    render(
      <LazyMount fallback={<div data-testid="fallback" />}>
        <div data-testid="child" />
      </LazyMount>,
    );
    expect(screen.getByTestId("fallback")).toBeInTheDocument();
    expect(screen.queryByTestId("child")).toBeNull();

    act(() => {
      StubObserver.instances[0]!.trigger(true);
    });

    expect(screen.queryByTestId("fallback")).toBeNull();
    expect(screen.getByTestId("child")).toBeInTheDocument();
  });

  it("falls back to immediate mount when IntersectionObserver is unavailable", () => {
    delete (globalThis as { IntersectionObserver?: unknown }).IntersectionObserver;
    render(
      <LazyMount fallback={<div data-testid="fallback" />}>
        <div data-testid="child" />
      </LazyMount>,
    );
    expect(screen.getByTestId("child")).toBeInTheDocument();
  });

  it("when mountOnce=false, unmounts child as it leaves the viewport", () => {
    render(
      <LazyMount mountOnce={false} fallback={<div data-testid="fallback" />}>
        <div data-testid="child" />
      </LazyMount>,
    );
    act(() => {
      StubObserver.instances[0]!.trigger(true);
    });
    expect(screen.getByTestId("child")).toBeInTheDocument();
    act(() => {
      StubObserver.instances[0]!.trigger(false);
    });
    expect(screen.queryByTestId("child")).toBeNull();
    expect(screen.getByTestId("fallback")).toBeInTheDocument();
  });
});
