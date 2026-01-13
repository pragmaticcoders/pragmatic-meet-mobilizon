declare global {
  interface Window {
    dataLayer: IArguments[];
    gtag: (...args: any[]) => void;
    __GA_INITIALIZED__?: boolean;
  }
}

interface GoogleAnalyticsConfig {
  measurementId: string;
  anonymizeIp?: boolean;
  sendPageView?: boolean;
}

export const googleAnalytics = (
  environment: any,
  config: GoogleAnalyticsConfig
) => {
  // Prevent multiple initializations
  if (window.__GA_INITIALIZED__) {
    console.debug("Google Analytics already initialized, skipping");
    return;
  }

  console.debug("Loading Google Analytics");

  if (!config.measurementId) {
    console.error("Google Analytics: measurementId is required");
    return;
  }

  // Validate measurement ID format (should start with G- for GA4)
  if (!config.measurementId.startsWith("G-")) {
    console.warn(
      "Google Analytics: measurementId should start with 'G-' for GA4. Got:",
      config.measurementId
    );
  }

  // Mark as initialized
  window.__GA_INITIALIZED__ = true;

  // Initialize dataLayer (Google's standard pattern)
  window.dataLayer = window.dataLayer || [];

  // Define gtag function exactly as Google specifies
  // Must use 'arguments' object, not rest parameters
  function gtag(..._args: any[]) {
    // eslint-disable-next-line prefer-rest-params
    window.dataLayer.push(arguments);
  }
  window.gtag = gtag;

  // Initialize GA4 with timestamp
  window.gtag("js", new Date());

  // Configure with options
  const configOptions: Record<string, any> = {};

  if (config.anonymizeIp !== false) {
    configOptions.anonymize_ip = true;
  }

  if (config.sendPageView === false) {
    configOptions.send_page_view = false;
  }

  window.gtag("config", config.measurementId, configOptions);

  // Load the Google Analytics script
  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${config.measurementId}`;

  script.onload = () => {
    console.debug("Google Analytics script loaded successfully");
  };

  script.onerror = () => {
    console.error(
      "Google Analytics script failed to load. Check if it's blocked by ad blocker or CSP."
    );
  };

  document.head.appendChild(script);

  // Track route changes if router is available
  if (environment.router) {
    environment.router.afterEach((to: any) => {
      window.gtag("event", "page_view", {
        page_path: to.fullPath,
        page_title: to.meta?.title || document.title,
        page_location: window.location.href,
      });
    });
  }

  console.debug(
    "Google Analytics initialized with measurement ID:",
    config.measurementId
  );
};



