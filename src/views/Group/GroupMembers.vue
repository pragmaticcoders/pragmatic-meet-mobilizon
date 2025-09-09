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
          name: RouteName.GROUP_MEMBERS_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Members'),
        },
      ]"
    />
    <o-loading
      :active="groupMembersLoading"
      class="o-loading--enhanced o-loading--page"
    />
    <section
      class="bg-white p-2 mt-4"
      v-if="group && isCurrentActorAGroupAdmin"
    >
      <label class="block text-[17px] font-bold text-[#1c1b1f] mb-2">{{
        t("Invite a new member")
      }}</label>
      <div class="flex flex-col md:flex-row gap-4 my-4 items-start">
        <form @submit.prevent="inviteMember" class="flex-1 min-w-0">
          <ActorAutoComplete
            v-model="selectedActors"
            :placeholder="
              isGroupPendingApproval
                ? t('Invites disabled during approval')
                : t('Search for a user to invite')
            "
            :disabled="isGroupPendingApproval"
          />
        </form>
        <div class="flex-shrink-0">
          <o-button
            variant="primary"
            native-type="submit"
            :disabled="isGroupPendingApproval"
            :class="[
              'px-8 py-[18px] font-bold whitespace-nowrap',
              isGroupPendingApproval
                ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                : 'bg-[#155eef] text-white hover:bg-blue-600',
            ]"
            :title="
              isGroupPendingApproval
                ? t('This group is pending approval from administrators')
                : ''
            "
            @click="inviteMember"
            >{{ t("Invite member") }}</o-button
          >
        </div>
      </div>
      <div v-if="isGroupPendingApproval" class="mb-4">
        <p
          class="text-sm text-amber-600 bg-amber-50 p-3 rounded-lg border border-amber-200"
        >
          <span class="font-medium">{{
            t("Member invitations are disabled")
          }}</span>
          -
          {{
            t(
              "You can invite members once your group is approved by administrators"
            )
          }}
        </p>
      </div>
      <!-- Gray separator line -->
      <hr class="border-t border-gray-200 my-6" />
      <h1 class="text-xl font-bold text-[#1c1b1f] mb-4">
        {{ t("Group Members") }} ({{ group.members.total }})
      </h1>
      <!-- Filter by status section -->
      <div class="my-6">
        <label class="block text-[17px] font-bold text-[#1c1b1f] mb-2">{{
          t("Filter by status")
        }}</label>
        <div class="flex items-start">
          <o-select
            v-model="roles"
            id="group-members-status-filter"
            class="w-48 border border-[#cac9cb] bg-white p-[18px]"
          >
            <option :value="undefined">
              {{ t("Everything") }}
            </option>
            <option :value="MemberRole.ADMINISTRATOR">
              {{ t("Administrator") }}
            </option>
            <option :value="MemberRole.MODERATOR">
              {{ t("Moderator") }}
            </option>
            <option :value="MemberRole.MEMBER">
              {{ t("Member") }}
            </option>
            <option :value="MemberRole.INVITED">
              {{ t("Invited") }}
            </option>
            <option :value="MemberRole.NOT_APPROVED">
              {{ t("Not approved") }}
            </option>
            <option :value="MemberRole.REJECTED">
              {{ t("Rejected") }}
            </option>
          </o-select>
        </div>
      </div>
      <o-table
        v-if="members"
        :data="members.elements"
        ref="queueTable"
        :loading="groupMembersLoading"
        paginated
        backend-pagination
        v-model:current-page="page"
        :pagination-simple="true"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="members.total"
        :per-page="MEMBERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="loadMoreMembers"
        @sort="(field: string, order: string) => emit('sort', field, order)"
        class="border border-[#cac9cb]"
        :key="`members-${tableRefreshKey}-${members.total}-${members.elements.length}`"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Member')"
          v-slot="props"
          header-class="bg-[#f5f5f6] px-[18px] py-3 text-[15px] font-bold text-[#1c1b1f] border border-[#cac9cb]"
          cell-class="px-[18px] py-[18px] border border-[#cac9cb]"
        >
          <article class="flex">
            <figure v-if="props.row.actor.avatar" class="h-8 w-8">
              <img
                class="rounded-full object-cover h-full w-full"
                :src="props.row.actor.avatar.url"
                :alt="props.row.actor.avatar.alt || ''"
                height="48"
                width="48"
              />
            </figure>
            <AccountCircle v-else :size="32" />

            <div class="ml-2">
              <div class="text-start">
                <span
                  v-if="props.row.actor.name"
                  class="font-bold text-[17px] text-[#1c1b1f]"
                  >{{ props.row.actor.name }}</span
                ><br />
                <span class="">@{{ usernameWithDomain(props.row.actor) }}</span>
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column
          field="role"
          :label="t('Role')"
          v-slot="props"
          header-class="bg-[#f5f5f6] px-[18px] py-3 text-[15px] font-bold text-[#1c1b1f] border border-[#cac9cb]"
          cell-class="px-[18px] py-[18px] border border-[#cac9cb]"
        >
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#155eef] text-white"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ t("Administrator") }}
          </span>
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#e8effd] text-[#155eef]"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ t("Moderator") }}
          </span>
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#d4ffeb] text-[#007e44]"
            v-else-if="props.row.role === MemberRole.MEMBER"
          >
            {{ t("Member") }}
          </span>
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#fff2e6] text-[#b05500]"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ t("Not approved") }}
          </span>
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#ffe5e5] text-[#cc0000]"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ t("Rejected") }}
          </span>
          <span
            class="inline-block px-2 py-1 text-[15px] font-medium bg-[#dfdfe0] text-[#37363a]"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ t("Invited") }}
          </span>
        </o-table-column>
        <o-table-column
          field="insertedAt"
          :label="t('Date')"
          v-slot="props"
          header-class="bg-[#f5f5f6] px-[18px] py-3 text-[15px] font-bold text-[#1c1b1f] border border-[#cac9cb]"
          cell-class="px-[18px] py-[18px] border border-[#cac9cb]"
        >
          <span class="text-[15px] text-[#1c1b1f]">
            {{ formatDateString(props.row.insertedAt) }},
            {{ formatTimeString(props.row.insertedAt) }}
          </span>
        </o-table-column>
        <o-table-column
          field="actions"
          :label="t('Actions')"
          v-slot="props"
          header-class="bg-[#f5f5f6] px-[18px] py-3 text-[15px] font-bold text-[#1c1b1f] border border-[#cac9cb]"
          cell-class="px-[18px] py-[18px] border border-[#cac9cb]"
        >
          <div
            class="flex flex-wrap gap-2"
            v-if="props.row.actor.id !== currentActor?.id"
          >
            <o-button
              v-if="props.row.role === MemberRole.NOT_APPROVED"
              @click="approveMember(props.row)"
              icon-left="check"
              class="bg-[#007e44] text-white px-4 py-2 font-medium hover:bg-green-700"
              :loading="isApproveLoading(props.row.id)"
              :disabled="isApproveLoading(props.row.id)"
              >{{ t("Approve member") }}</o-button
            >
            <o-button
              v-if="props.row.role === MemberRole.NOT_APPROVED"
              @click="rejectMember(props.row)"
              icon-left="exit-to-app"
              class="bg-[#cc0000] text-white px-4 py-2 font-medium hover:bg-red-700"
              :loading="isRemoveLoading(props.row.id)"
              :disabled="isRemoveLoading(props.row.id)"
              >{{ t("Reject member") }}</o-button
            >
            <o-button
              v-if="
                [MemberRole.MEMBER, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="promoteMember(props.row)"
              icon-left="chevron-double-up"
              class="border border-[#155eef] text-[#155eef] px-4 py-2 font-medium bg-white hover:bg-[#e8effd]"
              :loading="isRemoveLoading(props.row.id)"
              :disabled="isRemoveLoading(props.row.id)"
              >{{ t("Promote") }}</o-button
            >
            <o-button
              v-if="
                [MemberRole.ADMINISTRATOR, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="demoteMember(props.row)"
              icon-left="chevron-double-down"
              class="border border-[#b05500] text-[#b05500] px-4 py-2 font-medium bg-white hover:bg-[#fff2e6]"
              >{{ t("Demote") }}</o-button
            >
            <o-button
              v-if="props.row.role === MemberRole.MEMBER"
              @click="removeMember(props.row)"
              icon-left="exit-to-app"
              class="bg-[#cc0000] text-white px-4 py-2 font-medium hover:bg-red-700"
              >{{ t("Remove") }}</o-button
            >
          </div>
        </o-table-column>
        <template #empty>
          <empty-content icon="account" inline>
            {{ t("No member matches the filters") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <o-notification v-else-if="!groupMembersLoading && group">
      {{ t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import { MemberRole, ApprovalStatus } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "@/router/name";
import {
  INVITE_MEMBER,
  GROUP_MEMBERS,
  REMOVE_MEMBER,
  UPDATE_MEMBER,
  APPROVE_MEMBER,
} from "@/graphql/member";
import { usernameWithDomain, displayName, IGroup, IActor } from "@/types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject, ref, nextTick } from "vue";
import {
  enumTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { formatTimeString, formatDateString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { Notifier } from "@/plugins/notifier";
import ActorAutoComplete from "@/components/Account/ActorAutoComplete.vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group members")),
});

const props = defineProps<{ preferredUsername: string }>();
const preferredUsername = computed(() => props.preferredUsername);

const emit = defineEmits(["sort"]);

const { currentActor } = useCurrentActorClient();

const selectedActors = ref<IActor[]>([]);
const inviteError = ref("");
const page = useRouteQuery("page", 1, integerTransformer);
const roles = useRouteQuery("roles", undefined, enumTransformer(MemberRole));
const MEMBERS_PER_PAGE = 10;
const notifier = inject<Notifier>("notifier");

// Per-member loading states
const approveLoadingMembers = ref<Set<string>>(new Set());
const removeLoadingMembers = ref<Set<string>>(new Set());

// Helper functions for loading states
const setApproveLoading = (memberId: string, loading: boolean) => {
  if (loading) {
    approveLoadingMembers.value.add(memberId);
  } else {
    approveLoadingMembers.value.delete(memberId);
  }
};

const isApproveLoading = (memberId: string) => {
  return approveLoadingMembers.value.has(memberId);
};

const setRemoveLoading = (memberId: string, loading: boolean) => {
  if (loading) {
    removeLoadingMembers.value.add(memberId);
  } else {
    removeLoadingMembers.value.delete(memberId);
  }
};

const isRemoveLoading = (memberId: string) => {
  return removeLoadingMembers.value.has(memberId);
};

// Reactive key to force table re-render after cache updates
const tableRefreshKey = ref(0);
const forceTableRefresh = async () => {
  tableRefreshKey.value++;
  await nextTick();
};

// Fallback refresh function - use only when cache updates fail
const refreshMembersData = async () => {
  try {
    await refetchGroupMembers();
    forceTableRefresh();
  } catch (error) {
    console.error("Error refreshing members data:", error);
    // Fallback to force refresh only
    forceTableRefresh();
  }
};

const {
  result: groupMembersResult,
  fetchMore: fetchMoreGroupMembers,
  loading: groupMembersLoading,
  refetch: refetchGroupMembers,
} = useQuery<{ group: IGroup }>(
  GROUP_MEMBERS,
  () => ({
    groupName: props.preferredUsername,
    page: page.value,
    limit: MEMBERS_PER_PAGE,
    roles: roles.value,
  }),
  () => ({
    enabled: props.preferredUsername !== undefined,
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: false,
  })
);
const group = computed(() => groupMembersResult.value?.group);

const isGroupPendingApproval = computed((): boolean => {
  return group.value?.approvalStatus === ApprovalStatus.PENDING_APPROVAL;
});

const members = computed(
  () => group.value?.members ?? { total: 0, elements: [] }
);

const {
  mutate: inviteMemberMutation,
  onDone: onInviteMemberDone,
  onError: onInviteMemberError,
} = useMutation<{ inviteMember: IMember }>(INVITE_MEMBER, () => ({
  update: (cache, { data }) => {
    if (data?.inviteMember) {
      const invitedMember = data.inviteMember;

      // Update cache for current filter (if it matches the invited member's role)
      try {
        const currentVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: roles.value,
        };

        // Only update current filter if it includes INVITED role or no filter
        if (!roles.value || roles.value === MemberRole.INVITED) {
          const existingData = cache.readQuery<{ group: IGroup }>({
            query: GROUP_MEMBERS,
            variables: currentVariables,
          });

          if (existingData?.group?.members?.elements) {
            // Add the invited member to the beginning of the list
            const updatedElements = [
              invitedMember,
              ...existingData.group.members.elements,
            ];

            cache.writeQuery({
              query: GROUP_MEMBERS,
              variables: currentVariables,
              data: {
                ...existingData,
                group: {
                  ...existingData.group,
                  members: {
                    ...existingData.group.members,
                    elements: updatedElements,
                    total: existingData.group.members.total + 1,
                  },
                },
              },
            });
          }
        }
      } catch (error) {
        // Current filter cache update not needed or failed
      }

      // Always update cache for "INVITED" filter
      try {
        const invitedVariables = {
          groupName: props.preferredUsername,
          page: 1, // Always add to first page
          limit: MEMBERS_PER_PAGE,
          roles: MemberRole.INVITED, // Specifically for invited members
        };

        const invitedData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: invitedVariables,
        });

        if (invitedData?.group?.members?.elements) {
          const updatedInvitedElements = [
            invitedMember,
            ...invitedData.group.members.elements,
          ];

          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: invitedVariables,
            data: {
              ...invitedData,
              group: {
                ...invitedData.group,
                members: {
                  ...invitedData.group.members,
                  elements: updatedInvitedElements,
                  total: invitedData.group.members.total + 1,
                },
              },
            },
          });
        }
      } catch (error) {
        // INVITED filter cache update not needed
      }

      // Update cache for "all members" (no filter)
      try {
        const allMembersVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: undefined,
        };

        const allMembersData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: allMembersVariables,
        });

        if (allMembersData?.group?.members?.elements) {
          const updatedAllElements = [
            invitedMember,
            ...allMembersData.group.members.elements,
          ];

          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: allMembersVariables,
            data: {
              ...allMembersData,
              group: {
                ...allMembersData.group,
                members: {
                  ...allMembersData.group.members,
                  elements: updatedAllElements,
                  total: allMembersData.group.members.total + 1,
                },
              },
            },
          });
        }
      } catch (error) {
        // All members cache update not needed
      }
    }
  },
  // Remove refetchQueries to avoid conflicts
}));

