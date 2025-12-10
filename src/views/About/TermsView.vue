<template>
  <div class="bg-white dark:bg-gray-900">
    <h1
      class="text-[30px] font-bold text-gray-900 dark:text-gray-100 mb-8 leading-[40px]"
    >
      {{ t("Terms of Service") }}
    </h1>

    <div
      v-if="terms"
      class="space-y-8 text-gray-900 dark:text-gray-300 max-w-[592px]"
    >
      <div
        v-if="terms.bodyHtml"
        class="prose dark:prose-invert max-w-none"
        v-html="terms.bodyHtml"
      />
      <p v-else-if="terms.type === 'URL' && terms.url">
        {{ t("Please refer to") }}
        <a
          :href="terms.url"
          class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ t("our terms of service") }}
        </a>
      </p>
      <p v-else>{{ t("No terms of service defined yet.") }}</p>
    </div>
    <div v-else class="text-gray-900 dark:text-gray-300">
      {{ t("Loading...") }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { computed } from "vue";
import { useQuery } from "@vue/apollo-composable";
import { TERMS } from "@/graphql/config";
import { i18n } from "@/utils/i18n";

interface ITerms {
  type: string;
  url: string | null;
  bodyHtml: string | null;
}

interface IConfig {
  terms: ITerms;
}

const { t } = useI18n({ useScope: "global" });

const currentLocaleCode = computed(() => {
  // i18n.global.locale is a string, not a ref, so use it directly
  const i18nLocale = typeof i18n.global.locale === 'string' ? i18n.global.locale : i18n.global.locale.value;
  const documentLocale = document.documentElement.getAttribute("lang");
  const fullLocale = i18nLocale || documentLocale || "en";
  return fullLocale?.split(/[-_]/)[0] || "en";
});

const { result: configResult } = useQuery<{ config: IConfig }>(
  TERMS,
  () => ({
    locale: currentLocaleCode.value,
  })
);

const terms = computed(() => configResult.value?.config.terms);

useHead({
  title: t("Terms of Service"),
});
</script>
