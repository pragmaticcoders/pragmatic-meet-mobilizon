const countryFlagEmoji = (region2: string): string => {
  const cc = region2.toUpperCase();
  if (cc.length !== 2) return "";
  const A = 0x1f1e6;
  const codePoints = [cc.charCodeAt(0) - 65 + A, cc.charCodeAt(1) - 65 + A];
  return String.fromCodePoint(...codePoints);
};

export const flagForLocale = (lang: string): string => {
  const original = (lang || "");
  const normalized = original.replace("_", "-").toLowerCase();

  // Exact mapping for languages present in src/i18n/langs.json
  const map: Record<string, string> = {
    ar: "🇸🇦",
    bn: "🇧🇩",
    ca: "🇪🇸",
    cs: "🇨🇿",
    cy: "🇬🇧",
    de: "🇩🇪",
    en: "🇬🇧",
    es: "🇪🇸",
    fa: "🇮🇷",
    fi: "🇫🇮",
    fr: "🇫🇷",
    gd: "🇬🇧",
    gl: "🇪🇸",
    hr: "🇭🇷",
    hu: "🇭🇺",
    id: "🇮🇩",
    it: "🇮🇹",
    ja: "🇯🇵",
    nl: "🇳🇱",
    nn: "🇳🇴",
    oc: "🇫🇷",
    pl: "🇵🇱",
    "pt_BR": "🇧🇷",
    ru: "🇷🇺",
    sl: "🇸🇮",
    sv: "🇸🇪",
    zh_Hans: "🇨🇳",
    zh_Hant: "🇹🇼",
    // Also support normalized variants just in case
    "pt-br": "🇧🇷",
    "zh-hans": "🇨🇳",
    "zh-hant": "🇹🇼",
  } as Record<string, string>;

  return map[original] ?? map[normalized] ?? "";
};