onInviteMemberError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    inviteError.value = error.graphQLErrors[0].message;
  }
});

onInviteMemberDone(() => {
  if (selectedActors.value.length === 1) {
    const invitedActor = selectedActors.value[0];

    // If user is not viewing "INVITED" or "Everything" filter, auto-switch to INVITED
    if (roles.value && roles.value !== MemberRole.INVITED) {
      // Auto-switch to INVITED filter to show the invited member
      roles.value = MemberRole.INVITED;

      notifier?.success(
        t("{username} was invited to {group}. Showing invited members.", {
          username: invitedActor?.name || invitedActor?.preferredUsername || "",
          group: displayName(group.value),
        })
      );
    } else {
      notifier?.success(
        t("{username} was invited to {group}", {
          username: invitedActor?.name || invitedActor?.preferredUsername || "",
          group: displayName(group.value),
        })
      );
    }
  } else if (selectedActors.value.length > 1) {
    // If user is not viewing "INVITED" or "Everything" filter, auto-switch to INVITED
    if (roles.value && roles.value !== MemberRole.INVITED) {
      // Auto-switch to INVITED filter to show the invited members
      roles.value = MemberRole.INVITED;

      notifier?.success(
        t("{count} users were invited to {group}. Showing invited members.", {
          count: selectedActors.value.length,
          group: displayName(group.value),
        })
      );
    } else {
      notifier?.success(
        t("{count} users were invited to {group}", {
          count: selectedActors.value.length,
          group: displayName(group.value),
        })
      );
    }
  }
  selectedActors.value = [];
  refreshMembersData();
});

