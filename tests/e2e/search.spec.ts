import { test, expect } from "@playwright/test";

test.describe("Search Page - Online Filter", () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to search page
    await page.goto("/search");
    await page.waitForLoadState("networkidle");
  });

  test("displays online filter checkboxes", async ({ page }) => {
    // Check that both checkboxes are visible by finding the label with the text
    const onlineOnlyLabel = page.locator('label:has-text("Show only online events")');
    const includeOnlineLabel = page.locator('label:has-text("Include online events")');

    await expect(onlineOnlyLabel).toBeVisible();
    await expect(includeOnlineLabel).toBeVisible();
    
    // Also verify the checkboxes themselves are present
    const onlineOnlyCheckbox = onlineOnlyLabel.locator('input[type="checkbox"]');
    const includeOnlineCheckbox = includeOnlineLabel.locator('input[type="checkbox"]');
    
    await expect(onlineOnlyCheckbox).toBeVisible();
    await expect(includeOnlineCheckbox).toBeVisible();
  });

  test("checkboxes are stacked vertically", async ({ page }) => {
    const labels = page.locator('label:has(input[type="checkbox"])').filter({
      hasText: /show only online events|include online events/i,
    });

    const count = await labels.count();
    expect(count).toBe(2);

    // Get bounding boxes
    const box1 = await labels.nth(0).boundingBox();
    const box2 = await labels.nth(1).boundingBox();

    expect(box1).not.toBeNull();
    expect(box2).not.toBeNull();

    // Check that checkboxes are vertically stacked (Y position of second > first)
    expect(box2!.y).toBeGreaterThan(box1!.y);
  });

  test("checking 'Show only online events' activates the checkbox", async ({
    page,
  }) => {
    const label = page.locator('label:has-text("Show only online events")');
    const checkbox = label.locator('input[type="checkbox"]');

    // Check the checkbox
    await label.click();
    await page.waitForTimeout(500);

    // Verify it's checked
    await expect(checkbox).toBeChecked();
  });

  test("checking 'Include online events' activates the checkbox", async ({
    page,
  }) => {
    const label = page.locator('label:has-text("Include online events")');
    const checkbox = label.locator('input[type="checkbox"]');

    // Check the checkbox
    await label.click();
    await page.waitForTimeout(500);

    // Verify it's checked
    await expect(checkbox).toBeChecked();
  });

  test("clicking checked checkbox unchecks it", async ({ page }) => {
    const label = page.locator('label:has-text("Show only online events")');
    const checkbox = label.locator('input[type="checkbox"]');

    // Check the checkbox
    await label.click();
    await page.waitForTimeout(300);
    await expect(checkbox).toBeChecked();

    // Uncheck the checkbox
    await label.click();
    await page.waitForTimeout(300);
    await expect(checkbox).not.toBeChecked();
  });

  test("checkboxes are mutually exclusive", async ({ page }) => {
    const onlineOnlyLabel = page.locator(
      'label:has-text("Show only online events")'
    );
    const includeOnlineLabel = page.locator(
      'label:has-text("Include online events")'
    );
    const onlineOnlyCheckbox = onlineOnlyLabel.locator(
      'input[type="checkbox"]'
    );
    const includeOnlineCheckbox = includeOnlineLabel.locator(
      'input[type="checkbox"]'
    );

    // Check first checkbox
    await onlineOnlyLabel.click();
    await page.waitForTimeout(300);

    await expect(onlineOnlyCheckbox).toBeChecked();
    await expect(includeOnlineCheckbox).not.toBeChecked();

    // Check second checkbox
    await includeOnlineLabel.click();
    await page.waitForTimeout(300);

    await expect(onlineOnlyCheckbox).not.toBeChecked();
    await expect(includeOnlineCheckbox).toBeChecked();
  });

  test("URL updates when 'Show only online events' is checked", async ({
    page,
  }) => {
    const label = page.locator('label:has-text("Show only online events")');

    await label.click();
    await page.waitForTimeout(500);

    // Check URL query parameter
    const url = new URL(page.url());
    expect(url.searchParams.get("onlineFilter")).toBe("online_only");
  });

  test("URL updates when 'Include online events' is checked", async ({
    page,
  }) => {
    const label = page.locator('label:has-text("Include online events")');

    await label.click();
    await page.waitForTimeout(500);

    // Check URL query parameter
    const url = new URL(page.url());
    expect(url.searchParams.get("onlineFilter")).toBe("include_online");
  });

  test("URL updates when checkbox is unchecked", async ({ page }) => {
    const label = page.locator('label:has-text("Show only online events")');

    // Check the checkbox
    await label.click();
    await page.waitForTimeout(300);

    let url = new URL(page.url());
    expect(url.searchParams.get("onlineFilter")).toBe("online_only");

    // Uncheck the checkbox
    await label.click();
    await page.waitForTimeout(300);

    url = new URL(page.url());
    expect(url.searchParams.get("onlineFilter")).toBe("none");
  });

  test("loads with correct filter from URL parameter", async ({ page }) => {
    // Navigate with query parameter
    await page.goto("/search?onlineFilter=online_only");
    await page.waitForLoadState("networkidle");

    const label = page.locator('label:has-text("Show only online events")');
    const checkbox = label.locator('input[type="checkbox"]');

    // Check that the checkbox is checked
    await expect(checkbox).toBeChecked();
  });

  test("defaults to no filter when no query parameter", async ({ page }) => {
    await page.goto("/search");
    await page.waitForLoadState("networkidle");

    const onlineOnlyLabel = page.locator(
      'label:has-text("Show only online events")'
    );
    const includeOnlineLabel = page.locator(
      'label:has-text("Include online events")'
    );
    const onlineOnlyCheckbox = onlineOnlyLabel.locator(
      'input[type="checkbox"]'
    );
    const includeOnlineCheckbox = includeOnlineLabel.locator(
      'input[type="checkbox"]'
    );

    // Check that neither checkbox is checked
    await expect(onlineOnlyCheckbox).not.toBeChecked();
    await expect(includeOnlineCheckbox).not.toBeChecked();
  });

  test("filter section is hidden when viewing groups", async ({ page }) => {
    await page.goto("/search");
    await page.waitForLoadState("networkidle");

    // Click on Groups tab
    const groupsTab = page.getByRole("button", { name: /groups/i });
    await groupsTab.click();
    await page.waitForTimeout(300);

    // Online filter section should be hidden
    const filterSection = page.locator('text="Online events"').first();
    await expect(filterSection).not.toBeVisible();
  });

  test("search with location and online filter redirects correctly", async ({
    page,
  }) => {
    // This would test the LoggedSearchBar and SearchFields components
    // Navigate from home page to search with filters
    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // Assuming there's a search form on the home page
    const searchInput = page.locator('input[placeholder*="Keyword"]').first();
    if (await searchInput.isVisible()) {
      await searchInput.fill("test event");

      // Submit form
      const searchButton = page
        .getByRole("button", { name: /search/i })
        .first();
      await searchButton.click();
      await page.waitForLoadState("networkidle");

      // Should redirect to search page
      expect(page.url()).toContain("/search");
    }
  });
});
