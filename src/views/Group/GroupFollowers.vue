<template>
  <div>
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Settings'),
        },
        {
          name: RouteName.GROUP_FOLLOWERS_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Followers'),
        },
      ]"
    />
    <o-loading :active="loading" class="o-loading--enhanced o-loading--page" />
    <section class="p-2" v-if="group && isCurrentActorAGroupAdmin && followers">
      <div class="bg-white shadow-sm p-2">
        <div class="mb-6">
          <h2 class="text-2xl font-semibold text-gray-900">
            {{ t("Group Followers") }}
            <span class="text-gray-500 text-xl ml-2"
              >({{ followers.total }})</span
            >
          </h2>
        </div>
        <div class="mb-6 flex items-center gap-4">
          <label class="text-sm font-medium text-gray-700">{{
            t("Status")
          }}</label>
          <o-switch v-model="pending">{{ t("Pending") }}</o-switch>
        </div>
        <o-table
          :data="followers.elements"
          ref="queueTable"
          :loading="loading"
          paginated
          backend-pagination
          v-model:current-page="page"
          :pagination-simple="true"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
          :total="followers.total"
          :per-page="FOLLOWERS_PER_PAGE"
          backend-sorting
          :default-sort-direction="'desc'"
          :default-sort="['insertedAt', 'desc']"
          @page-change="loadMoreFollowers"
          @sort="(field: any, order: any) => $emit('sort', field, order)"
          class="w-full"
        >
          <o-table-column
            field="actor.preferredUsername"
            :label="t('Follower')"
            v-slot="props"
          >
            <article class="flex items-center gap-3">
              <figure v-if="props.row.actor.avatar">
                <img
                  class="rounded-full"
                  :src="props.row.actor.avatar.url"
                  alt=""
                  width="48"
                  height="48"
                />
              </figure>
              <AccountCircle v-else :size="48" />
              <div>
                <div
                  class="font-medium text-gray-900"
                  v-if="props.row.actor.name"
                >
                  {{ props.row.actor.name }}
                </div>
                <div class="text-sm text-gray-600">
                  @{{ usernameWithDomain(props.row.actor) }}
                </div>
              </div>
            </article>
          </o-table-column>
          <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
            <div class="text-center">
              <div class="text-gray-900">
                {{ formatDateString(props.row.insertedAt) }}
              </div>
              <div class="text-sm text-gray-600">
                {{ formatTimeString(props.row.insertedAt) }}
              </div>
            </div>
          </o-table-column>
          <o-table-column field="actions" :label="t('Actions')" v-slot="props">
            <div class="flex gap-2">
              <o-button
                v-if="!props.row.approved"
                @click="updateFollower(props.row, true)"
                icon-left="check"
                variant="success"
                class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg transition-colors"
                >{{ t("Accept") }}</o-button
              >
              <o-button
                @click="updateFollower(props.row, false)"
                icon-left="close"
                variant="danger"
                class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors"
                >{{ t("Reject") }}</o-button
              >
            </div>
          </o-table-column>
          <template #empty>
            <empty-content icon="account" inline>
              {{ t("No follower matches the filters") }}
            </empty-content>
          </template>
        </o-table>
      </div>
    </section>
    <o-notification v-else-if="!loading && group" class="max-w-4xl mx-auto p-6">
      {{ t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import { GROUP_FOLLOWERS, UPDATE_FOLLOWER } from "@/graphql/followers";
import RouteName from "../../router/name";
import { displayName, usernameWithDomain } from "../../types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { IFollower } from "@/types/actor/follower.model";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { computed, inject } from "vue";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { usePersonStatusGroup } from "@/composition/apollo/actor";
import { MemberRole } from "@/types/enums";
import { formatTimeString, formatDateString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { Notifier } from "@/plugins/notifier";

const props = defineProps<{ preferredUsername: string }>();

const preferredUsername = computed(() => props.preferredUsername);

const page = useRouteQuery("page", 1, integerTransformer);

const pending = useRouteQuery("pending", false, booleanTransformer);

const FOLLOWERS_PER_PAGE = 10;

const {
  result: followersResult,
  fetchMore,
  loading,
} = useQuery(GROUP_FOLLOWERS, () => ({
  name: props.preferredUsername,
  followersPage: page.value,
  followersLimit: FOLLOWERS_PER_PAGE,
  approved: !pending.value,
}));

const group = computed(() => followersResult.value?.group);

const followers = computed(
  () => group.value?.followers ?? { total: 0, elements: [] }
);

const { t } = useI18n({ useScope: "global" });

useHead({ title: computed(() => t("Group Followers")) });

const loadMoreFollowers = async (): Promise<void> => {
  console.debug("load more followers");
  await fetchMore({
    // New variables
    variables: {
      name: usernameWithDomain(group.value),
      followersPage: page.value,
      followersLimit: FOLLOWERS_PER_PAGE,
      approved: !pending.value,
    },
  });
};

const notifier = inject<Notifier>("notifier");

const { onDone, onError, mutate } = useMutation<{ updateFollower: IFollower }>(
  UPDATE_FOLLOWER,
  () => ({
    refetchQueries: [
      {
        query: GROUP_FOLLOWERS,
        variables: {
          name: usernameWithDomain(group.value),
          followersPage: page.value,
          followersLimit: FOLLOWERS_PER_PAGE,
          approved: !pending.value,
        },
      },
    ],
  })
);

onDone(({ data }) => {
  const follower = data?.updateFollower;
  const message =
    data?.updateFollower.approved === true
      ? t("{user}'s follow request was accepted", {
          user: displayName(follower?.actor),
        })
      : t("{user}'s follow request was rejected", {
          user: displayName(follower?.actor),
        });
  notifier?.success(message);
});

onError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const updateFollower = async (
  follower: IFollower,
  approved: boolean
): Promise<void> => {
  mutate({
    id: follower.id,
    approved,
  });
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(preferredUsername.value);
</script>
