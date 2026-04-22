declare global {
  interface Window {
    dataLayer: any[];
    gtmInitialized?: boolean;
  }
}

interface GoogleTagManagerConfig {
  containerId: string;
}

/** Cookiebot `CookieConsent` cookie is a URL-encoded JS-like object; we need `statistics: true`. */
function statisticsAllowed(): boolean {
  const m = document.cookie.match(/(?:^|; )CookieConsent=([^;]*)/);
  if (!m) return false;
  let raw = m[1];
  try {
    raw = decodeURIComponent(raw.replace(/\+/g, " "));
  } catch {
    /* keep raw */
  }
  return /\bstatistics\s*:\s*true\b/.test(raw);
}

let removeCookiebotListeners: (() => void) | null = null;

/**
 * Loads GTM after Cookiebot statistics consent. Hooks router `page_view` pushes.
 * (GTM: Custom Event `page_view`, variables `page_path`, `page_title`, `page_location`.)
 */
export const googleTagManager = (environment: any, config: GoogleTagManagerConfig) => {
  removeCookiebotListeners?.();
  removeCookiebotListeners = null;

  if (window.gtmInitialized) return;

  if (!config.containerId) {
    console.error("Google Tag Manager: containerId is required");
    return;
  }

  const tryStart = () => {
    if (window.gtmInitialized || !statisticsAllowed()) return;
    removeCookiebotListeners?.();
    removeCookiebotListeners = null;

    window.gtmInitialized = true;
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      "gtm.start": new Date().getTime(),
      event: "gtm.js",
    });

    const script = document.createElement("script");
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtm.js?id=${config.containerId}`;
    script.onerror = () => {
      console.error(
        "Google Tag Manager script failed to load. Check if it's blocked by ad blocker or CSP."
      );
    };
    document.head.appendChild(script);

    const pushPageView = (to: any) => {
      window.dataLayer.push({
        event: "page_view",
        page_path: to.fullPath,
        page_title: to.meta?.title || document.title,
        page_location: window.location.href,
      });
    };

    if (environment.router) {
      environment.router.afterEach((to) => {
        pushPageView(to);
      });
    }

    console.debug("GTM initialized");
  };

  const events = ["CookiebotOnAccept", "CookiebotOnConsentReady", "CookiebotOnDecline"];
  events.forEach((e) => window.addEventListener(e, tryStart));
  removeCookiebotListeners = () =>
    events.forEach((e) => window.removeEventListener(e, tryStart));

  tryStart();
};
