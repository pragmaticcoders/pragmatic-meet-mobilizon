# Cloudflare cache configuration for Pragmatic Meet

## Why this matters

After every production release, users must see the new version of the
SPA right away — not the cached old one. At the same time we still want
Cloudflare to cache JS, CSS, fonts and images aggressively, so the app
stays fast.

The trick: Vite gives every JS/CSS file a unique name based on its
content (e.g. `main-A1b2C3.js`). A new release means new file names, so
caching them forever is safe. The only files that keep the same name
across releases are:

- `/` and any other HTML route (the SPA shell — lists which hashed
  bundles to load)
- `/service-worker.js` (installs the precache manifest; a stale copy
  pins users on the previous release)
- `/version.json` (build identity polled by the SPA every minute to
  detect new deploys)
- `/survey-assets/remoteEntry.js` (Module Federation
  entry point)

These four classes of URL **must not be cached**:

- HTML routes (`/` and SPA routes),
- `/service-worker.js`,
- `/version.json`,
- `/survey-assets/remoteEntry.js` (fixed filename; keep very short TTL
  or bypass entirely).

Everything else under `/assets/`, `/img/`, `/media/` or `/proxy/`
**can be cached for a year** because those files are content-hashed.

This document is the single source of truth for what to configure on
the Cloudflare dashboard. The matching origin behavior (Phoenix
controllers + nginx) is already in place — see `lib/web/router.ex`,
`lib/web/controllers/version_controller.ex` and
`support/nginx/mobilizon-release.conf`.

## Hostname

We assume a single hostname in the examples below:

- `dev.pragmaticmeet.com` — main app and survey assets

If you use different hostnames (staging, prod), substitute them
everywhere.

---

## Step 1 — Cache Rules

Go to the Cloudflare dashboard → pick the zone → **Caching → Cache
Rules → Create rule**. Add these six rules **in this exact order**.
Cloudflare evaluates them top to bottom and stops on the first match,
so more specific rules (exact path) must sit above more general ones
(path prefixes).

### Rule 1 — bypass cache for the version probe

| Field | Value |
| --- | --- |
| Rule name | `App: bypass cache for version probe` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and http.request.uri.path eq "/version.json")` |
| Then | **Cache eligibility → Bypass cache** |
| Browser TTL | **Override origin → 0 seconds** |

The SPA polls `/version.json` every minute (and on tab focus) to
discover the live build's git SHA. If Cloudflare returns a stale copy,
every user is told they're on the latest version even after we
deployed a new one — completely defeating the auto-update mechanism.

### Rule 2 — bypass cache for the service worker

| Field | Value |
| --- | --- |
| Rule name | `App: bypass cache for service worker` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and http.request.uri.path eq "/service-worker.js")` |
| Then | **Cache eligibility → Bypass cache** |
| Browser TTL | **Override origin → 0 seconds** |

Browsers internally cap SW caching at 24 hours regardless of headers,
but Cloudflare doesn't. A SW served from edge cache keeps installing
the old precache manifest, so users get the new HTML shell pointing at
hashed bundles that the old SW immediately replaces with the previous
release's bundles. Result: zombie cache.

### Rule 3 — bypass cache for HTML routes

| Field | Value |
| --- | --- |
| Rule name | `App: bypass cache for HTML routes` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and not starts_with(http.request.uri.path, "/assets/") and not starts_with(http.request.uri.path, "/img/") and not starts_with(http.request.uri.path, "/media/") and not starts_with(http.request.uri.path, "/proxy/") and not http.request.uri.path matches "\\.(js\|css\|woff2?\|svg\|png\|jpe?g\|webp\|ico\|map)$")` |
| Then | **Cache eligibility → Bypass cache** |
| Browser TTL | **Override origin → 0 seconds** |

The expression says: if the path is **not** under `/assets/`, `/img/`,
`/media/` or `/proxy/` **and** does not end with a known static
extension, treat it as an HTML route and never cache it. This covers
`/`, `/events/...`, `/groups/...`, `/admin`, etc.

### Rule 4 — long cache for hashed assets

| Field | Value |
| --- | --- |
| Rule name | `App: long cache for hashed assets` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and (starts_with(http.request.uri.path, "/assets/") or starts_with(http.request.uri.path, "/img/")))` |
| Then | **Cache eligibility → Eligible for cache**<br>**Edge TTL → Override origin → 1 year**<br>**Browser TTL → Respect existing headers** |