const inviteMember = async (): Promise<void> => {
  inviteError.value = "";

  // Prevent invites if group is pending approval
  if (isGroupPendingApproval.value) {
    inviteError.value = t(
      "Cannot invite members while group is awaiting approval"
    );
    return;
  }

  if (!selectedActors.value.length) {
    inviteError.value = t("Please select a user to invite");
    return;
  }

  // Process all selected actors, not just the first one
  for (const actorToInvite of selectedActors.value) {
    try {
      await inviteMemberMutation({
        groupId: group.value?.id,
        targetActorUsername: actorToInvite.preferredUsername,
      });
    } catch (error) {
      console.error(
        `Failed to invite ${actorToInvite.preferredUsername}:`,
        error
      );
      // Continue with other invitations even if one fails
    }
  }
};

const loadMoreMembers = async (): Promise<void> => {
  await fetchMoreGroupMembers({
    // New variables
    variables() {
      return {
        name: usernameWithDomain(group.value),
        page,
        limit: MEMBERS_PER_PAGE,
        roles,
      };
    },
  });
};

const {
  mutate: mutateRemoveMember,
  onDone: onRemoveMemberDone,
  onError: onRemoveMemberError,
} = useMutation(REMOVE_MEMBER, () => ({
  errorPolicy: "all", // Allow cache updates even if there are GraphQL errors
  update: (cache, { data }, { context }) => {
    if (data?.removeMember && context?.oldMember) {
      // Try to update cache for current query with filters
      try {
        const currentVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: roles.value,
        };

        const existingData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: currentVariables,
        });

        if (existingData?.group?.members?.elements) {
          // Filter out the removed member
          const updatedElements = existingData.group.members.elements.filter(
            (member) => member.id !== context.oldMember.id
          );

          // Write back to cache
          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: currentVariables,
            data: {
              ...existingData,
              group: {
                ...existingData.group,
                members: {
                  ...existingData.group.members,
                  elements: updatedElements,
                  total: Math.max(0, existingData.group.members.total - 1),
                },
              },
            },
          });
        }
      } catch (error) {
        console.warn("Failed to update cache:", error);
      }

      // Also try to update cache for "all members" query (no role filter)
      try {
        const allMembersVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: undefined, // No role filter
        };

        const allMembersData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: allMembersVariables,
        });

        if (allMembersData?.group?.members?.elements) {
          const updatedAllElements =
            allMembersData.group.members.elements.filter(
              (member) => member.id !== context.oldMember.id
            );

          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: allMembersVariables,
            data: {
              ...allMembersData,
              group: {
                ...allMembersData.group,
                members: {
                  ...allMembersData.group.members,
                  elements: updatedAllElements,
                  total: Math.max(0, allMembersData.group.members.total - 1),
                },
              },
            },
          });
        }
      } catch (error) {
        // No cache entry for all members query (this is ok)
      }
    }
  },
}));

