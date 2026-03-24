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
    <!-- Invite section - only for admins -->
    <section class="bg-white p-2 mt-4" v-if="group && canUseAdminMemberTools">
      <label class="block text-[17px] font-bold text-[#1c1b1f] mb-2">{{
        t("Invite a new member")
      }}</label>
      <form
        @submit.prevent="onInviteSubmit"
        class="flex flex-col gap-3 max-w-2xl"
      >
        <!-- Mode: invite existing member vs send email to person not on platform -->
        <div class="flex flex-wrap gap-2 mb-1">
          <label
            class="inline-flex items-center gap-2 cursor-pointer select-none"
          >
            <input
              v-model="inviteMode"
              type="radio"
              value="existing"
              class="w-4 h-4 border border-gray-300 text-blue-600"
            />
            <span class="text-sm font-medium text-gray-800">{{
              t("Existing user")
            }}</span>
          </label>
          <label
            class="inline-flex items-center gap-2 cursor-pointer select-none"
          >
            <input
              v-model="inviteMode"
              type="radio"
              value="email_new"
              class="w-4 h-4 border border-gray-300 text-blue-600"
            />
            <span class="text-sm font-medium text-gray-800">{{
              t("Not on platform yet")
            }}</span>
          </label>
        </div>

        <div class="flex flex-col md:flex-row gap-4 md:items-start">
          <!-- Mode: existing member — autocomplete or plain input when email-shaped -->
          <template v-if="inviteMode === 'existing'">
            <o-input
              v-if="inviteInputLooksLikeEmail"
              ref="inviteExistingEmailInputRef"
              v-model="inviteInput"
              type="text"
              :placeholder="
                isPendingGroupActionsLocked
                  ? t('Invites disabled during approval')
                  : t('Username or email address')
              "
              :disabled="isPendingGroupActionsLocked"
              class="flex-1 min-w-0"
            />
            <o-autocomplete
              v-else
              ref="inviteExistingAutocompleteRef"
              v-model="inviteInput"
              :data="inviteActorSuggestionsWithDisplayName"
              field="displayName"
              :loading="inviteSearchLoading"
              :placeholder="
                isPendingGroupActionsLocked
                  ? t('Invites disabled during approval')
                  : t('Username or email address')
              "
              :disabled="isPendingGroupActionsLocked"
              class="flex-1 min-w-0"
              @select="onSelectInviteActor"
            >
              <template #default="props">
                <ActorInline :actor="props.option" />
              </template>
              <template #empty>
                <div
                  v-if="inviteSearchLoading"
                  class="p-3 text-center text-gray-500"
                >
                  {{ t("Searching...") }}
                </div>
                <div
                  v-else-if="
                    inviteInput.trim().length >= 2 &&
                    inviteActorSuggestions.length === 0
                  "
                  class="p-3 text-center text-gray-500"
                >
                  {{ t("No users or groups found") }}
                </div>
              </template>
            </o-autocomplete>
          </template>
          <!-- Mode: email invitation (no account) — email input only -->
          <template v-else>
            <o-input
              v-model="inviteInput"
              type="email"
              :placeholder="
                isPendingGroupActionsLocked
                  ? t('Invites disabled during approval')
                  : t('Email address')
              "
              :disabled="isPendingGroupActionsLocked"
              class="flex-1 min-w-0"
            />
          </template>

          <o-button
            type="submit"
            variant="primary"
            :disabled="
              isPendingGroupActionsLocked ||
              !inviteInput.trim() ||
              sendingInvite ||
              (inviteMode === 'email_new' && !confirmNonExistingUser)
            "
            :class="[
              'px-8 py-[18px] font-bold whitespace-nowrap flex-shrink-0',
              isPendingGroupActionsLocked
                ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                : 'bg-[#155eef] text-white hover:bg-blue-600',
            ]"
            :title="
              isPendingGroupActionsLocked
                ? t('This group is pending approval from administrators')
                : ''
            "
          >
            {{ sendingInvite ? t("Sending...") : t("Invite member") }}
          </o-button>
        </div>

        <!-- Checkbox only for "email (person not on platform)" mode -->
        <div
          v-if="inviteMode === 'email_new'"
          class="flex items-start space-x-2"
        >
          <input
            id="confirm_non_existing"
            v-model="confirmNonExistingUser"
            type="checkbox"
            class="w-4 h-4 mt-0.5 border border-gray-300 text-blue-600"
          />
          <label for="confirm_non_existing" class="text-sm text-gray-700">
            {{
              t("I confirm that I am eligible to invite this person by email")
            }}
          </label>
        </div>

        <o-notification
          v-if="inviteError"
          variant="danger"
          :closable="true"
          @close="inviteError = ''"
        >
          {{ inviteError }}
        </o-notification>
      </form>
      <o-notification
        v-if="isPendingGroupActionsLocked"
        variant="warning"
        :closable="false"
        class="mb-4 mt-4"
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
      </o-notification>

      <hr class="border-t border-gray-200 my-6" />
    </section>

    <!-- Members list section - visible for all group members -->
    <section
      class="bg-white p-2 mt-4"
      v-if="group && isCurrentActorAGroupMember"
    >
      <h1 class="text-xl font-bold text-[#1c1b1f] mb-4">
        {{ t("Group Members") }} ({{ group.members.total }})
      </h1>
      <!-- Filter by status section - only for admins -->
      <div class="my-6" v-if="canUseAdminMemberTools">
        <label class="block text-[17px] font-bold text-[#1c1b1f] mb-2">{{
          t("Filter by status")
        }}</label>
        <div class="flex items-start">
          <o-select
            v-model="roles"
            id="group-members-status-filter"
            class="w-48 border border-[#cac9cb] bg-white p-[18px]"
          >
            <option value="EVERYTHING">
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
            <figure v-if="props.row.actor?.avatar" class="h-8 w-8">
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
                <template v-if="props.row.actor">
                  <span
                    v-if="props.row.actor.name"
                    class="font-bold text-[17px] text-[#1c1b1f]"
                    >{{ props.row.actor.name }}</span
                  ><br />
                  <span class="">
                    @{{ usernameWithDomain(props.row.actor) }}
                  </span>
                </template>
                <template v-else-if="props.row.invitedEmail">
                  <span class="font-bold text-[17px] text-[#1c1b1f]">{{
                    props.row.invitedEmail
                  }}</span>
                </template>
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
          v-if="canUseAdminMemberTools"
          header-class="bg-[#f5f5f6] px-[18px] py-3 text-[15px] font-bold text-[#1c1b1f] border border-[#cac9cb]"
          cell-class="px-[18px] py-[18px] border border-[#cac9cb]"
        >
          <div
            class="flex flex-wrap gap-2"
            v-if="props.row.actor?.id !== currentActor?.id"
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
    <o-notification
      v-else-if="!groupMembersLoading && group && !isCurrentActorAGroupMember"
    >
      {{ t("You must be a member of this group to view its members.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useRestrictions } from "@/composition/apollo/config";
import { formatDateString, formatTimeString } from "@/filters/datetime";
import {
  APPROVE_MEMBER,
  GROUP_MEMBERS,
  INVITE_GROUP_MEMBER_BY_EMAIL,
  INVITE_MEMBER,
  REMOVE_MEMBER,
  UPDATE_MEMBER,
} from "@/graphql/member";
import { SEARCH_PERSON_AND_GROUPS } from "@/graphql/search";
import { Notifier } from "@/plugins/notifier";
import RouteName from "@/router/name";
import {
  displayName,
  IGroup,
  IActor,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import { Paginate } from "@/types/paginate";
import { IMember } from "@/types/actor/member.model";
import { ApprovalStatus, MemberRole } from "@/types/enums";
import { useHead } from "@/utils/head";
import { useLazyQuery, useMutation, useQuery } from "@vue/apollo-composable";
import { debounce } from "lodash";
import { computed, inject, nextTick, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import ActorInline from "@/components/Account/ActorInline.vue";
import {
  enumTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group members")),
});

const props = defineProps<{ preferredUsername: string }>();
const preferredUsername = computed(() => props.preferredUsername);

const emit = defineEmits(["sort"]);

const { currentActor } = useCurrentActorClient();
const { restrictions } = useRestrictions();

const inviteMode = ref<"existing" | "email_new">("existing");
const inviteExistingEmailInputRef = ref<{ $el?: HTMLElement } | null>(null);
const inviteExistingAutocompleteRef = ref<{ $el?: HTMLElement } | null>(null);
const inviteInput = ref("");
const inviteError = ref("");
const confirmNonExistingUser = ref(false);
const sendingInvite = ref(false);
const lastInvitedLabel = ref("");
const selectedInviteActor = ref<IActor | null>(null);
const inviteActorSuggestions = ref<IActor[]>([]);
const inviteSearchLoading = ref(false);

/** Map invite-by-email API error message to a clear, translated message. */
function inviteByEmailErrorMessage(apiMessage: string | undefined): string {
  if (!apiMessage) return t("Failed to send invitation.");
  const msg = apiMessage.toLowerCase();
  if (msg.includes("already been invited"))
    return t("This email has already been invited to the group.");
  if (msg.includes("already a member"))
    return t("This person is already a member of the group.");
  return apiMessage;
}

const inviteInputLooksLikeEmail = computed(() =>
  /^\S+@\S+\.\S+$/.test(inviteInput.value.trim())
);

const inviteActorSuggestionsWithDisplayName = computed(() =>
  inviteActorSuggestions.value.map((actor) => ({
    ...actor,
    displayName: displayName(actor),
  }))
);

const {
  load: loadInviteSearch,
  onResult: onInviteSearchResult,
  onError: onInviteSearchError,
} = useLazyQuery<
  { searchPersons: Paginate<IPerson>; searchGroups: Paginate<IGroup> },
  { searchText: string }
>(SEARCH_PERSON_AND_GROUPS);

onInviteSearchResult((result) => {
  inviteSearchLoading.value = false;
  if (result.data) {
    const persons = result.data.searchPersons?.elements ?? [];
    const groups = result.data.searchGroups?.elements ?? [];
    const actors: IActor[] = [...persons, ...groups].filter(
      (actor) => !currentActor.value || actor.id !== currentActor.value.id
    );
    inviteActorSuggestions.value = actors;
  } else {
    inviteActorSuggestions.value = [];
  }
});

onInviteSearchError(() => {
  inviteSearchLoading.value = false;
  inviteActorSuggestions.value = [];
});

const performInviteSearch = (text: string) => {
  const trimmed = text.trim();
  if (!trimmed || inviteInputLooksLikeEmail.value) {
    inviteActorSuggestions.value = [];
    inviteSearchLoading.value = false;
    return;
  }
  if (trimmed.length < 2) {
    inviteActorSuggestions.value = [];
    return;
  }
  inviteSearchLoading.value = true;
  loadInviteSearch(SEARCH_PERSON_AND_GROUPS, { searchText: trimmed });
};

const debouncedInviteSearch = debounce(performInviteSearch, 300);

watch(inviteInput, (newVal) => {
  if (
    selectedInviteActor.value &&
    newVal !== displayName(selectedInviteActor.value)
  ) {
    selectedInviteActor.value = null;
  }
  if (inviteMode.value === "existing" && !inviteInputLooksLikeEmail.value) {
    debouncedInviteSearch(newVal);
  } else {
    inviteActorSuggestions.value = [];
  }
});

watch(inviteMode, () => {
  inviteError.value = "";
  inviteActorSuggestions.value = [];
  selectedInviteActor.value = null;
});

// When we swap between o-input and o-autocomplete (email-shaped vs not), restore focus so typing/backspace isn't interrupted
watch(inviteInputLooksLikeEmail, (isEmail) => {
  if (inviteMode.value !== "existing") return;
  nextTick(() => {
    const targetRef = isEmail
      ? inviteExistingEmailInputRef
      : inviteExistingAutocompleteRef;
    const el = targetRef.value?.$el ?? targetRef.value;
    const input =
      el instanceof HTMLInputElement
        ? el
        : (el as HTMLElement)?.querySelector?.("input");
    (input as HTMLInputElement)?.focus();
  });
});

function onSelectInviteActor(option: IActor & { displayName: string }) {
  selectedInviteActor.value = option;
  inviteInput.value = displayName(option);
}
const page = useRouteQuery("page", 1, integerTransformer);
const MemberAllRoles = { ...MemberRole, EVERYTHING: "EVERYTHING" };
const roles = useRouteQuery(
  "roles",
  "EVERYTHING",
  enumTransformer(MemberAllRoles)
);
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
    roles: roles.value === "EVERYTHING" ? undefined : roles.value,
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

const members = computed(() => {
  const allMembers = group.value?.members ?? { total: 0, elements: [] };

  // For non-admin members, filter out INVITED, NOT_APPROVED, and REJECTED members
  if (!canUseAdminMemberTools.value && allMembers.elements) {
    const filteredElements = allMembers.elements.filter(
      (member: IMember) =>
        ![
          MemberRole.INVITED,
          MemberRole.NOT_APPROVED,
          MemberRole.REJECTED,
        ].includes(member.role)
    );
    return {
      ...allMembers,
      elements: filteredElements,
      total: filteredElements.length,
    };
  }

  return allMembers;
});

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
          roles: roles.value === "EVERYTHING" ? undefined : roles.value,
        };

        // Only update current filter if it includes INVITED role or no filter
        if (
          roles.value === "EVERYTHING" ||
          roles.value === MemberRole.INVITED
        ) {
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
  sendingInvite.value = false;
});

onInviteMemberDone(() => {
  const label = lastInvitedLabel.value || inviteInput.value;
  if (roles.value !== "EVERYTHING" && roles.value !== MemberRole.INVITED) {
    roles.value = MemberRole.INVITED;
    notifier?.success(
      t("{username} was invited to {group}. Showing invited members.", {
        username: label,
        group: displayName(group.value),
      })
    );
  } else {
    notifier?.success(
      t("{username} was invited to {group}", {
        username: label,
        group: displayName(group.value),
      })
    );
  }
  inviteInput.value = "";
  lastInvitedLabel.value = "";
  selectedInviteActor.value = null;
  inviteActorSuggestions.value = [];
  refreshMembersData();
  sendingInvite.value = false;
});

const { mutate: inviteByEmailMutation } = useMutation<{
  inviteGroupMemberByEmail: { success: boolean };
}>(INVITE_GROUP_MEMBER_BY_EMAIL);

const onInviteSubmit = async (): Promise<void> => {
  inviteError.value = "";
  const value = inviteInput.value?.trim() || "";
  if (!value || !group.value?.id) return;
  if (isPendingGroupActionsLocked.value) {
    inviteError.value = t(
      "Cannot invite members while group is awaiting approval"
    );
    return;
  }

  sendingInvite.value = true;
  lastInvitedLabel.value = value;

  // Mode: send invitation by email to person not on platform (checkbox was required)
  if (inviteMode.value === "email_new") {
    try {
      await inviteByEmailMutation({
        groupId: group.value.id,
        email: value,
        confirmNonExistingUser: true,
      });
      notifier?.success(t("Invitation sent by email."));
      inviteInput.value = "";
      lastInvitedLabel.value = "";
      selectedInviteActor.value = null;
      confirmNonExistingUser.value = false;
      refreshMembersData();
    } catch (err: any) {
      inviteError.value = inviteByEmailErrorMessage(
        err?.graphQLErrors?.[0]?.message
      );
    } finally {
      sendingInvite.value = false;
    }
    return;
  }

  // Mode: invite existing member — by email or by username
  if (inviteInputLooksLikeEmail.value) {
    try {
      await inviteByEmailMutation({
        groupId: group.value.id,
        email: value,
        confirmNonExistingUser: false,
      });
      notifier?.success(t("Invitation sent."));
      inviteInput.value = "";
      lastInvitedLabel.value = "";
      selectedInviteActor.value = null;
      refreshMembersData();
    } catch (err: any) {
      const apiMessage = err?.graphQLErrors?.[0]?.message;
      inviteError.value = inviteByEmailErrorMessage(apiMessage);
      // Hint if they might have meant "person not on platform"
      if (
        typeof apiMessage === "string" &&
        (apiMessage.includes("No account") ||
          apiMessage.includes("not yet on the platform"))
      ) {
        inviteError.value = `${inviteError.value} ${t("Use «Send invitation by email» above to invite someone without an account.")}`;
      }
    } finally {
      sendingInvite.value = false;
    }
    return;
  }

  const usernameToInvite =
    selectedInviteActor.value?.preferredUsername ?? value;
  try {
    await inviteMemberMutation({
      groupId: group.value.id,
      targetActorUsername: usernameToInvite,
    });
  } catch (_) {
    sendingInvite.value = false;
  }
};

const loadMoreMembers = async (): Promise<void> => {
  await fetchMoreGroupMembers({
    // New variables
    variables() {
      return {
        name: usernameWithDomain(group.value),
        page: page.value,
        limit: MEMBERS_PER_PAGE,
        roles: roles.value === "EVERYTHING" ? undefined : roles.value,
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
          roles: roles.value === "EVERYTHING" ? undefined : roles.value,
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
          roles: roles.value === "EVERYTHING" ? undefined : roles.value,
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

const isCurrentActorAGroupMember = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
    MemberRole.MEMBER,
  ]);
});

const { person } = usePersonStatusGroup(preferredUsername.value);

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const rolesToConsider = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    rolesToConsider.includes(personMemberships.value?.elements[0].role)
  );
};

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const isCurrentActorAGroupOwner = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.CREATOR);
});

const allowModeratorActivityForPendingGroups = computed(
  () => restrictions.value?.allowModeratorActivityForPendingGroups ?? false
);

const canUseAdminMemberTools = computed((): boolean => {
  if (isCurrentActorAGroupAdmin.value) return true;

  return (
    allowModeratorActivityForPendingGroups.value &&
    isGroupPendingApproval.value &&
    (isCurrentActorAGroupModerator.value || isCurrentActorAGroupOwner.value)
  );
});

const isPendingGroupActionsLocked = computed((): boolean => {
  return (
    isGroupPendingApproval.value &&
    !(
      allowModeratorActivityForPendingGroups.value &&
      (isCurrentActorAGroupModerator.value || isCurrentActorAGroupOwner.value)
    )
  );
});
</script>