Vite emits content-hashed filenames here, so a year is safe — the URL
itself changes whenever the content does. Browser TTL is left to
"respect existing headers" so the origin's `Cache-Control: public,
max-age=31536000, immutable` (set in nginx) wins.

### Rule 5 — short cache for the survey remote entry

| Field | Value |
| --- | --- |
| Rule name | `App: short cache for survey remote entry` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and http.request.uri.path eq "/survey-assets/remoteEntry.js")` |
| Then | **Cache eligibility → Eligible for cache**<br>**Edge TTL → Override origin → 30 seconds**<br>**Browser TTL → Override origin → 30 seconds** |

`remoteEntry.js` is the only survey file with a fixed name. We allow 30
seconds of edge caching to reduce origin load, but no more — otherwise
users would load survey chunks that no longer
exist after a redeploy. Pick **Bypass cache** instead if you prefer
zero risk over the marginal performance gain.

### Rule 6 — long cache for hashed survey chunks

| Field | Value |
| --- | --- |
| Rule name | `App: long cache for survey hashed assets` |
| When incoming requests match | `(http.host eq "dev.pragmaticmeet.com" and starts_with(http.request.uri.path, "/survey-assets/") and not http.request.uri.path eq "/survey-assets/remoteEntry.js")` |
| Then | **Cache eligibility → Eligible for cache**<br>**Edge TTL → Override origin → 1 year**<br>**Browser TTL → Override origin → 1 year** |

### Final rule order (top to bottom)

1. `App: bypass cache for version probe`
2. `App: bypass cache for service worker`
3. `App: bypass cache for HTML routes`
4. `App: long cache for hashed assets`
5. `App: short cache for survey remote entry`
6. `App: long cache for survey hashed assets`

---

## Step 2 — Other Cloudflare settings

### Caching → Configuration

- **Browser Cache TTL:** `Respect existing headers`. The origin already
  sends correct `Cache-Control` for every URL class — let it win.
- **Always Online:** **OFF**. It can serve very old snapshots of the
  site after a deploy, which is exactly what we're trying to avoid.
- **Tiered Cache:** safe to leave ON; it only affects cacheable
  responses and the bypass rules above keep critical files out of any
  tier.

### Speed → Optimization

- **Auto Minify (HTML / CSS / JS):** **OFF** for all three. Cloudflare
  rewrites files at the edge, which:
  - changes the bytes of hashed bundles, breaking subresource integrity
    and Workbox's precache hash check (the SW install fails and the
    old SW stays active — zombie cache);
  - mutates `index.html` content, which is fine in isolation but adds
    a useless transformation on a path we already mark `no-store`.
  Vite already minifies everything during the build. Doing it twice
  helps no one.
- **Rocket Loader:** **OFF**. It defers and reorders `<script>`
  execution, which breaks Vue mounting and Apollo client setup in
  unpredictable ways.
- **Brotli:** ON is fine; it's content-aware compression, not a
  rewrite.

### Rules → Page Rules

- If old **Page Rules** exist for these hostnames, **delete them**.
  Cache Rules are the new system; mixing both produces order-dependent
  surprises.

### Workers / Transform Rules

- Make sure no Worker or Transform Rule rewrites `Cache-Control` for
  the four critical paths (`/`, `/service-worker.js`, `/version.json`,
  `/survey-assets/remoteEntry.js`). If one does, exclude these paths
  explicitly.

### SSL/TLS → Edge Certificates

- **Automatic HTTPS Rewrites:** ON is fine.
- **Always Use HTTPS:** ON.
- **Min TLS Version:** `TLS 1.2` or higher.

These don't affect cache directly but breaking TLS would mask
caching bugs by failing earlier.

---

## Step 3 — Manual purge after each deploy (optional, recommended)

Until we add an automated purge step to CI, run this once after every
production deploy:

1. Cloudflare → **Caching → Configuration → Purge Cache → Custom
   Purge**.
2. Paste these URLs (one per line):
   ```
   https://dev.pragmaticmeet.com/
   https://dev.pragmaticmeet.com/service-worker.js
   https://dev.pragmaticmeet.com/version.json
   https://dev.pragmaticmeet.com/survey-assets/remoteEntry.js
   ```
3. Click **Purge**.

These are the only URLs with stable names — every other asset is
content-hashed, so nobody will ever request the old URLs again and
purging them is unnecessary.

---

## Step 4 — Verify it works

### 4.1 Header check

In a terminal:

```bash
curl -sI https://dev.pragmaticmeet.com/
curl -sI https://dev.pragmaticmeet.com/service-worker.js
curl -sI https://dev.pragmaticmeet.com/version.json
curl -sI https://dev.pragmaticmeet.com/assets/main-XXXXX.js     # use a real hash
curl -sI https://dev.pragmaticmeet.com/survey-assets/remoteEntry.js
```

Expected response headers:

