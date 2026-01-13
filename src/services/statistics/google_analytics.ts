declare global {
  interface Window {
    dataLayer: any[];
    gtag: (...args: any[]) => void;
  }
}

interface GoogleAnalyticsConfig {
  measurementId: string;
  anonymizeIp?: boolean;
  sendPageView?: boolean;
  debug?: boolean;
}

export const googleAnalytics = (
  environment: any,
  config: GoogleAnalyticsConfig
) => {
  console.debug("Loading Google Analytics");

  if (!config.measurementId) {
    console.error("Google Analytics: measurementId is required");
    return;
  }

  // Initialize dataLayer
  window.dataLayer = window.dataLayer || [];

  // Define gtag function
  window.gtag = function gtag(...args: unknown[]) {
    window.dataLayer.push(args);
  };

  window.gtag("js", new Date());

  // Configure with options
  const configOptions: Record<string, any> = {};

  if (config.anonymizeIp !== false) {
    configOptions.anonymize_ip = true;
  }

  if (config.sendPageView === false) {
    configOptions.send_page_view = false;
  }

  // Enable debug mode for testing in GA4 DebugView
  // Can be enabled via URL parameter: ?gtag_debug=1
  const urlParams = new URLSearchParams(window.location.search);
  if (config.debug || urlParams.get("gtag_debug") === "1") {
    configOptions.debug_mode = true;
    console.debug("Google Analytics: Debug mode enabled - events will appear in GA4 DebugView");
  }

  window.gtag("config", config.measurementId, configOptions);

  // Load the Google Analytics script
  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${config.measurementId}`;
  
  script.onload = () => {
    console.debug("Google Analytics: gtag.js script loaded successfully");
  };
  
  script.onerror = (error) => {
    console.error("Google Analytics: Failed to load gtag.js script", error);
    console.error("This might be caused by: ad blockers, CSP restrictions, or network issues");
  };
  
  document.head.appendChild(script);

  // Track route changes if router is available
  if (environment.router) {
    environment.router.afterEach((to: any) => {
      console.debug("Google Analytics: Tracking page view", {
        page_path: to.fullPath,
        page_title: to.meta?.title || document.title,
      });
      window.gtag("config", config.measurementId, {
        page_path: to.fullPath,
        page_title: to.meta?.title || document.title,
      });
    });
  } else {
    console.warn("Google Analytics: Router not available, page view tracking disabled");
  }

  console.debug(
    "Google Analytics initialized with measurement ID:",
    config.measurementId
  );
};
