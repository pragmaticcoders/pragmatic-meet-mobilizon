import type { Page } from "@playwright/test";

/**
 * Cookiebot overlays the app until consent is given. Call after the first
 * navigation in a test so subsequent clicks are not intercepted.
 */
export async function dismissCookieConsent(page: Page): Promise<void> {
  const allowAll = page.getByRole("button", { name: /allow all/i });
  try {
    await allowAll.waitFor({ state: "visible", timeout: 15000 });
    await allowAll.click();
    await allowAll.waitFor({ state: "detached", timeout: 10000 }).catch(() => {});
  } catch {
    // No banner (already consented or Cookiebot blocked)
  }
}
