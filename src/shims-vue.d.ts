declare module "*.vue" {
  import type { DefineComponent } from "vue";

  // eslint-disable-next-line @typescript-eslint/ban-types
  const component: DefineComponent<{}, {}, {}>;
  export default component;
}

declare module "*.svg" {
  import Vue, { VueConstructor } from "vue";

  const content: VueConstructor<Vue>;
  export default content;
}

declare module "@vue-leaflet/vue-leaflet";

// Compile-time constants injected by `vite.config.js` (see `define:`).
// Available everywhere in the bundle without imports. Stringified at
// build time, so they're plain string literals at runtime.
declare const __APP_VERSION__: string;
declare const __GIT_COMMIT__: string;
declare const __BUILD_TIME__: string;
