import { describe, it, expect } from "vitest";
import {
  generatePackingList,
  groupPackingList,
  climateForTemp,
} from "@/lib/packingList";

describe("packingList", () => {
  it("classifies climate by mean high temp", () => {
    expect(climateForTemp(-5)).toBe("cold");
    expect(climateForTemp(10)).toBe("cold");
    expect(climateForTemp(15)).toBe("cool");
    expect(climateForTemp(22)).toBe("mild");
    expect(climateForTemp(28)).toBe("warm");
    expect(climateForTemp(35)).toBe("hot");
  });

  it("includes essentials always", () => {
    const list = generatePackingList({ meanHighC: 20, nights: 3 });
    const ids = new Set(list.map((i) => i.id));
    expect(ids.has("passport")).toBe(true);
    expect(ids.has("phone")).toBe(true);
    expect(ids.has("charger")).toBe(true);
  });

  it("scales socks/underwear to nights", () => {
    const list = generatePackingList({ meanHighC: 20, nights: 5 });
    const socks = list.find((i) => i.id === "socks")!;
    expect(socks.qty).toBe(6);
  });

  it("caps qty at 14 for long trips", () => {
    const list = generatePackingList({ meanHighC: 20, nights: 60 });
    const socks = list.find((i) => i.id === "socks")!;
    expect(socks.qty).toBe(14);
  });

  it("adds cold-weather gear when below 10°C", () => {
    const list = generatePackingList({ meanHighC: 5, nights: 4 });
    const ids = new Set(list.map((i) => i.id));
    expect(ids.has("coat")).toBe(true);
    expect(ids.has("gloves")).toBe(true);
    expect(ids.has("beanie")).toBe(true);
  });

  it("adds hot-weather gear when above 30°C", () => {
    const list = generatePackingList({ meanHighC: 33, nights: 4 });
    const ids = new Set(list.map((i) => i.id));
    expect(ids.has("sunhat")).toBe(true);
    expect(ids.has("sunglasses")).toBe(true);
    expect(ids.has("electrolytes")).toBe(true);
  });

  it("adds umbrella when precipitation chance >=30%", () => {
    const wet = generatePackingList({ meanHighC: 18, meanPrecipChance: 0.5, nights: 3 });
    const dry = generatePackingList({ meanHighC: 18, meanPrecipChance: 0.1, nights: 3 });
    expect(wet.find((i) => i.id === "umbrella")).toBeTruthy();
    expect(dry.find((i) => i.id === "umbrella")).toBeUndefined();
  });

  it("adds business gear for business activity", () => {
    const list = generatePackingList({
      meanHighC: 18,
      nights: 3,
      activities: ["business"],
    });
    const ids = new Set(list.map((i) => i.id));
    expect(ids.has("blazer")).toBe(true);
    expect(ids.has("laptop")).toBe(true);
  });

  it("groups output by category in stable order", () => {
    const list = generatePackingList({ meanHighC: 30, nights: 4, activities: ["beach"] });
    const groups = groupPackingList(list);
    const categories = groups.map((g) => g.category);
    expect(categories[0]).toBe("documents");
    expect(categories.includes("activities")).toBe(true);
  });
});
