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
  window.gtag = function gtag() {
    window.dataLayer.push(arguments);
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

  window.gtag("config", config.measurementId, configOptions);

  // Load the Google Analytics script
  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${config.measurementId}`;
  document.head.appendChild(script);

  // Track route changes if router is available
  if (environment.router) {
    environment.router.afterEach((to: any) => {
      window.gtag("config", config.measurementId, {
        page_path: to.fullPath,
        page_title: to.meta?.title || document.title,
      });
    });
  }

  console.debug(
    "Google Analytics initialized with measurement ID:",
    config.measurementId
  );
};



