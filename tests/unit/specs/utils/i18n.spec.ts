import { describe, it, expect } from "vitest";
import { i18n, loadLanguageAsync } from "@/utils/i18n";
import { isRef } from "vue";

describe("i18n utility", () => {
  it("i18n.global.locale should be a reactive Ref (vue-i18n v9 behavior)", () => {
    // Check if locale is a reactive Ref (WritableComputedRef in v9)
    expect(isRef(i18n.global.locale)).toBe(true);
    expect(typeof i18n.global.locale).not.toBe("string");
  });

  it("should maintain reactivity after loading a new language", async () => {
    // Initial check
    expect(isRef(i18n.global.locale)).toBe(true);
    
    // Attempt to load 'pl'
    try {
      await loadLanguageAsync("pl");
    } catch (e) {
      // Dynamic import might fail in test environment if not properly configured,
      // but the reactivity of the locale object should remain intact regardless.
    }
    
    // After loadLanguageAsync, it MUST still be a Ref
    expect(isRef(i18n.global.locale)).toBe(true);
    expect(typeof i18n.global.locale).not.toBe("string");
  });

  it("should update locale.value correctly", async () => {
    const targetLang = "pl";
    try {
      await loadLanguageAsync(targetLang);
    } catch (e) {
      // Ignore dynamic import errors
    }
    
    // Even if the file load fails, setI18nLanguage is called which updates the value
    expect(i18n.global.locale.value).toBe(targetLang);
  });
});
