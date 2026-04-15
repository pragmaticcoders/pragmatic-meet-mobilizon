/**
 * Survey Module Federation loader.
 *
 * The remote (pragmatic-forms adapter) builds its components as an ES module
 * that exports { get, init } — it does NOT register itself globally.
 * Vite's vite-plugin-federation host code resolves the remote by importing
 * from the URL baked into the build (placeholder). We bypass that mechanism
 * entirely and call container.get() directly.
 *
 * `surveyModuleReady` is a Vue ref so components react when the module loads.
 */
import * as Vue from "vue";
import * as VueApolloComposable from "@vue/apollo-composable";
import * as VueI18n from "vue-i18n";
import { ref } from "vue";

export const surveyModuleReady = ref(false);

interface RemoteContainer {
  get: (module: string) => Promise<() => unknown>;
  init: (scope: Record<string, unknown>) => Promise<void>;
}

// The loaded remote container — used by loadRemoteComponent.
let remoteContainer: RemoteContainer | null = null;

export async function initSurveyModule(
  adapterStaticUrl: string
): Promise<void> {
  if (remoteContainer || !adapterStaticUrl) {
    return;
  }

  try {
    const remoteUrl = `${adapterStaticUrl}/assets/remoteEntry.js`;
    // Dynamic import — bypasses Vite's placeholder URL resolution.
    const container = (await import(
      /* @vite-ignore */ remoteUrl
    )) as RemoteContainer;

    // NOTE: Do NOT inject formio CSS or Font Awesome here.
    // The builder is rendered in an isolated iframe (builder.html) which loads
    // its own CSS. Injecting Bootstrap 4 globally here would break Mobilizon's
    // Tailwind-based layout across the entire app.

    // Pass the HOST's Vue instance to the remote's shared scope.
    // Without this, importShared('vue') in the remote falls back to loading
    // its own bundled Vue — a different instance from Mobilizon's. Components
    // rendered in Mobilizon's Vue context can't resolve components registered
    // in the adapter's Vue instance, causing "Failed to resolve component" errors.
    //
    // @vue/apollo-composable must also be shared: its DefaultApolloClient is a
    // unique Symbol used as the Vue inject key. If the remote bundles its own
    // copy, it gets a *different* Symbol instance and inject() returns undefined,
    // producing the "Apollo client with id default not found" error on form submit.
    const shareScope = {
      vue: {
        [Vue.version]: {
          get: async () => async () => Vue,
          scope: "default",
          loaded: 1,
          from: "mobilizon",
        },
      },
      "@vue/apollo-composable": {
        "4.0.1": {
          get: async () => async () => VueApolloComposable,
          scope: "default",
          loaded: 1,
          from: "mobilizon",
        },
      },
      "vue-i18n": {
        [VueI18n.VERSION]: {
          get: async () => async () => VueI18n,
          scope: "default",
          loaded: 1,
          from: "mobilizon",
        },
      },
    };
    await container.init(shareScope);
    remoteContainer = container as RemoteContainer;
    surveyModuleReady.value = true;
  } catch (err) {
    console.error("Failed to load survey module:", err);
  }
}

/**
 * Load a component exposed by the remote adapter.
 * @param name — the expose key, e.g. "./SurveyForm" or "./SurveyBuilder"
 */
export async function loadRemoteComponent(name: string): Promise<unknown> {
  if (!remoteContainer) {
    throw new Error("Survey module is not initialized");
  }
  const factory = await remoteContainer.get(name);
  return (factory as () => unknown)();
}

export function isSurveyModuleInitialized(): boolean {
  return remoteContainer !== null;
}
