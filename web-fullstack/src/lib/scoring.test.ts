import { describe, expect, it } from "vitest";
import { toPar } from "./scoring";

describe("toPar", () => {
  it("calculates diff", () => {
    expect(toPar(70, 72)).toBe(-2);
    expect(toPar(78, 72)).toBe(6);
  });
});
