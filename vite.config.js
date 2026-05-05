import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";
import path from "path";
import { execSync } from "child_process";
import { VitePWA } from "vite-plugin-pwa";
import { visualizer } from "rollup-plugin-visualizer";
import federation from "@originjs/vite-plugin-federation";

// Resolve build identity once per Vite invocation. Order of preference:
// 1. Explicit env vars (set by Docker build args / CI) — single source of
//    truth that also reaches the Elixir VersionController so `/version.json`
//    and the JS bundle report the same SHA.
// 2. Local git for `npm run build` / `npm run dev` outside Docker.
// 3. Hardcoded "dev" sentinel — `useVersionCheck.ts` treats it as "skip
//    polling", so devs don't get reload loops.
const resolveAppVersion = () =>
  process.env.VITE_APP_VERSION ||
  process.env.npm_package_version ||
  "dev";

const resolveGitCommit = () => {
  if (process.env.VITE_GIT_COMMIT) {
    return process.env.VITE_GIT_COMMIT.slice(0, 7);
  }
  try {
    return execSync("git rev-parse --short=7 HEAD", { stdio: ["ignore", "pipe", "ignore"] })
      .toString()
      .trim();
  } catch {
    return "dev";
  }
};

const resolveBuildTime = () =>
  process.env.VITE_BUILD_TIME || new Date().toISOString();

const APP_VERSION = resolveAppVersion();
const GIT_COMMIT = resolveGitCommit();
const BUILD_TIME = resolveBuildTime();

export default defineConfig(({ command }) => {
  const isDev = command !== "build";
  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }

  const isStory = Boolean(process.env.HISTOIRE);

  const plugins = [
    federation({
      name: "mobilizon",
      remotes: {
        adapterModule:
          "https://placeholder-replaced-at-runtime/assets/remoteEntry.js",
      },
      // vue and Apollo client are shared so SurveyForm.vue (loaded from the adapter
      // via Module Federation) uses the same instances — including the Apollo client
      // that already carries the Guardian JWT of the logged-in user.
      shared: ["vue", "@vue/apollo-composable", "@apollo/client"],
    }),
    vue(),
    visualizer(),
  ];

  if (!isStory) {
    plugins.push(
      VitePWA({
        registerType: "autoUpdate",
        strategies: "injectManifest",
        srcDir: "src",
        filename: "service-worker.ts",
        // injectRegister: "auto",
        // devOptions: {
        //   enabled: true,
        // },
        manifest: {
          name: "Mobilizon",
          short_name: "Mobilizon",
          orientation: "portrait-primary",
          theme_color: "#ffd599",
          icons: [
            {
              src: "./img/icons/favicon.svg",
              sizes: "192x192",
              type: "image/svg+xml",
            },
            {
              src: "./img/icons/favicon.svg",
              sizes: "512x512",
              type: "image/svg+xml",
            },
            {
              src: "./img/icons/favicon.svg",
              sizes: "192x192",
              type: "image/svg+xml",
              purpose: "maskable",
            },
            {
              src: "./img/icons/favicon.svg",
              sizes: "512x512",
              type: "image/svg+xml",
              purpose: "maskable",
            },
          ],
        },
      })
    );
  }

  const build = {
    manifest: true,
    outDir: path.resolve(__dirname, "priv/static"),
    emptyOutDir: true,
    sourcemap: true,
    target: "esnext",
  };

  if (!isStory) {
    // overwrite default .html entry
    build.rollupOptions = {
      input: {
        main: "src/main.ts",
      },
    };
  }

  const esbuild = {
    target: "esnext",
  };

  return {
    plugins,
    build,
    esbuild,
    // Bake build identity into the bundle as compile-time constants.
    // `useVersionCheck.ts` reads `__GIT_COMMIT__` and the `main.ts`
    // boot banner reads all three. JSON.stringify is required by the
    // `define:` API so the values are emitted as proper JS literals.
    define: {
      __APP_VERSION__: JSON.stringify(APP_VERSION),
      __GIT_COMMIT__: JSON.stringify(GIT_COMMIT),
      __BUILD_TIME__: JSON.stringify(BUILD_TIME),
    },
    server: {
      host: "0.0.0.0",
      port: 5173,
      strictPort: true,
      hmr: {
        port: 5173,
        host: "localhost",
        clientPort: 5173,
      },
    },
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
        unfetch: path.resolve(
          __dirname,
          "node_modules",
          "unfetch",
          "dist",
          "unfetch.mjs"
        ),
      },
    },
    css: {
      preprocessorOptions: {
        scss: {
          sassOptions: {
            quietDeps: true,
          },
        },
      },
    },
    test: {
      environment: "jsdom",
      cache: {
        dir: path.resolve(__dirname, "./.vitest-cache"),
      },
      resolve: {
        alias: {
          "@": path.resolve(__dirname, "./src"),
        },
      },
      coverage: {
        reporter: ["text", "json", "html"],
      },
      setupFiles: [path.resolve(__dirname, "./tests/unit/setup.ts")],
      include: [path.resolve(__dirname, "./tests/unit/specs/**/*.spec.ts")],
    },
  };
});
