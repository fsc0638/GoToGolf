import { chromium, devices } from "@playwright/test";

const iPhone = devices["iPhone 13"];
const BASE = "http://localhost:638";

const results = [];
function log(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? "  -> " + detail : ""}`);
}

const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {},
);
const context = await browser.newContext({ ...iPhone });
const page = await context.newPage();

const consoleErrors = [];
page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });
page.on("pageerror", (e) => consoleErrors.push("pageerror: " + e.message));

try {
  // 1. Load home page
  const resp = await page.goto(BASE, { waitUntil: "networkidle" });
  log("首頁載入", resp.ok(), `HTTP ${resp.status()}`);

  // 2. Header visible
  const h1 = await page.locator("h1").first().textContent();
  log("標題顯示", !!h1, h1?.trim());

  // 3. No horizontal overflow (mobile layout sanity)
  const overflow = await page.evaluate(() => ({
    scrollW: document.documentElement.scrollWidth,
    clientW: document.documentElement.clientWidth,
  }));
  const noHScroll = overflow.scrollW <= overflow.clientW + 1;
  log("無水平捲動溢出", noHScroll, `scrollW=${overflow.scrollW} clientW=${overflow.clientW}`);

  await page.screenshot({ path: "/tmp/shot-1-home.png", fullPage: true });

  // 4. Create a test round
  const createBtn = page.getByRole("button", { name: /建立18洞測試回合/ });
  log("找到建立回合按鈕", await createBtn.isVisible());
  await createBtn.click();
  await page.waitForSelector("text=/H1 \\/ Par/", { timeout: 8000 });
  log("建立回合後顯示洞位卡片", true);

  await page.screenshot({ path: "/tmp/shot-2-round.png", fullPage: true });

  // 5. Tap-target size check on +/- buttons
  const plusBtn = page.getByRole("button", { name: "+", exact: true }).first();
  const box = await plusBtn.boundingBox();
  const tapOk = box && box.width >= 28 && box.height >= 28;
  log("計分按鈕可點擊尺寸", !!tapOk, box ? `${Math.round(box.width)}x${Math.round(box.height)}px` : "no box");

  const totalLoc = page.locator("text=總桿").locator("xpath=following-sibling::div").first();

  // 6a. Single tap, wait fully for refetch
  await plusBtn.click();
  await page.waitForTimeout(2500);
  const afterOne = (await totalLoc.textContent())?.trim();
  log("單擊 + 計分正常 (0->1)", afterOne === "1", `總桿=${afterOne}`);

  // 6b. Rapid 3 taps (mobile users tap fast) — expect total to reach 4
  for (let i = 0; i < 3; i++) {
    await plusBtn.click();
    await page.waitForTimeout(250);
  }
  await page.waitForTimeout(2500);
  const afterRapid = (await totalLoc.textContent())?.trim();
  log("連續快速點擊累加正確 (應為4)", afterRapid === "4", `總桿=${afterRapid}`);

  await page.screenshot({ path: "/tmp/shot-3-scored.png", fullPage: true });

  // 7. Console errors
  log("無 console 錯誤", consoleErrors.length === 0, consoleErrors.slice(0, 3).join(" | "));
} catch (e) {
  log("測試執行例外", false, e.message);
  await page.screenshot({ path: "/tmp/shot-error.png" }).catch(() => {});
} finally {
  await browser.close();
}

const failed = results.filter((r) => !r.ok).length;
console.log(`\n=== ${results.length - failed}/${results.length} 通過 ===`);
process.exit(failed ? 1 : 0);
