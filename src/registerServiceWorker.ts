import { register } from "register-service-worker";

// Run in dev *and* prod so the zombie-cache fix can be tested locally
// against the same code path that ships to production. In dev the
// `/service-worker.js` file only exists when the frontend was built
// (`npm run build` or `vite build --watch`) — pure HMR mode (`npm run
// dev`) will hit a 404 here and the `error` callback below will log
// it. That's expected and matches what the `Testing locally` section
// in `docs/CLOUDFLARE_CACHE.md` describes.
if ("serviceWorker" in navigator) {
  // Auto-reload exactly once when a freshly activated SW takes control.
  // This closes the loop opened by `useVersionCheck` (poll → detect new
  // commit → `registration.update()` → SW install → `skipWaiting` →
  // `clients.claim()` → `controllerchange` → reload here).
  //
  // The guard is required because Workbox's `precacheAndRoute` may
  // trigger multiple controllerchange events under some browsers; we
  // only ever want a single reload per tab per deploy.
  let reloading = false;
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (reloading) return;
    reloading = true;
    console.debug(
      "[sw] controller changed, reloading to pick up the new release."
    );
    window.location.reload();
  });

  register(`${import.meta.env.BASE_URL}service-worker.js`, {
    ready() {
      console.debug(
        "App is being served from cache by a service worker.\n" +
          "For more details, visit https://goo.gl/AFskqB"
      );
    },
    registered() {
      console.debug("Service worker has been registered.");
    },
    cached() {
      console.debug("Content has been cached for offline use.");
    },
    updatefound() {
      console.debug("New content is downloading.");
    },
    updated(registration: ServiceWorkerRegistration) {
      // Kept as a UX fallback: if `controllerchange` somehow does not
      // fire (very old browsers, SW disabled mid-flight, etc.) the
      // `refreshApp` snackbar in `App.vue` still gives the user a
      // manual way to apply the update.
      const event = new CustomEvent("refreshApp", { detail: registration });
      document.dispatchEvent(event);
      console.debug("New content is available; please refresh.");
    },
    offline() {
      console.debug(
        "No internet connection found. App is running in offline mode."
      );
    },
    error(error) {
      console.error("Error during service worker registration:", error);
    },
  });
}
