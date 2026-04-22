declare global {
  interface Window {
    gtmInitialized?: boolean;
  }
}

/** Avoid conflicting `Window.dataLayer` typings from `google_analytics.ts`. */
function pushToDataLayer(payload: Record<string, unknown>): void {
  const w = window as unknown as { dataLayer?: unknown[] };
  if (!Array.isArray(w.dataLayer)) {
    w.dataLayer = [];
  }
  w.dataLayer.push(payload);
}

interface GoogleTagManagerConfig {
  containerId: string;
}

/** Cookiebot `CookieConsent` cookie: URL-encoded object with `statistics: true` / `false`. */
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
let stopRouter: (() => void) | null = null;
let gtmScriptEl: HTMLScriptElement | null = null;
let isGtmMounted = false;
let mountedContainerId: string | null = null;
let lastEnvironment: any = null;

function stripGtmFromDom(containerId: string): void {
  gtmScriptEl?.remove();
  gtmScriptEl = null;

  const idParam = encodeURIComponent(containerId);
  document.querySelectorAll("script[src*='googletagmanager.com/gtm.js']").forEach((el) => {
    const src = (el as HTMLScriptElement).src;
    if (src.includes(containerId) || src.includes(idParam)) {
      el.remove();
    }
  });

  document.querySelectorAll("iframe[src*='googletagmanager.com']").forEach((el) => {
    const src = (el as HTMLIFrameElement).src;
    if (src.includes(containerId) || src.includes(idParam)) {
      el.remove();
    }
  });
}

function mountGtm(environment: any, config: GoogleTagManagerConfig): void {
  if (isGtmMounted) return;

  isGtmMounted = true;
  mountedContainerId = config.containerId;
  window.gtmInitialized = true;

  pushToDataLayer({
    "gtm.start": new Date().getTime(),
    event: "gtm.js",
  });

  gtmScriptEl = document.createElement("script");
  gtmScriptEl.async = true;
  gtmScriptEl.src = `https://www.googletagmanager.com/gtm.js?id=${config.containerId}`;
  gtmScriptEl.onerror = () => {
    console.error(
      "Google Tag Manager script failed to load. Check if it's blocked by ad blocker or CSP."
    );
  };
  document.head.appendChild(gtmScriptEl);

  const pushPageView = (to: { fullPath: string; meta?: { title?: string } }) => {
    if (!isGtmMounted) return;
    pushToDataLayer({
      event: "page_view",
      page_path: to.fullPath,
      page_title: to.meta?.title || document.title,
      page_location: window.location.href,
    });
  };

  if (environment.router) {
    stopRouter = environment.router.afterEach((to: {
      fullPath: string;
      meta?: { title?: string };
    }) => {
      pushPageView(to);
    });
  }

  console.debug("GTM initialized");
}

function unmountGtm(): void {
  if (!isGtmMounted) return;

  isGtmMounted = false;
  window.gtmInitialized = false;

  stopRouter?.();
  stopRouter = null;

  const id = mountedContainerId;
  mountedContainerId = null;
  if (id) {
    stripGtmFromDom(id);
  }

  console.debug("GTM torn down (statistics consent off or container changed)");
}

/**
 * Mounts GTM when Cookiebot allows statistics; tears it down when consent is withdrawn.
 * Router `page_view` pushes stop after unmount. (GTM: trigger on `page_view`.)
 */
export const googleTagManager = (environment: any, config: GoogleTagManagerConfig) => {
  removeCookiebotListeners?.();
  removeCookiebotListeners = null;

  if (!config.containerId) {
    console.error("Google Tag Manager: containerId is required");
    return;
  }

  lastEnvironment = environment;

  const sync = (): void => {
    if (!statisticsAllowed()) {
      unmountGtm();
      return;
    }
    if (isGtmMounted && mountedContainerId !== config.containerId) {
      unmountGtm();
    }
    if (!isGtmMounted) {
      mountGtm(lastEnvironment, config);
    }
  };

  const events = ["CookiebotOnAccept", "CookiebotOnConsentReady", "CookiebotOnDecline"];
  events.forEach((name) => window.addEventListener(name, sync));
  removeCookiebotListeners = () =>
    events.forEach((name) => window.removeEventListener(name, sync));

  sync();
};
