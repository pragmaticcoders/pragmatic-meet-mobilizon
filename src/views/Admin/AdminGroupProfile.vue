<template>
  <div v-if="group" class="section">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        {
          name: RouteName.ADMIN_GROUPS,
          text: t('Groups'),
        },
        {
          name: RouteName.PROFILES,
          params: { id: group.id },
          text: displayName(group),
        },
      ]"
    />
    <div>
      <p v-if="group.suspended" class="mx-auto max-w-sm block mb-2">
        <actor-card
          :actor="group"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </p>
      <router-link
        class="mx-auto max-w-sm block mb-2"
        v-else
        :to="{
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
      >
        <actor-card
          :actor="group"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </router-link>
    </div>
    <table v-if="metadata.length > 0" class="table w-full">
      <tbody>
        <tr v-for="{ key, value, link } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="link">
            <router-link v-if="typeof link === 'object'" :to="link">
              {{ value }}
            </router-link>
            <a
              v-else
              :href="link"
              target="_blank"
              rel="noopener noreferrer"
              class="text-blue-600 hover:text-blue-800 underline"
            >
              {{ value }}
            </a>
          </td>
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="flex gap-2 flex-wrap">
      <!-- Approval/Rejection buttons -->
      <o-button
        @click="approveGroup"
        v-if="group.approvalStatus === 'PENDING_APPROVAL'"
        variant="success"
        >{{ t("Approve Group") }}</o-button
      >
      <o-button
        @click="rejectGroup"
        v-if="group.approvalStatus === 'PENDING_APPROVAL'"
        variant="danger"
        outlined
        >{{ t("Reject Group") }}</o-button
      >

      <!-- Suspend/Unsuspend buttons (soft suspend - preserves data) -->
      <o-button
        @click="confirmSuspendGroup"
        v-if="!group.suspended && !group.domain"
        variant="warning"
        >{{ t("Suspend group") }}</o-button
      >
      <o-button
        @click="confirmUnsuspendGroup"
        v-if="group.suspended"
        variant="success"
        >{{ t("Unsuspend group") }}</o-button
      >

      <!-- Delete button (permanent deletion) -->
      <o-button
        @click="confirmDeleteGroup"
        v-if="!group.domain"
        variant="danger"
        >{{ t("Delete group permanently") }}</o-button
      >

      <!-- Refresh button (remote groups) -->
      <o-button
        @click="
          refreshProfile({
            actorId: id,
          })
        "
        v-if="group.domain"
        variant="primary"
        outlined
        >{{ t("Refresh profile") }}</o-button
      >

      <!-- Suspend remote group (actually deletes local copy) -->
      <o-button
        @click="confirmSuspendRemoteGroup"
        v-if="group.domain && !group.suspended"
        variant="danger"
        >{{ t("Remove from instance") }}</o-button
      >
    </div>
    
    <!-- Status alerts -->
    <div v-if="group.suspended" class="mt-4 p-4 text-sm text-yellow-700 bg-yellow-100 rounded-lg" role="alert">
      {{ t("This group is suspended. Members cannot access the group, but all data is preserved.") }}
    </div>
    <section>
      <h2>
        {{
          t(
            "{number} members",
            {
              number: group.members.total,
            },
            group.members.total
          )
        }}
      </h2>
      <o-table
        :data="group.members.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="membersPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.members.total"
        :per-page="MEMBERS_PER_PAGE"
        @page-change="onMembersPageChange"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Member')"
          v-slot="props"
        >
          <article class="flex gap-1">
            <div class="flex-none">
              <router-link
                class="no-underline"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: props.row.actor.id },
                }"
              >
                <figure v-if="props.row.actor.avatar">
                  <img
                    class="rounded"
                    :src="props.row.actor.avatar.url"
                    alt=""
                    width="48"
                    height="48"
                  />
                </figure>
                <AccountCircle :size="48" v-else />
              </router-link>
            </div>
            <div>
              <div class="prose dark:prose-invert">
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-if="props.row.actor.name"
                  >{{ props.row.actor.name }}</router-link
                ><router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-else
                  >@{{ usernameWithDomain(props.row.actor) }}</router-link
                ><br />
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-if="props.row.actor.name"
                  >@{{ usernameWithDomain(props.row.actor) }}</router-link
                >
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column field="role" :label="t('Role')" v-slot="props">
          <tag
            variant="primary"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ t("Administrator") }}
          </tag>
          <tag
            variant="primary"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ t("Moderator") }}
          </tag>
          <tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ t("Member") }}
          </tag>
          <tag
            variant="warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ t("Not approved") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ t("Rejected") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ t("Invited") }}
          </tag>
        </o-table-column>
        <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ formatDateString(props.row.insertedAt) }}<br />{{
              formatTimeString(props.row.insertedAt)
            }}
          </span>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ t("No members found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section>
      <h2>
        {{
          t(
            "{number} organized events",
            {
              number: group.organizedEvents.total,
            },
            group.organizedEvents.total
          )
        }}
      </h2>
      <o-table
        :data="group.organizedEvents.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="organizedEventsPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.organizedEvents.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onOrganizedEventsPageChange"
      >
        <o-table-column field="title" :label="t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
            <tag variant="info" v-if="props.row.draft">{{ t("Draft") }}</tag>
          </router-link>
        </o-table-column>
        <o-table-column field="beginsOn" :label="t('Begins on')" v-slot="props">
          {{ formatDateTimeString(props.row.beginsOn) }}
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ t("No organized events found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section>
      <h2>
        {{
          t(
            "{number} posts",
            {
              number: group.posts.total,
            },
            group.posts.total
          )
        }}
      </h2>
      <o-table
        :data="group.posts.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="postsPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.posts.total"
        :per-page="POSTS_PER_PAGE"
        @page-change="onPostsPageChange"
      >
        <o-table-column field="title" :label="t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.POST, params: { slug: props.row.slug } }"
          >
            {{ props.row.title }}
            <tag variant="info" v-if="props.row.draft">{{ t("Draft") }}</tag>
          </router-link>
        </o-table-column>
        <o-table-column
          field="publishAt"
          :label="t('Publication date')"
          v-slot="props"
        >
          {{ formatDateTimeString(props.row.publishAt) }}
        </o-table-column>
        <template #empty>
          <empty-content icon="bullhorn" :inline="true">
            {{ t("No posts found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
  </div>
  <empty-content v-else-if="!loading" icon="account-multiple">
    {{ t("This group was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.ADMIN_GROUPS }"
        >{{ t("Back to group list") }}</o-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts" setup>
import {
  GET_GROUP,
  REFRESH_PROFILE,
  APPROVE_GROUP,
  REJECT_GROUP,
} from "@/graphql/group";
import { formatBytes } from "@/utils/datetime";
import { MemberRole } from "@/types/enums";
import { SUSPEND_PROFILE, UNSUSPEND_PROFILE, ADMIN_DELETE_GROUP } from "../../graphql/actor";
import { IGroup } from "../../types/actor";
import {
  usernameWithDomain,
  displayName,
  IActor,
} from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import ActorCard from "../../components/Account/ActorCard.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject } from "vue";
import { useRouter } from "vue-router";
import { useHead } from "@/utils/head";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useI18n } from "vue-i18n";
import {
  formatTimeString,
  formatDateString,
  formatDateTimeString,
} from "@/filters/datetime";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Tag from "@/components/TagElement.vue";

const EVENTS_PER_PAGE = 10;
const POSTS_PER_PAGE = 10;
const MEMBERS_PER_PAGE = 10;

const props = defineProps<{ id: string }>();

const organizedEventsPage = useRouteQuery(
  "organizedEventsPage",
  1,
  integerTransformer
);
const membersPage = useRouteQuery("membersPage", 1, integerTransformer);
const postsPage = useRouteQuery("postsPage", 1, integerTransformer);

const {
  result: groupResult,
  loading,
  fetchMore,
} = useQuery(
  GET_GROUP,
  () => ({
    id: props.id,
    organizedEventsPage: organizedEventsPage.value,
    organizedEventsLimit: EVENTS_PER_PAGE,
    postsPage: postsPage.value,
    postsLimit: POSTS_PER_PAGE,
    membersLimit: MEMBERS_PER_PAGE,
    membersPage: membersPage.value,
  }),
  () => ({
    enabled: props.id !== undefined,
  })
);

const group = computed(() => groupResult.value?.getGroup);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => displayName(group.value)),
});

const metadata = computed((): Array<Record<string, string>> => {
  if (!group.value) return [];

  // Determine status based on suspended and approval status
  let statusText = "";
  if (group.value.suspended) {
    statusText = t("Suspended") as string;
  } else if (group.value.approvalStatus === "PENDING_APPROVAL") {
    statusText = t("Pending Approval") as string;
  } else if (group.value.approvalStatus === "REJECTED") {
    statusText = t("Rejected") as string;
  } else {
    statusText = t("Active") as string;
  }

  const res: Record<string, string>[] = [
    {
      key: t("Status") as string,
      value: statusText,
    },
    {
      key: t("Domain") as string,
      value: (group.value.domain ? group.value.domain : t("Local")) as string,
    },
    {
      key: t("Uploaded media size") as string,
      value: formatBytes(group.value.mediaSize),
    },
  ];

  // Add marketing URL if it exists
  if (group.value.customUrl) {
    res.push({
      key: t("Marketing URL") as string,
      value: group.value.customUrl,
      link: group.value.customUrl,
    });
  }
  return res;
});

const router = useRouter();
const dialog = inject<Dialog>("dialog");
const notifier = inject<Notifier>("notifier");

// Soft suspend local group (preserves data)
const confirmSuspendGroup = (): void => {
  dialog?.confirm({
    title: t("Suspend group?"),
    message: t(
      "Do you want to suspend this group? Members will not be able to access the group, but all data will be preserved and can be restored later."
    ),
    confirmText: t("Suspend group"),
    cancelText: t("Cancel"),
    variant: "warning",
    hasIcon: true,
    onConfirm: async () => {
      await suspendProfile({ id: props.id });
      notifier?.success(t("Group suspended successfully"));
    },
  });
};

// Unsuspend group
const confirmUnsuspendGroup = (): void => {
  dialog?.confirm({
    title: t("Unsuspend group?"),
    message: t(
      "Do you want to unsuspend this group? Members will be able to access the group again."
    ),
    confirmText: t("Unsuspend group"),
    cancelText: t("Cancel"),
    variant: "success",
    hasIcon: true,
    onConfirm: async () => {
      await unsuspendProfile({ id: props.id });
      notifier?.success(t("Group unsuspended successfully"));
    },
  });
};

// Permanently delete local group
const confirmDeleteGroup = (): void => {
  dialog?.confirm({
    title: t("Delete group permanently?"),
    message: t(
      "Are you sure you want to <b>permanently delete</b> this group? All members will be notified and removed, and <b>all group data (events, posts, discussions, resources…) will be irretrievably destroyed</b>. This action cannot be undone!"
    ),
    confirmText: t("Delete permanently"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    onConfirm: async () => {
      await adminDeleteGroup({ id: props.id });
      notifier?.success(t("Group deleted permanently"));
      router.push({ name: RouteName.ADMIN_GROUPS });
    },
  });
};

// Suspend/remove remote group (deletes local copy)
const confirmSuspendRemoteGroup = (): void => {
  dialog?.confirm({
    title: t("Remove remote group from instance?"),
    message: t(
      "Are you sure you want to remove this remote group from your instance? As this group originates from instance {instance}, this will only remove local members and delete the local data, as well as rejecting all future data from this group.",
      { instance: group.value.domain }
    ),
    confirmText: t("Remove from instance"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    onConfirm: async () => {
      await suspendProfile({ id: props.id });
      notifier?.success(t("Remote group removed from instance"));
    },
  });
};

const { mutate: suspendProfile, onError: onSuspendProfileError } = useMutation<{
  suspendProfile: { id: string; suspended: boolean };
}>(SUSPEND_PROFILE, () => ({
  refetchQueries: [
    {
      query: GET_GROUP,
      variables: {
        id: props.id,
        organizedEventsPage: organizedEventsPage.value,
        organizedEventsLimit: EVENTS_PER_PAGE,
        postsPage: postsPage.value,
        postsLimit: POSTS_PER_PAGE,
        membersLimit: MEMBERS_PER_PAGE,
        membersPage: membersPage.value,
      },
    },
  ],
}));

onSuspendProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

// Admin delete group mutation
const { mutate: adminDeleteGroup, onError: onAdminDeleteGroupError } = useMutation<{
  adminDeleteGroup: { id: string };
}>(ADMIN_DELETE_GROUP);

onAdminDeleteGroupError((e) => {
  console.error(e);
  notifier?.error(t("Error while deleting group"));
});

const { mutate: unsuspendProfile, onError: onUnsuspendProfileError } =
  useMutation(UNSUSPEND_PROFILE, () => ({
    refetchQueries: [
      {
        query: GET_GROUP,
        variables: {
          id: props.id,
        },
      },
    ],
  }));

onUnsuspendProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

const {
  mutate: refreshProfile,
  onDone: onRefreshProfileDone,
  onError: onRefreshProfileError,
} = useMutation<{ refreshProfile: IActor }>(REFRESH_PROFILE);

onRefreshProfileDone(() => {
  notifier?.success(t("Triggered profile refreshment"));
});

onRefreshProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

// Approve group mutation
const { mutate: approveGroupMutation, onError: onApproveGroupError } =
  useMutation<{
    approveGroup: IGroup;
  }>(APPROVE_GROUP, () => ({
    refetchQueries: [
      {
        query: GET_GROUP,
        variables: {
          id: props.id,
        },
      },
    ],
  }));

onApproveGroupError((e) => {
  console.error(e);
  notifier?.error(t("Error while approving group"));
});

const approveGroup = () => {
  approveGroupMutation({ groupId: props.id });
  notifier?.success(t("Group approved successfully"));
};

// Reject group mutation
const { mutate: rejectGroupMutation, onError: onRejectGroupError } =
  useMutation<{
    rejectGroup: IGroup;
  }>(REJECT_GROUP, () => ({
    refetchQueries: [
      {
        query: GET_GROUP,
        variables: {
          id: props.id,
        },
      },
    ],
  }));

onRejectGroupError((e) => {
  console.error(e);
  notifier?.error(t("Error while rejecting group"));
});

const rejectGroup = () => {
  rejectGroupMutation({ groupId: props.id });
  notifier?.success(t("Group rejected"));
};

const onOrganizedEventsPageChange = async (page: number): Promise<void> => {
  organizedEventsPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      organizedEventsPage: organizedEventsPage.value,
      organizedEventsLimit: EVENTS_PER_PAGE,
    },
  });
};

const onMembersPageChange = async (page: number): Promise<void> => {
  membersPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      membersPage: membersPage.value,
      membersLimit: EVENTS_PER_PAGE,
    },
  });
};

const onPostsPageChange = async (page: number): Promise<void> => {
  postsPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      postsPage: postsPage.value,
      postsLimit: POSTS_PER_PAGE,
    },
  });
};
</script>
