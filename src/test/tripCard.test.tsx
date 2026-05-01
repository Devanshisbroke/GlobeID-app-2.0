import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import TripCard from "@/components/travel/TripCard";
import type { TravelRecord } from "@/store/userStore";

vi.mock("@/utils/haptics", () => ({
  haptics: {
    selection: vi.fn(),
    light: vi.fn(),
    medium: vi.fn(),
    success: vi.fn(),
  },
}));

const trip: TravelRecord = {
  id: "tr-test-1",
  from: "JFK",
  to: "LHR",
  date: "2026-02-12",
  airline: "British Airways",
  duration: "7h 10m",
  type: "upcoming",
  flightNumber: "BA 178",
  source: "history",
};

function renderTripCard(extra?: { onClick?: () => void }) {
  return render(
    <MemoryRouter initialEntries={["/"]}>
      <Routes>
        <Route path="/" element={<TripCard trip={trip} {...extra} />} />
        <Route
          path="/trip/:tripId"
          element={<div data-testid="trip-detail-route" />}
        />
      </Routes>
    </MemoryRouter>,
  );
}

describe("<TripCard>", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders the route IATA codes", () => {
    renderTripCard();
    expect(screen.getByText(/JFK\s*→\s*LHR/)).toBeInTheDocument();
    expect(screen.getByText(/British Airways/)).toBeInTheDocument();
  });

  it("navigates to /trip/:id on click and fires haptics.selection()", async () => {
    const { haptics } = await import("@/utils/haptics");
    renderTripCard();

    const button = screen.getByRole("button", {
      name: /open trip jfk to lhr/i,
    });
    fireEvent.click(button);

    expect(haptics.selection).toHaveBeenCalledTimes(1);
    expect(screen.getByTestId("trip-detail-route")).toBeInTheDocument();
  });

  it("activates on Enter key as well", async () => {
    const { haptics } = await import("@/utils/haptics");
    renderTripCard();

    const button = screen.getByRole("button", {
      name: /open trip jfk to lhr/i,
    });
    fireEvent.keyDown(button, { key: "Enter" });

    expect(haptics.selection).toHaveBeenCalledTimes(1);
    expect(screen.getByTestId("trip-detail-route")).toBeInTheDocument();
  });

  it("prefers a custom onClick over the default navigation", () => {
    const onClick = vi.fn();
    render(
      <MemoryRouter initialEntries={["/"]}>
        <TripCard trip={trip} onClick={onClick} />
      </MemoryRouter>,
    );

    fireEvent.click(
      screen.getByRole("button", { name: /open trip jfk to lhr/i }),
    );
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
