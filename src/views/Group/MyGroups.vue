<template>
  <section class="max-w-screen-xl mx-auto px-4 md:px-16 py-6">
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">
        {{ t("My groups") }}
      </h1>
      <p class="text-base text-gray-600 dark:text-gray-400 max-w-3xl">
        {{
          t(
            "Groups are spaces for coordination and preparation to better organize events and manage your community."
          )
        }}
      </p>
    </div>
    <div class="flex mb-6" v-if="!hideCreateGroupButton">
      <o-button
        tag="router-link"
        variant="primary"
        class="px-5 py-2.5 font-medium"
        :to="{ name: RouteName.CREATE_GROUP }"
        >{{ t("Create group") }}</o-button
      >
    </div>
    <o-loading v-model:active="loading"></o-loading>
    <InvitationsList
      :invitations="invitations"
      @accept-invitation="acceptInvitation"
      @reject-invitation="rejectInvitation"
    />
    <section v-if="memberships && memberships.length > 0" class="space-y-6">
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <GroupMemberCard
          v-for="member in memberships"
          :key="member.id"
          :member="member"
          @leave="leaveGroup({ groupId: member.parent.id })"
        />
      </div>
      <div class="flex justify-center mt-8">
        <o-pagination
          :total="membershipsPages.total"
          v-show="membershipsPages.total > limit"
          v-model:current="page"
          :per-page="limit"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </div>
    </section>
    <section
      class="flex flex-col items-center justify-center py-12"
      v-if="memberships.length === 0 && !loading"
    >
      <div class="max-w-md text-center">
        <div class="mb-6">
          <svg
            class="w-20 h-20 mx-auto text-gray-300 dark:text-gray-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            ></path>
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          {{ t("You are not part of any group.") }}
        </h3>
        <p class="text-gray-600 dark:text-gray-400">
          <i18n-t keypath="Do you wish to {create_group} or {explore_groups}?">
            <template #create_group>
              <router-link
                :to="{ name: RouteName.CREATE_GROUP }"
                class="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium underline"
                >{{ t("create a group") }}</router-link
              >
            </template>
            <template #explore_groups>
              <router-link
                :to="{
                  name: RouteName.SEARCH,
                  query: { contentType: ContentType.GROUPS },
                }"
                class="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium underline"
                >{{ t("explore the groups") }}</router-link
              >
            </template>
          </i18n-t>
        </p>
      </div>
    </section>
  </section>
</template>

<script lang="ts" setup>
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { LEAVE_GROUP } from "@/graphql/group";
import GroupMemberCard from "@/components/Group/GroupMemberCard.vue";
import InvitationsList from "@/components/Group/InvitationsList.vue";
import { usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole, ContentType } from "@/types/enums";
import RouteName from "../../router/name";
import { useRestrictions } from "@/composition/apollo/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { IUser } from "@/types/current-user.model";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { computed, inject } from "vue";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import { Notifier } from "@/plugins/notifier";

const page = useRouteQuery("page", 1, integerTransformer);
const limit = 10;

const { result: membershipsResult, loading } = useQuery<{
  loggedUser: Pick<IUser, "memberships">;
}>(LOGGED_USER_MEMBERSHIPS, () => ({
  page: page.value,
  limit,
}));

const membershipsPages = computed(
  () =>
    membershipsResult.value?.loggedUser?.memberships ?? {
      total: 0,
      elements: [],
    }
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: t("My groups"),
});

const notifier = inject<Notifier>("notifier");

const router = useRouter();

const acceptInvitation = (member: IMember) => {
  return router.push({
    name: RouteName.GROUP,
    params: { preferredUsername: usernameWithDomain(member.parent) },
  });
};

const rejectInvitation = ({ id: memberId }: { id: string }) => {
  const index = membershipsPages.value.elements.findIndex(
    (membership) =>
      membership.role === MemberRole.INVITED && membership.id === memberId
  );
  if (index > -1) {
    membershipsPages.value.elements.splice(index, 1);
    membershipsPages.value.total -= 1;
  }
};

const { mutate: leaveGroup, onError: onLeaveGroupError } = useMutation(
  LEAVE_GROUP,
  () => ({
    refetchQueries: [
      {
        query: LOGGED_USER_MEMBERSHIPS,
        variables: {
          page,
          limit,
        },
      },
    ],
  })
);

onLeaveGroupError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const invitations = computed((): IMember[] => {
  if (!membershipsPages.value) return [];
  return membershipsPages.value.elements.filter(
    (member: IMember) => member.role === MemberRole.INVITED
  );
});

const memberships = computed((): IMember[] => {
  if (!membershipsPages.value) return [];
  return membershipsPages.value.elements.filter(
    (member: IMember) =>
      ![MemberRole.INVITED, MemberRole.REJECTED].includes(member.role)
  );
});

const { restrictions } = useRestrictions();

const hideCreateGroupButton = computed((): boolean => {
  return restrictions.value?.onlyAdminCanCreateGroups === true;
});
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
/* Grid responsive layout handled via Tailwind classes */

/* Optional: Add transition for smoother layout changes */
.grid > * {
  transition: all 0.2s ease;
}

/* Optional: Custom pagination styling if needed */
:deep(.o-pag) {
  .o-pag__link {
    @apply px-3 py-1.5 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700;

    &.is-current {
      @apply bg-primary-600 text-white;
    }
  }
}
</style>
