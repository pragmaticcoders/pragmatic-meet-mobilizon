import type { Page } from "@playwright/test";

/**
 * Cookiebot overlays the app until consent is given. Call after the first
 * navigation in a test so subsequent clicks are not intercepted.
 */
export async function dismissCookieConsent(page: Page): Promise<void> {
  const allowAll = page.getByRole("button", { name: /allow all/i });
  try {
    // Keep under default test budget on CI; banner usually appears quickly.
    await allowAll.waitFor({ state: "visible", timeout: 12_000 });
    await allowAll.click();
    await allowAll.waitFor({ state: "detached", timeout: 8000 }).catch(() => {});
  } catch {
    // No banner (already consented or Cookiebot blocked)
  }
}
