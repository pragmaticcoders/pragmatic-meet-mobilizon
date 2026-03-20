<template>
  <Suspense>
    <template #default>
      <SurveyForm
        v-if="isSurveyModuleReady"
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
import { defineAsyncComponent, ref, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import { isSurveyModuleInitialized } from "@/plugins/surveyModule";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  contextId: string;
  surveySchema: object;
}>();

defineEmits<{
  completed: [];
  error: [error: Error];
}>();

const isSurveyModuleReady = ref(false);

const SurveyForm = defineAsyncComponent(
  () => import("adapterModule/SurveyForm")
);

onMounted(() => {
  isSurveyModuleReady.value = isSurveyModuleInitialized();
});
</script>
