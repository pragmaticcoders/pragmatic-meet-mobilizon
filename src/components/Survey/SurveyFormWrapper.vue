<template>
  <Suspense>
    <template #default>
      <SurveyForm
        v-if="surveyModuleReady"
        :context-id="contextId"
        :survey-schema="surveySchema"
        @completed="$emit('completed')"
        @error="(e: Error) => $emit('error', e)"
      />
      <div v-else class="p-4 text-center text-gray-500">
        {{ t("Survey module is not available") }}
      </div>
    </template>
    <template #fallback>
      <div class="p-4 space-y-3">
        <o-skeleton height="40px" />
        <o-skeleton height="40px" />
        <o-skeleton height="40px" />
      </div>
    </template>
  </Suspense>
</template>

<script lang="ts" setup>
import { defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { surveyModuleReady, loadRemoteComponent } from "@/plugins/surveyModule";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  contextId: string;
  surveySchema: object;
}>();

defineEmits<{
  completed: [];
  error: [error: Error];
}>();

const SurveyForm = defineAsyncComponent({
  loader: () => loadRemoteComponent("./SurveyForm") as Promise<any>,
  errorComponent: {
    template: `<div class="p-4 text-red-600 text-sm">Failed to load survey form.</div>`,
  },
  timeout: 15000,
});
</script>
