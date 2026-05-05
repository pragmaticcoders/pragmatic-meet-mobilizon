/**
 * Polling-based deploy detection.
 *
 * Without this, the only way for an SPA tab to discover a new release is
 * either to reload (which users don't do for hours) or wait for the
 * browser's built-in 24h SW update probe. Both are too slow.
 *
 * What we do instead: ask the origin's `/version.json` what SHA is live
 * and compare against the SHA baked into this bundle (`__GIT_COMMIT__`).
 * If they differ, we trigger `registration.update()` — the SW's install
 * handler calls `skipWaiting()`, `activate` calls `clients.claim()`, and
 * the `controllerchange` listener in `registerServiceWorker.ts` reloads
 * every controlled tab once the controller swaps.
 *
 * When no SW is registered (e.g. `npm run dev` without a frontend build,
 * so `/service-worker.js` 404s) we fall back to a direct
 * `window.location.reload()` so the flow still works end-to-end during
 * local testing.
 *
 * Endpoint contract: `/version.json` is served with `Cache-Control:
 * no-store` (see `Mobilizon.Web.VersionController`) so we always hit
 * origin, not Cloudflare. Make sure your Cloudflare Cache Rules also
 * bypass it — see `docs/CLOUDFLARE_CACHE.md`.
 *
 * Testing locally — see the "Testing locally" section in
 * `docs/CLOUDFLARE_CACHE.md` for the recommended flow. Quick recap:
 *   1. `VITE_GIT_COMMIT=abc1111 npm run build` — bundle bakes in
 *      `__GIT_COMMIT__ = "abc1111"`.
 *   2. `VITE_GIT_COMMIT=abc1111 mix phx.server` — backend reports the
 *      same SHA from `/version.json`. Open the app, confirm the
 *      console banner shows `abc1111`, and confirm DevTools →
 *      Application → Service Workers shows the SW as activated.
 *   3. To simulate a deploy: stop the backend and restart it with
 *      `VITE_GIT_COMMIT=def2222 mix phx.server` (no frontend rebuild
 *      needed — we want the mismatch). Within ~1 minute (or instantly
 *      on tab focus) DevTools should print
 *      `[version-check] new release detected: abc1111 -> def2222` and
 *      the page reloads automatically.
 *
 * If `__GIT_COMMIT__` is the literal string `"dev"` (default fallback
 * when no `VITE_GIT_COMMIT` is set) the check still runs against the
 * live commit, but the loop guard below kicks in after a single
 * unsuccessful attempt — so devs running `npm run dev` against a
 * production-like backend don't get stuck in a reload loop.
 */

const DEFAULT_INTERVAL_M1 = 1 * 60 * 1000;

// sessionStorage key used to break out of reload loops in environments
// where the local commit can't actually change between reloads (e.g.
// Vite dev server keeps `__GIT_COMMIT__` constant). If we already tried
// updating to a given live commit and we're still seeing the same
// mismatch, the next poll skips with a warning instead of looping.
const ATTEMPTED_KEY = "__pragmatic_meet_version_check_attempted_commit";

type VersionPayload = {
  version?: string;
  commit?: string;
  build_time?: string;
};

let started = false;

const fetchLiveVersion = async (): Promise<VersionPayload | null> => {
  try {
    const res = await fetch("/version.json", {
      cache: "no-store",
      credentials: "same-origin",
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return null;
    return (await res.json()) as VersionPayload;
  } catch (err) {
    console.debug("[version-check] fetch failed:", err);
    return null;
  }
};

const triggerUpdate = async (): Promise<void> => {
  // Preferred path: ask the registered SW to update. Its lifecycle
  // (skipWaiting + clients.claim + controllerchange) handles the reload.
  if ("serviceWorker" in navigator) {
    try {
      const registration = await navigator.serviceWorker.getRegistration();
      if (registration) {
        await registration.update();
        return;
      }
    } catch (err) {
      console.debug("[version-check] SW update failed, falling back:", err);
    }
  }

  // Fallback: no SW registered (dev mode, or a browser without SW
  // support). Hard-reload to pick up the new bundle directly.
  console.info("[version-check] no SW available, performing hard reload.");
  window.location.reload();
};

export const startVersionCheck = (
  intervalMs: number = DEFAULT_INTERVAL_M1
): void => {
  if (started) return;
  started = true;

  const localCommit = __GIT_COMMIT__ || "dev";
  console.debug(
    `[version-check] starting (interval=${intervalMs}ms, local=${localCommit})`
  );

  const checkOnce = async (): Promise<void> => {
    if (document.visibilityState !== "visible") return;

    const live = await fetchLiveVersion();
    if (!live?.commit) return;
    if (live.commit === localCommit) return;

    // Loop guard: if we already attempted updating to this exact live
    // commit and the local bundle still reports the old SHA, the build
    // pipeline is broken (or we're in dev mode where the frontend is
    // pinned to "dev"). Reloading again would just spin forever.
    const lastAttempted = sessionStorage.getItem(ATTEMPTED_KEY);
    if (lastAttempted === live.commit) {
      console.warn(
        `[version-check] already attempted update to ${live.commit} but ` +
          `bundle still reports ${localCommit}. Build mismatch — make sure ` +
          `the frontend was built with VITE_GIT_COMMIT=${live.commit}.`
      );
      return;
    }
    sessionStorage.setItem(ATTEMPTED_KEY, live.commit);

    console.info(
      `[version-check] new release detected: ${localCommit} -> ${live.commit}. ` +
        `Triggering update.`
    );
    await triggerUpdate();
  };

  setInterval(checkOnce, intervalMs);
  document.addEventListener("visibilitychange", checkOnce);
  // Run once on startup so users that have been on a stale tab for hours
  // don't have to wait for the first interval to elapse.
  void checkOnce();
};
