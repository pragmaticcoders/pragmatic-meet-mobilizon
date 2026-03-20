import { PLUGINS_CONFIG } from "@/graphql/config";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";

export interface IPluginsConfig {
  surveysEnabled: boolean;
  surveysAdapterStaticUrl: string;
}

export function usePlugins() {
  const {
    result: pluginsResult,
    error,
    loading,
  } = useQuery<{
    config: { plugins: IPluginsConfig };
  }>(PLUGINS_CONFIG, undefined, { fetchPolicy: "cache-first" });

  const surveysEnabled = computed(
    () => pluginsResult.value?.config?.plugins?.surveysEnabled ?? false
  );
  const surveysAdapterStaticUrl = computed(
    () => pluginsResult.value?.config?.plugins?.surveysAdapterStaticUrl ?? ""
  );

  return { surveysEnabled, surveysAdapterStaticUrl, error, loading };
}