| URL | `cache-control` | `cf-cache-status` |
| --- | --- | --- |
| `/` | `no-store, no-cache, must-revalidate` | `BYPASS` or `DYNAMIC` |
| `/service-worker.js` | `no-cache, no-store, must-revalidate` | `BYPASS` or `DYNAMIC` |
| `/version.json` | `no-store, no-cache, must-revalidate` | `BYPASS` or `DYNAMIC` |
| `/assets/main-HASH.js` | `public, max-age=31536000, immutable` | `HIT` (after the second request) |
| `/survey-assets/remoteEntry.js` | `public, max-age=30` | `HIT` or `MISS` |

If you see `HIT` for any of the first three rows, a Cache Rule is
missing or ordered below a more general rule.

### 4.2 Auto-update flow check

In the browser DevTools console you should see a single banner line on
load:

```
Pragmatic Meet  v5.1.4  a3f9c12  2026-04-30T07:00:00Z
```

The short SHA (`a3f9c12`) is the git commit the build was made from.
If you see `dev` instead of a SHA, the Docker image was not built with
the `VCS_REF` build-arg, or the build-arg did not reach the `assets`
stage of the Dockerfile.

You can also inspect the build identity manually:

```js
__APP_VERSION__   // "5.1.4"
__GIT_COMMIT__    // "a3f9c12"
__BUILD_TIME__    // "2026-04-30T07:00:00Z"
```

To smoke-test the auto-update loop end to end:

1. Note the current SHA shown in the console.
2. Deploy a new build.
3. Leave the tab in the foreground. Within ~1 minute (or instantly on
   tab focus), DevTools should print:
   ```
   [version-check] new release detected: <old> -> <new>. Triggering update.
   [sw] controller changed, reloading to pick up the new release.
   ```
   followed by an automatic page reload.
4. The new console banner should show the `<new>` SHA.

If the reload doesn't happen automatically, check (in order):

- `/version.json` returns the **new** SHA when you `curl` it through
  Cloudflare. If it returns the old one, Rule 1 is missing or
  misconfigured.
- `/service-worker.js` returns 200 with `cf-cache-status: BYPASS`. If
  it's a HIT, Rule 2 is missing.
- The browser DevTools → Application → Service Workers panel shows the
  new worker as "activated and is running" (not "waiting"). If it's
  stuck waiting, the deployed `service-worker.ts` did not reach the
  origin with the `skipWaiting()` install handler — rebuild and
  redeploy.

---

## Testing locally

The dev and prod code paths for the cache-refresh flow are identical —
no `import.meta.env.PROD` guards anywhere — so the whole loop
(`/version.json` polling → `registration.update()` → `skipWaiting` →
`clients.claim()` → `controllerchange` → reload) can be exercised on
your laptop. There is no Cloudflare in front of localhost, so the
local test only covers the **origin + browser** half of the flow; the
"is Cloudflare correctly bypassing?" half is covered by Step 4.1
above.

### How dev mode differs from prod

- The Phoenix app serves the SPA shell on `http://localhost:4000` and
  injects script tags pointing at the Vite dev server on
  `http://localhost:5173` (see
  `lib/web/templates/page/index.html.heex` → `<%= Vite.vite_client()
  %>`).
- The Service Worker is registered on the page origin (`:4000`), so
  the file `/service-worker.js` must be served by Phoenix, not Vite.
  Phoenix's `Plug.Static` reads from `priv/static/` (configured in
  `lib/web/endpoint.ex`).
- A pure `npm run dev` (HMR-only) build does **not** populate
  `priv/static/service-worker.js`. The SW registration call will
  succeed but receive a 404, the `error` callback will log it, and
  the polling will fall back to a hard `window.location.reload()`
  when it detects a deploy. Good enough for a smoke test of the
  version-check, but the full SW lifecycle (`skipWaiting`,
  `clients.claim`, `controllerchange`) cannot be exercised this way.
- A `vite build` (or `vite build --watch` for live rebuilds) puts
  `service-worker.js` and `assets/*` into `priv/static/`. Phoenix
  serves them, and the full prod-equivalent flow works.

### Recommended workflow — full SW lifecycle

```bash
# Terminal 1: rebuild frontend on every source change.
# `--watch` keeps SW + manifest in sync without HMR's edge cases.
VITE_GIT_COMMIT=abc1111 npm run build:assets -- --watch

# Terminal 2: backend with the matching SHA.
VITE_GIT_COMMIT=abc1111 mix phx.server
```

Open `http://localhost:4000`, then in DevTools:

- Console banner shows `Pragmatic Meet v5.1.4 abc1111 …` — confirms
  the bundle was built with the right env var.
