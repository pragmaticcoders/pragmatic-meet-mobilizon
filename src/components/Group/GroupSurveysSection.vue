<template>
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
</template>

<script lang="ts" setup>
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import type { IGroup } from "@/types/actor/group.model";
import type { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import { surveyModuleReady, loadRemoteComponent } from "@/plugins/surveyModule";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  group: IGroup;
  groupMember: IMember | undefined;
}>();

const contextId = computed(() => `mobilizon_group_survey:${props.group.id}`);

const isAdmin = computed(() =>
  props.groupMember?.role === MemberRole.ADMINISTRATOR ||
  props.groupMember?.role === MemberRole.CREATOR
);

const isMember = computed(() =>
  props.groupMember?.role !== undefined &&
  [MemberRole.MEMBER, MemberRole.MODERATOR, MemberRole.ADMINISTRATOR, MemberRole.CREATOR]
    .includes(props.groupMember.role as MemberRole)
);

const SurveysManager = defineAsyncComponent({
  loader: () => loadRemoteComponent("./SurveysManager") as Promise<any>,
  errorComponent: {
    template: `<div class="p-4 text-red-600 text-sm">Failed to load surveys manager.</div>`,
  },
  timeout: 15000,
});
</script>
