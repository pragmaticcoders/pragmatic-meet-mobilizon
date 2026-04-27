<template>
  <div class="max-w-screen-xl" v-if="config">
    <h1>{{ t("Rules") }}</h1>
    <div
      class="prose dark:prose-invert"
      v-html="config.rules"
      v-if="config.rules"
    />
    <p v-else>{{ t("No rules defined yet.") }}</p>
  </div>
</template>

<script lang="ts" setup>
import { RULES } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@/utils/head";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { i18n } from "@/utils/i18n";

const { t, locale } = useI18n({ useScope: "global" });

const currentLocaleCode = computed(() => {
  const i18nLocale = locale.value;
  const documentLocale = document.documentElement.getAttribute("lang");
  const fullLocale = i18nLocale || documentLocale || "en";
  return fullLocale?.split(/[-_]/)[0] || "en";
});

const { result: configResult } = useQuery<{ config: IConfig }>(RULES, () => ({
  locale: currentLocaleCode.value,
}));

const config = computed(() => configResult.value?.config);

useHead({
  title: t("Rules"),
});
</script>