- Application → Service Workers → status is "activated and is
  running" (not "waiting" / "redundant") — confirms `skipWaiting`
  works.
- `curl -sI http://localhost:4000/service-worker.js` shows
  `cache-control: no-cache, no-store, must-revalidate` — confirms
  nginx-equivalent behavior is in place at the origin (in dev there's
  no nginx, but the `VersionController` and the SW response itself
  carry the right headers anyway).
- `curl -s http://localhost:4000/version.json` returns
  `{"version":"5.1.4","commit":"abc1111","build_time":"…"}`.

### Simulating a deploy

While the app is open in a browser tab, simulate a deploy by changing
only the backend's SHA env var (no frontend rebuild — we want a
deliberate mismatch):

```bash
# Stop terminal 2 (Ctrl+C), then restart with a new SHA.
VITE_GIT_COMMIT=def2222 mix phx.server
```

Within ~1 minute (or instantly when you re-focus the tab) the DevTools
console should print:

```
[version-check] new release detected: abc1111 -> def2222. Triggering update.
[sw] controller changed, reloading to pick up the new release.
```

…followed by an automatic page reload. If the frontend bundles were not
rebuilt with `def2222`, the console banner can still show `abc1111`.
This is expected in this simulation and still confirms that the
**detection and reload mechanism works**. To complete the end-to-end
test (banner reflects the new SHA), rebuild the frontend with the new
SHA after the simulated deploy:

```bash
# Terminal 1 already running `--watch`, just bump the env and let it
# rebuild — or restart it explicitly:
VITE_GIT_COMMIT=def2222 npm run build:assets -- --watch
```

Now the next reload picks up bundles built with `def2222`, the banner
flips, and `/version.json` and `__GIT_COMMIT__` agree again.

### Quick smoke test in HMR mode (`npm run dev`)

For UI iteration where you don't care about the full SW lifecycle
but still want to verify the polling logic:

```bash
# Terminal 1
npm run dev

# Terminal 2 — backend with a fixed SHA so the mismatch is
# deterministic.
VITE_GIT_COMMIT=initial mix phx.server
```

Open the app on `http://localhost:4000` (NOT `:5173` — the SPA shell
is rendered by Phoenix). The console will log:

```
Pragmatic Meet v5.1.4 dev <build-time>
[version-check] starting (interval=60000ms, local=dev)
Error during service worker registration: ...  ← expected, no SW file
```

Now restart the backend with a different SHA. Within ~1 minute, the
console should print
`[version-check] new release detected: dev -> <new>` and trigger a
full-page reload (no SW means the fallback `window.location.reload()`
runs directly). Repeat with the same `<new>` SHA and the loop guard
prevents a second reload — instead you'll see:

```
[version-check] already attempted update to <new> but bundle still
reports dev. Build mismatch — make sure the frontend was built with
VITE_GIT_COMMIT=<new>.
```

That's the safety net working as designed.

### Resetting between tests

Service workers persist across page loads and across browser sessions.
After a test where you intentionally produced a stuck/broken state,
clean up via DevTools:

1. Application → Service Workers → "Unregister" next to the active
   worker.
2. Application → Storage → "Clear site data" (clears caches,
   sessionStorage including the version-check loop guard, and
   IndexedDB).
3. Hard reload (Cmd+Shift+R).

Alternatively, in the browser address bar:

```
chrome://serviceworker-internals/   # full SW inventory
chrome://settings/siteData           # storage cleanup
```

---

## Quick reference: who sets which header

| URL | Origin (Phoenix / nginx) | Cloudflare rule |
| --- | --- | --- |
| `/` | nginx `location = /` → `no-store, no-cache, must-revalidate` | Rule 3 (bypass) |
| `/events/...`, `/groups/...`, `/admin`, ... | nginx `location /` → `public, max-age=0, must-revalidate` | Rule 3 (bypass) |
| `/service-worker.js` | nginx `location = /service-worker.js` → `no-cache, no-store, must-revalidate` | Rule 2 (bypass) |
| `/version.json` | `VersionController` → `no-store, no-cache, must-revalidate` | Rule 1 (bypass) |
| `/assets/*`, `/img/*` | nginx → `public, max-age=31536000, immutable` | Rule 4 (1 year edge) |
| `/media/*`, `/proxy/*` | nginx → `public, max-age=31536000, immutable` | uses Rule 4's siblings via the regex |
| `/survey-assets/remoteEntry.js` | app origin | Rule 5 (30s edge) |
| `/survey-assets/<hash-or-chunk-path>` | app origin | Rule 6 (1 year edge) |

If any row above doesn't match what `curl -I` shows in production,
fix the origin first (it's the source of truth) and only then revisit
the Cloudflare rules.
