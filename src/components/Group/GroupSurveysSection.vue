<template>
  <div class="space-y-4">
    <Suspense>
      <template #default>
        <SurveysManager
          v-if="surveyModuleReady"
          :context-id="contextId"
          :group-id="group.id"
          :group-preferred-username="group.preferredUsername"
          :is-admin="isAdmin"
          :is-member="isMember"
          @error="(e: Error) => console.error('SurveysManager error:', e)"
        />
        <div v-else class="p-4 text-center text-gray-500 text-sm">
          {{ t("Survey module is not available") }}
        </div>
      </template>
      <template #fallback>
        <div class="animate-pulse h-32 bg-gray-100" />
      </template>
    </Suspense>

    <!-- "View my response" button for regular members (non-admins) -->
    <div v-if="isMember && !isAdmin" class="flex justify-end px-1">
      <o-button
        variant="info"
        outlined
        size="small"
        icon-left="clipboard-text-outline"
        @click="openMyResponseModal"
      >
        {{ t("View my survey response") }}
      </o-button>
    </div>

    <SurveyResponseModal
      v-model:active="responseModalOpen"
      :loading="responseLoading"
      :error="responseError ?? undefined"
      :response-data="responseData"
      :title="t('My survey response')"
    />
  </div>
</template>

<script lang="ts" setup>
import { computed, defineAsyncComponent, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useLazyQuery } from "@vue/apollo-composable";
import type { IGroup } from "@/types/actor/group.model";
import type { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import { surveyModuleReady, loadRemoteComponent } from "@/plugins/surveyModule";
import { MY_SURVEY_RESPONSE } from "@/graphql/event";
import SurveyResponseModal from "@/components/Survey/SurveyResponseModal.vue";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  group: IGroup;
  groupMember: IMember | undefined;
}>();

const contextId = computed(() => `mobilizon_group_survey:${props.group.id}`);

const isAdmin = computed(
  () =>
    props.groupMember?.role === MemberRole.ADMINISTRATOR ||
    props.groupMember?.role === MemberRole.CREATOR
);

const isMember = computed(
  () =>
    props.groupMember?.role !== undefined &&
    [
      MemberRole.MEMBER,
      MemberRole.MODERATOR,
      MemberRole.ADMINISTRATOR,
      MemberRole.CREATOR,
    ].includes(props.groupMember.role as MemberRole)
);

// "View my response" modal state
const responseModalOpen = ref(false);
const responseLoading = ref(false);
const responseError = ref<string | null>(null);
const responseData = ref<{ schema: any; data: Record<string, unknown> } | null>(
  null
);

const { load: loadMyResponse } = useLazyQuery<{
  mySurveyResponse: { schema: any; data: Record<string, unknown> } | null;
}>(MY_SURVEY_RESPONSE);

const openMyResponseModal = async () => {
  responseModalOpen.value = true;
  responseLoading.value = true;
  responseError.value = null;
  responseData.value = null;
  try {
    const result = await loadMyResponse(MY_SURVEY_RESPONSE, {
      contextId: contextId.value,
    });
    responseData.value = result?.mySurveyResponse ?? null;
  } catch (e: any) {
    responseError.value =
      e?.graphQLErrors?.[0]?.message ??
      e?.message ??
      t("Failed to load survey response");
  } finally {
    responseLoading.value = false;
  }
};

const SurveysManager = defineAsyncComponent({
  loader: () => loadRemoteComponent("./SurveysManager") as Promise<any>,
  errorComponent: {
    template: `<div class="p-4 text-red-600 text-sm">Failed to load surveys manager.</div>`,
  },
  timeout: 15000,
});
</script>