onRemoveMemberDone((result: any) => {
  const context = result.context;

  // Clear loading state
  if (context?.oldMember?.id) {
    setRemoveLoading(context.oldMember.id, false);
  }

  let message = t("The member was removed from the group {group}", {
    group: displayName(group.value),
  }) as string;
  if (context?.oldMember.role === MemberRole.NOT_APPROVED) {
    message = t("The membership request from {profile} was rejected", {
      group: displayName(context?.oldMember.actor),
    }) as string;
  }
  notifier?.success(message);
  refreshMembersData();
});

onRemoveMemberError((error) => {
  console.error("Member removal error:", error);

  // Clear loading state for all members on error (fallback)
  removeLoadingMembers.value.clear();

  // Since we no longer use refetchQueries, this should be a genuine error
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  } else {
    notifier?.error(t("An error occurred while removing the member"));
  }
});

const removeMember = (oldMember: IMember) => {
  if (!oldMember.id || isRemoveLoading(oldMember.id)) return;

  setRemoveLoading(oldMember.id, true);
  mutateRemoveMember(
    {
      memberId: oldMember.id,
      exclude: false, // false = just remove, true = exclude/ban
    },
    {
      context: { oldMember },
    }
  );
};

const promoteMember = (member: IMember): void => {
  if (!member.id) return;
  if (member.role === MemberRole.MODERATOR) {
    updateMember(member, MemberRole.ADMINISTRATOR);
  }
  if (member.role === MemberRole.MEMBER) {
    updateMember(member, MemberRole.MODERATOR);
  }
};

