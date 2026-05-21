import { test, expect } from "@playwright/test";

test("home renders", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("GoToGolf Web 完整測試台")).toBeVisible();
});
