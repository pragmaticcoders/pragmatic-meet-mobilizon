<template>
  <Suspense>
    <template #default>
      <SurveyResponsesView
        v-if="surveyModuleReady"
        :preferred-username="preferredUsername"
        :survey-id="surveyId"
        :group-id="groupId"
        @error="(e: Error) => console.error('SurveyResponsesView error:', e)"
      />
      <div v-else class="p-8 text-center text-gray-500 text-sm">
        {{ t("Survey module is not available") }}
      </div>
    </template>
    <template #fallback>
      <div class="max-w-5xl mx-auto px-4 py-8">
        <div class="animate-pulse space-y-4">
          <div class="h-8 bg-gray-200 w-64" />
          <div class="h-48 bg-gray-100" />
        </div>
      </div>
    </template>
  </Suspense>
</template>

<script lang="ts" setup>
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useRoute } from "vue-router";
import { surveyModuleReady, loadRemoteComponent } from "@/plugins/surveyModule";

const { t } = useI18n({ useScope: "global" });
const route = useRoute();

defineProps<{
  preferredUsername: string;
  surveyId: string;
}>();

// The numeric group ID is passed by SurveysManager as the ?gid= query param.
// It is needed for the GraphQL authorization check which requires the actor's
// numeric DB id, not the preferredUsername string.
const groupId = computed(() => route.query.gid as string | undefined);

const SurveyResponsesView = defineAsyncComponent({
  loader: () => loadRemoteComponent("./SurveyResponsesView") as Promise<any>,
  errorComponent: {
    template: `<div class="p-8 text-red-600 text-sm">Failed to load survey responses view.</div>`,
  },
  timeout: 15000,
});
</script>
