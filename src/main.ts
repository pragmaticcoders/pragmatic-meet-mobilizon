import { provide, createApp, h, ref } from "vue";
import VueScrollTo from "vue-scrollto";
// import VueAnnouncer from "@vue-a11y/announcer";
// import VueSkipTo from "@vue-a11y/skip-to";
import App from "./App.vue";
import { router } from "./router";
import { i18n, locale } from "./utils/i18n";
import { apolloClient } from "./vue-apollo";

// Single boot banner: makes it trivial for support and devs to confirm
// which build the user actually has loaded — match this SHA against
// `/version.json` and the deployed git tag. `__APP_VERSION__`,
// `__GIT_COMMIT__` and `__BUILD_TIME__` are baked at build time by
// `vite.config.js`. Printed via `console.info` (rendered even when the
// browser DevTools console is filtered to "Info" only).
console.info(
  "%c Pragmatic Meet %c v" +
    __APP_VERSION__ +
    " %c " +
    __GIT_COMMIT__ +
    " %c " +
    __BUILD_TIME__ +
    " ",
  "background:#1f2937;color:#fff;padding:2px 6px;border-radius:0;font-weight:bold;",
  "background:#2563eb;color:#fff;padding:2px 6px;",
  "background:#10b981;color:#fff;padding:2px 6px;font-family:monospace;",
  "background:#6b7280;color:#fff;padding:2px 6px;"
);

// Also expose as plain globals so users can paste these three lines in
// the DevTools console without needing to know the build flow.
(window as unknown as Record<string, string>).__APP_VERSION__ = __APP_VERSION__;
(window as unknown as Record<string, string>).__GIT_COMMIT__ = __GIT_COMMIT__;
(window as unknown as Record<string, string>).__BUILD_TIME__ = __BUILD_TIME__;
import Breadcrumbs from "@/components/Utils/NavBreadcrumbs.vue";
import { DefaultApolloClient } from "@vue/apollo-composable";
import "./registerServiceWorker";
import { startVersionCheck } from "./composition/useVersionCheck";
import "./assets/tailwind.css";
import { setAppForAnalytics } from "./services/statistics";
import { dateFnsPlugin } from "./plugins/dateFns";
import { dialogPlugin } from "./plugins/dialog";
import { snackbarPlugin } from "./plugins/snackbar";
import { notifierPlugin } from "./plugins/notifier";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import Oruga from "@oruga-ui/oruga-next";
import "@oruga-ui/theme-oruga/dist/oruga.css";
import "./assets/oruga-tailwindcss.css";
import { orugaConfig } from "./oruga-config";
import MaterialIcon from "./components/core/MaterialIcon.vue";
import { createHead } from "@unhead/vue";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";
import { initSurveyModule } from "./plugins/surveyModule";

// Vue.use(VueAnnouncer);
// Vue.use(VueSkipTo);

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient);
  },
  render: () => h(App),
});

app.use(router);
app.use(i18n);
app.use(dateFnsPlugin, { locale });
app.use(dialogPlugin);
app.use(snackbarPlugin);
app.use(notifierPlugin);
app.use(VueScrollTo);
app.use(FloatingVue);

app.component("breadcrumbs-nav", Breadcrumbs);
app.component("material-icon", MaterialIcon);
app.use(Oruga, orugaConfig);

const instanceName = ref<string>();

apolloClient
  .query<{ config: IConfig }>({
    query: CONFIG,
  })
  .then(({ data: configData }) => {
    instanceName.value = configData.config?.name;

    const primaryColor = configData.config?.primaryColor;
    if (primaryColor) {
      document.documentElement.style.setProperty(
        "--custom-primary",
        primaryColor
      );
    }
    const secondaryColor = configData.config?.secondaryColor;
    if (secondaryColor) {
      document.documentElement.style.setProperty(
        "--custom-secondary",
        secondaryColor
      );
    }

    // Initialize survey module if enabled
    if (configData.config?.plugins?.surveysEnabled) {
      const staticUrl = configData.config?.plugins?.surveysAdapterStaticUrl;
      if (staticUrl) {
        initSurveyModule(staticUrl).catch((err) =>
          console.warn("Failed to initialize survey module:", err)
        );
      }
    }
  });

const head = createHead();
app.use(head);

app.mount("#app");

setAppForAnalytics(app);

// Kick off the deploy-detection polling loop in dev *and* prod. The
// loop is idempotent when local SHA equals the live one (`/version.json`
// returns the same value the bundle was built with), and the
// `useVersionCheck` reload-loop guard kicks in if SHAs are intentionally
// mismatched for testing — see `docs/CLOUDFLARE_CACHE.md` ("Testing
// locally") for the full step-by-step.
startVersionCheck();