const demoteMember = (member: IMember): void => {
  if (!member.id) return;
  if (member.role === MemberRole.MODERATOR) {
    updateMember(member, MemberRole.MEMBER);
  }
  if (member.role === MemberRole.ADMINISTRATOR) {
    updateMember(member, MemberRole.MODERATOR);
  }
};

const {
  mutate: approveMemberMutation,
  onDone: onApproveMemberDone,
  onError: onApproveMemberError,
} = useMutation<{ approveMember: IMember }, { memberId: string }>(
  APPROVE_MEMBER,
  {
    update: (cache, { data }) => {
      if (data?.approveMember) {
        const approvedMember = data.approveMember; // Now has role: MEMBER
        try {
          const notApprovedVariables = {
            groupName: props.preferredUsername,
            page: page.value,
            limit: MEMBERS_PER_PAGE,
            roles: MemberRole.NOT_APPROVED,
          };

          const notApprovedData = cache.readQuery<{ group: IGroup }>({
            query: GROUP_MEMBERS,
            variables: notApprovedVariables,
          });

          if (notApprovedData?.group?.members?.elements) {
            // Member removed from NOT_APPROVED filter
          }
        } catch (error) {
          // NOT_APPROVED filter cache update not needed
        }

        // Add to "MEMBER" filter cache (if exists)
        try {
          const memberVariables = {
            groupName: props.preferredUsername,
            page: 1, // Add to first page
            limit: MEMBERS_PER_PAGE,
            roles: MemberRole.MEMBER,
          };

          const memberData = cache.readQuery<{ group: IGroup }>({
            query: GROUP_MEMBERS,
            variables: memberVariables,
          });

          if (memberData?.group?.members?.elements) {
            const updatedMemberElements = [
              approvedMember,
              ...memberData.group.members.elements,
            ];

            cache.writeQuery({
              query: GROUP_MEMBERS,
              variables: memberVariables,
              data: {
                ...memberData,
                group: {
                  ...memberData.group,
                  members: {
                    ...memberData.group.members,
                    elements: updatedMemberElements,
                    total: memberData.group.members.total + 1,
                  },
                },
              },
            });
          }
        } catch (error) {
          // MEMBER filter cache update not needed
        }
      }
    },
    // Removed refetchQueries to avoid conflicts with cache update
  }
);

