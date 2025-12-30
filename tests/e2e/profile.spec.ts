import { test, expect } from "@playwright/test";

test("User can update their profile information", async ({ page }) => {
  // Step 1: Login with user that has a profile
  await page.goto("/login");
  await page.locator("#email").fill("user@email.com");
  await page.locator("#password").fill("some password");
  await page.getByRole("button", { name: "Login" }).click();

  // Wait for redirect to home page
  await page.waitForURL("/");

  // Dismiss marketing consent popup if it appears (for legacy users)
  const consentPopup = page.getByText("I consent to receiving messages, updates, and promotional emails");
  if (await consentPopup.isVisible({ timeout: 2000 }).catch(() => false)) {
    await page.getByRole("button", { name: "Yes, I agree" }).click();
    // Wait for modal to close
    await expect(consentPopup).not.toBeVisible({ timeout: 3000 });
  }

  // Step 2: Navigate directly to profile edit page
  await page.goto("/identity/update/test_user");

  // Step 3: Update display name and description
  const displayNameInput = page.getByLabel(/Display name/i);
  const descriptionInput = page.getByLabel(/Description/i);

  // Clear and fill new values
  await displayNameInput.clear();
  await displayNameInput.fill("Updated Test User");

  await descriptionInput.clear();
  await descriptionInput.fill("This is my updated profile description");

  // Step 4: Click Save button
  await page.getByRole("button", { name: "Save" }).click();

  // Step 5: Verify success message (uses the new display name)
  await expect(page.getByText("Identity Updated Test User updated")).toBeVisible();
});

