/**
 * Survey Module Federation loader.
 * Loads the remote survey adapter module at runtime.
 */
let initialized = false;

export async function initSurveyModule(
  adapterStaticUrl: string
): Promise<void> {
  if (initialized || !adapterStaticUrl) {
    return;
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = `${adapterStaticUrl}/assets/remoteEntry.js`;
    script.type = "module";
    script.onload = () => {
      initialized = true;
      resolve();
    };
    script.onerror = (err) => {
      console.error("Failed to load survey module:", err);
      reject(err);
    };
    document.head.appendChild(script);
  });
}

export function isSurveyModuleInitialized(): boolean {
  return initialized;
}