onApproveMemberDone((result: any) => {
  const context = result.context;
  if (context?.oldMember?.id) {
    setApproveLoading(context.oldMember.id, false);
  }
  notifier?.success(t("The member was approved"));
  refreshMembersData();
});

onApproveMemberError((error) => {
  console.error("approveMember error:", error);
  // Clear loading state for all members on error (fallback)
  approveLoadingMembers.value.clear();

  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
  // Fallback refresh on error
  refreshMembersData();
});

// Wrapper function for approve member with loading state management
const approveMember = (member: IMember) => {
  if (!member.id || isApproveLoading(member.id)) return;

  setApproveLoading(member.id, true);
  approveMemberMutation(
    { memberId: member.id },
    { context: { oldMember: member } }
  );
};

const rejectMember = (member: IMember): void => {
  if (!member.id) return;
  removeMember(member);
};

const {
  mutate: updateMemberMutation,
  onDone: onUpdateMutationDone,
  onError: onUpdateMutationError,
} = useMutation<
  { id: string; role: MemberRole },
  { memberId: string; role: MemberRole; oldRole: MemberRole }
>(UPDATE_MEMBER, () => ({
  errorPolicy: "all",
  update: (cache, { data }, { context }) => {
    if (data && context?.oldMember) {
      // For role changes, we need to update all relevant caches
      const memberId = context.oldMember.id;
      const newRole = data.role;

      // Update current filter cache
      try {
        const currentVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: roles.value,
        };

        const currentData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: currentVariables,
        });

        if (currentData?.group?.members?.elements) {
          const updatedElements = currentData.group.members.elements.map(
            (member) =>
              member.id === memberId ? { ...member, role: newRole } : member
          );

          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: currentVariables,
            data: {
              ...currentData,
              group: {
                ...currentData.group,
                members: {
                  ...currentData.group.members,
                  elements: updatedElements,
                },
              },
            },
          });
        }
      } catch (error) {
        // Current filter cache update failed
      }

      // Update "all members" cache (no filter)
      try {
        const allMembersVariables = {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: undefined,
        };

        const allMembersData = cache.readQuery<{ group: IGroup }>({
          query: GROUP_MEMBERS,
          variables: allMembersVariables,
        });

        if (allMembersData?.group?.members?.elements) {
          const updatedAllElements = allMembersData.group.members.elements.map(
            (member) =>
              member.id === memberId ? { ...member, role: newRole } : member
          );

          cache.writeQuery({
            query: GROUP_MEMBERS,
            variables: allMembersVariables,
            data: {
              ...allMembersData,
              group: {
                ...allMembersData.group,
                members: {
                  ...allMembersData.group.members,
                  elements: updatedAllElements,
                },
              },
            },
          });
        }
      } catch (error) {
        // All members cache update failed
      }
    }
  },
  // Removed refetchQueries to avoid conflicts
}));

onUpdateMutationDone((result: any) => {
  const { data } = result;
  const context = result.context;
  let successMessage;
  switch (data?.role) {
    case MemberRole.MODERATOR:
      successMessage = "The member role was updated to moderator";
      break;
    case MemberRole.ADMINISTRATOR:
      successMessage = "The member role was updated to administrator";
      break;
    case MemberRole.MEMBER:
      if (context?.oldMember.role === MemberRole.NOT_APPROVED) {
        successMessage = "The member was approved";
      } else {
        successMessage = "The member role was updated to simple member";
      }
      break;
    default:
      successMessage = "The member role was updated";
  }
  notifier?.success(t(successMessage));
});

onUpdateMutationError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const updateMember = async (
  oldMember: IMember,
  role: MemberRole
): Promise<void> => {
  updateMemberMutation(
    {
      memberId: oldMember.id as string,
      role,
      oldRole: oldMember.role,
    },
    { context: { oldMember } }
  );
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const rolesToConsider = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    rolesToConsider.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(preferredUsername.value);
</script>
