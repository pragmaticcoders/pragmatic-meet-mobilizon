<template>
  <div v-if="user">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        {
          name: RouteName.USERS,
          text: t('Users'),
        },
        {
          name: RouteName.ADMIN_USER_PROFILE,
          params: { id: user.id },
          text: user.email,
        },
      ]"
    />

    <section>
      <h2 class="text-lg font-bold mb-3">{{ t("Details") }}</h2>
      <div class="flex flex-col">
        <div class="overflow-x-auto">
          <div class="inline-block py-2 min-w-full sm:px-2">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="metadata.length > 0" class="table w-full">
                <tbody>
                  <tr
                    class="border-b"
                    v-for="{ key, value, type } in metadata"
                    :key="key"
                  >
                    <td class="py-4 px-2 whitespace-nowrap align-middle">
                      {{ key }}
                    </td>

                    <td
                      v-if="type === 'ip'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <code class="truncate block max-w-[15rem]">{{
                        value
                      }}</code>
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <span
                        :class="{
                          'bg-red-100 text-red-800':
                            user.role == ICurrentUserRole.ADMINISTRATOR,
                          'bg-yellow-100 text-yellow-800':
                            user.role == ICurrentUserRole.MODERATOR,
                          'bg-blue-100 text-blue-800':
                            user.role == ICurrentUserRole.USER,
                        }"
                        class="text-sm font-medium mr-2 px-2.5 py-0.5 rounded"
                      >
                        {{ value }}
                      </span>
                    </td>
                    <td
                      v-else-if="type === 'status'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <span
                        :class="{
                          'bg-red-100 text-red-800': user.disabled,
                          'bg-yellow-100 text-yellow-800': user.suspended && !user.disabled,
                          'bg-green-100 text-green-800': !user.suspended && !user.disabled,
                        }"
                        class="text-sm font-medium mr-2 px-2.5 py-0.5 rounded"
                      >
                        {{ value }}
                      </span>
                    </td>
                    <td v-else class="py-4 px-2 align-middle">
                      {{ value }}
                    </td>
                    <td
                      v-if="type === 'email'"
                      class="py-4 px-2 whitespace-nowrap flex flex flex-col items-start gap-2"
                    >
                      <o-button
                        size="small"
                        v-if="!user.disabled"
                        @click="isEmailChangeModalActive = true"
                        variant="text"
                        icon-left="pencil"
                        >{{ t("Change email") }}</o-button
                      >
                      <o-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { emailFilter: `@${userEmailDomain}` },
                        }"
                        size="small"
                        variant="text"
                        icon-left="magnify"
                        >{{
                          t("Other users with the same email domain")
                        }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'confirmed'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        size="small"
                        v-if="!user.confirmedAt || user.disabled"
                        @click="isConfirmationModalActive = true"
                        variant="text"
                        icon-left="check"
                        >{{ t("Confirm user") }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        size="small"
                        v-if="!user.disabled"
                        @click="isRoleChangeModalActive = true"
                        variant="text"
                        icon-left="chevron-double-up"
                        >{{ t("Change role") }}</o-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'ip' && user.currentSignInIp"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <o-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { ipFilter: user.currentSignInIp },
                        }"
                        size="small"
                        variant="text"
                        icon-left="web"
                        >{{
                          t("Other users with the same IP address")
                        }}</o-button
                      >
                    </td>
                    <td v-else></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <!-- Profile Section - Single profile mode -->
    <section class="my-4" v-if="profile">
      <h2 class="text-lg font-bold mb-3">{{ t("Profile") }}</h2>
      <div class="flex justify-center mb-4">
        <actor-card
          :actor="profile"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </div>
      
      <!-- Profile Details Table -->
      <div class="flex flex-col mb-4">
        <div class="overflow-x-auto">
          <div class="inline-block py-2 min-w-full sm:px-2">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="profileMetadata.length > 0" class="table w-full">
                <tbody>
                  <tr
                    v-for="{ key, value, link } in profileMetadata"
                    :key="key"
                    class="odd:bg-white dark:odd:bg-zinc-800 even:bg-gray-50 dark:even:bg-zinc-700 border-b"
                  >
                    <td class="py-4 px-2 whitespace-nowrap">
                      {{ key }}
                    </td>
                    <td
                      v-if="link"
                      class="py-4 px-2 text-sm text-gray-500 dark:text-gray-200 whitespace-nowrap"
                    >
                      <router-link :to="link">
                        {{ value }}
                      </router-link>
                    </td>
                    <td
                      v-else
                      class="py-4 px-2 text-sm text-gray-500 dark:text-gray-200 whitespace-nowrap"
                    >
                      {{ value }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- Organized Events -->
      <div class="mt-4 mb-3">
        <h3 class="font-semibold mb-2">{{ t("Organized events") }}</h3>
        <o-table
          :data="profile.organizedEvents?.elements"
          :loading="loadingUser"
          paginated
          backend-pagination
          v-model:current-page="organizedEventsPage"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
          :total="profile.organizedEvents?.total"
          :per-page="EVENTS_PER_PAGE"
          @page-change="onOrganizedEventsPageChange"
        >
          <o-table-column
            field="beginsOn"
            :label="t('Begins on')"
            v-slot="props"
          >
            {{ formatDateTimeString(props.row.beginsOn) }}
          </o-table-column>
          <o-table-column field="title" :label="t('Title')" v-slot="props">
            <router-link
              :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
            >
              {{ props.row.title }}
            </router-link>
          </o-table-column>
          <template #empty>
            <empty-content icon="calendar" :inline="true">
              {{ t("No organized events listed") }}
            </empty-content>
          </template>
        </o-table>
      </div>

      <!-- Participations -->
      <div class="mt-4 mb-3">
        <h3 class="font-semibold mb-2">{{ t("Participations") }}</h3>
        <o-table
          :data="
            profile.participations?.elements.map(
              (participation: { event: unknown }) => participation.event
            )
          "
          :loading="loadingUser"
          paginated
          backend-pagination
          v-model:current-page="participationsPage"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
          :total="profile.participations?.total"
          :per-page="EVENTS_PER_PAGE"
          @page-change="onParticipationsPageChange"
        >
          <o-table-column
            field="beginsOn"
            :label="t('Begins on')"
            v-slot="props"
          >
            {{ formatDateTimeString(props.row.beginsOn) }}
          </o-table-column>
          <o-table-column field="title" :label="t('Title')" v-slot="props">
            <router-link
              :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
            >
              {{ props.row.title }}
            </router-link>
          </o-table-column>
          <template #empty>
            <empty-content icon="calendar" :inline="true">
              {{ t("No participations listed") }}
            </empty-content>
          </template>
        </o-table>
      </div>

      <!-- Memberships -->
      <div class="mt-4 mb-3">
        <h3 class="font-semibold mb-2">{{ t("Memberships") }}</h3>
        <o-table
          :data="profile.memberships?.elements"
          :loading="loadingUser"
          paginated
          backend-pagination
          v-model:current-page="membershipsPage"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
          :total="profile.memberships?.total"
          :per-page="EVENTS_PER_PAGE"
          @page-change="onMembershipsPageChange"
        >
          <o-table-column
            field="parent.preferredUsername"
            :label="t('Group')"
            v-slot="props"
          >
            <article class="flex gap-2">
              <router-link
                class="no-underline"
                :to="{
                  name: RouteName.ADMIN_GROUP_PROFILE,
                  params: { id: props.row.parent.id },
                }"
              >
                <figure class="" v-if="props.row.parent.avatar">
                  <img
                    class="rounded-full"
                    :src="props.row.parent.avatar.url"
                    alt=""
                    width="48"
                    height="48"
                  />
                </figure>
                <AccountCircle v-else :size="48" />
              </router-link>
              <div class="">
                <div class="prose dark:prose-invert">
                  <router-link
                    class="no-underline"
                    :to="{
                      name: RouteName.ADMIN_GROUP_PROFILE,
                      params: { id: props.row.parent.id },
                    }"
                    v-if="props.row.parent.name"
                    >{{ props.row.parent.name }}</router-link
                  ><br />
                  <router-link
                    class="no-underline"
                    :to="{
                      name: RouteName.ADMIN_GROUP_PROFILE,
                      params: { id: props.row.parent.id },
                    }"
                    >@{{ usernameWithDomain(props.row.parent) }}</router-link
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
              {{ t("No memberships found") }}
            </empty-content>
          </template>
        </o-table>
      </div>
    </section>
    <section class="my-4" v-else-if="!loadingUser">
      <h2 class="text-lg font-bold mb-3">{{ t("Profile") }}</h2>
      <empty-content :inline="true" icon="account">
        {{ t("This user doesn't have any profiles") }}
      </empty-content>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold mb-3">{{ t("Actions") }}</h2>
      <!-- User is disabled (deleted) -->
      <div
        v-if="user.disabled"
        class="p-4 mb-4 text-sm text-red-700 bg-red-100 rounded-lg"
        role="alert"
      >
        {{ t("This account has been deleted") }}
      </div>
      <!-- User is suspended -->
      <div v-else-if="user.suspended" class="space-y-4">
        <div
          class="p-4 mb-4 text-sm text-yellow-700 bg-yellow-100 rounded-lg"
          role="alert"
        >
          {{ t("This account is suspended. The user cannot log in.") }}
        </div>
        <div class="buttons flex gap-2">
          <o-button @click="unsuspendAccount" variant="success">{{
            t("Unsuspend account")
          }}</o-button>
          <o-button @click="deleteAccount" variant="danger">{{
            t("Delete account permanently")
          }}</o-button>
        </div>
      </div>
      <!-- User is active -->
      <div v-else class="buttons flex gap-2">
        <o-button @click="suspendAccount" variant="warning">{{
          t("Suspend account")
        }}</o-button>
        <o-button @click="deleteAccount" variant="danger">{{
          t("Delete account permanently")
        }}</o-button>
      </div>
    </section>
    <o-modal
      v-model:active="isEmailChangeModalActive"
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="updateUserEmail">
        <div class="" style="width: auto">
          <header class="">
            <h2>{{ t("Change user email") }}</h2>
          </header>
          <section class="">
            <o-field :label="t('Previous email')">
              <o-input type="email" v-model="user.email" disabled />
            </o-field>
            <o-field :label="t('New email')">
              <o-input
                type="email"
                v-model="newUser.email"
                :placeholder="t(`new{'@'}email.com`)"
                required
              >
              </o-input>
            </o-field>
            <o-checkbox v-model="newUser.notify">{{
              t("Notify the user of the change")
            }}</o-checkbox>
          </section>
          <footer class="mt-2 flex gap-2">
            <o-button outlined @click="isEmailChangeModalActive = false">{{
              t("Close")
            }}</o-button>
            <o-button native-type="submit" variant="primary">{{
              t("Change email")
            }}</o-button>
          </footer>
        </div>
      </form>
    </o-modal>
    <o-modal
      v-model:active="isRoleChangeModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="updateUserRole">
        <header>
          <h2>{{ t("Change user role") }}</h2>
        </header>
        <section>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.ADMINISTRATOR"
            >
              {{ t("Administrator") }}
            </o-radio>
          </o-field>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.MODERATOR"
            >
              {{ t("Moderator") }}
            </o-radio>
          </o-field>
          <o-field>
            <o-radio
              v-model="newUser.role"
              :native-value="ICurrentUserRole.USER"
            >
              {{ t("User") }}
            </o-radio>
          </o-field>
          <o-checkbox v-model="newUser.notify">{{
            t("Notify the user of the change")
          }}</o-checkbox>
        </section>
        <footer class="mt-2 flex gap-2">
          <o-button @click="isRoleChangeModalActive = false" outlined>{{
            t("Close")
          }}</o-button>
          <o-button native-type="submit" variant="primary">{{
            t("Change role")
          }}</o-button>
        </footer>
      </form>
    </o-modal>
    <o-modal
      v-model:active="isConfirmationModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="t('Edit user email')"
      :close-button-aria-label="t('Close')"
      aria-modal
    >
      <form @submit.prevent="confirmUser">
        <header>
          <h2>{{ t("Confirm user") }}</h2>
        </header>
        <section>
          <o-checkbox v-model="newUser.notify">{{
            t("Notify the user of the change")
          }}</o-checkbox>
        </section>
        <footer>
          <o-button @click="isConfirmationModalActive = false">{{
            t("Close")
          }}</o-button>
          <o-button native-type="submit" variant="primary">{{
            t("Confirm user")
          }}</o-button>
        </footer>
      </form>
    </o-modal>
  </div>
  <empty-content v-else-if="!loadingUser" icon="account">
    {{ t("This user was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.USERS }"
        >{{ t("Back to user list") }}</o-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts" setup>
import { formatBytes } from "@/utils/datetime";
import { ICurrentUserRole, MemberRole } from "@/types/enums";
import { GET_USER, SUSPEND_USER, UNSUSPEND_USER, DELETE_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import { ADMIN_UPDATE_USER, LANGUAGES_CODES } from "@/graphql/admin";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { ILanguage } from "@/types/admin.model";
import { computed, inject, reactive, ref, watch } from "vue";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import {
  formatDateString,
  formatTimeString,
  formatDateTimeString,
} from "@/filters/datetime";
import { useRouter } from "vue-router";
import { IPerson } from "@/types/actor";
import { usernameWithDomain } from "@/types/actor/actor.model";
import { Dialog } from "@/plugins/dialog";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Tag from "@/components/TagElement.vue";

const EVENTS_PER_PAGE = 10;

const props = defineProps<{ id: string }>();

const organizedEventsPage = useRouteQuery(
  "organizedEventsPage",
  1,
  integerTransformer
);
const participationsPage = useRouteQuery(
  "participationsPage",
  1,
  integerTransformer
);
const membershipsPage = useRouteQuery("membershipsPage", 1, integerTransformer);

const {
  result: userResult,
  loading: loadingUser,
  fetchMore,
} = useQuery<{ user: IUser }>(GET_USER, () => ({
  id: props.id,
  organizedEventsPage: organizedEventsPage.value,
  organizedEventsLimit: EVENTS_PER_PAGE,
  participationsPage: participationsPage.value,
  participationsLimit: EVENTS_PER_PAGE,
  membershipsPage: membershipsPage.value,
  membershipsLimit: EVENTS_PER_PAGE,
}));

const user = computed(() => userResult.value?.user);

const languageCode = computed(() => user.value?.locale);

const { result: languagesResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES_CODES,
  () => ({
    codes: languageCode.value,
  }),
  () => ({
    enabled: languageCode.value !== undefined,
  })
);

const languages = computed(() => languagesResult.value?.languages);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => user.value?.email ?? ""),
});

const isEmailChangeModalActive = ref(false);
const isRoleChangeModalActive = ref(false);
const isConfirmationModalActive = ref(false);

const newUser = reactive({
  email: "",
  role: user.value?.role,
  confirm: false,
  notify: true,
});

const metadata = computed(
  (): Array<{ key: string; value: string; type?: string }> => {
    if (!user.value) return [];
    return [
      {
        key: t("Email"),
        value: user.value.email,
        type: "email",
      },
      {
        key: t("Language"),
        value: languages.value ? languages.value[0].name : t("Unknown"),
      },
      {
        key: t("Role"),
        value: roleName(user.value.role),
        type: "role",
      },
      {
        key: t("Account status"),
        value: user.value.disabled
          ? t("Deleted")
          : user.value.suspended
            ? t("Suspended")
            : t("Active"),
        type: "status",
      },
      {
        key: t("Confirmed"),
        value: user.value.confirmedAt
          ? formatDateTimeString(user.value.confirmedAt)
          : t("Not confirmed"),
        type: "confirmed",
      },
      {
        key: t("Last sign-in"),
        value: user.value.currentSignInAt
          ? formatDateTimeString(user.value.currentSignInAt)
          : t("Unknown"),
      },
      {
        key: t("Last IP adress"),
        value: user.value.currentSignInIp || t("Unknown"),
        type: user.value.currentSignInIp ? "ip" : undefined,
      },
      {
        key: t("Total number of participations"),
        value: user.value.participations.total.toString(),
      },
      {
        key: t("Uploaded media total size"),
        value: formatBytes(user.value.mediaSize),
      },
      {
        key: t("Marketing consent"),
        value: user.value.marketingConsent
          ? user.value.marketingConsentUpdatedAt
            ? t("Yes") +
              " (" +
              formatDateTimeString(user.value.marketingConsentUpdatedAt) +
              ")"
            : t("Yes")
          : t("No"),
      },
    ];
  }
);

const roleName = (role: ICurrentUserRole): string => {
  switch (role) {
    case ICurrentUserRole.ADMINISTRATOR:
      return t("Administrator");
    case ICurrentUserRole.MODERATOR:
      return t("Moderator");
    case ICurrentUserRole.USER:
    default:
      return t("User");
  }
};

const router = useRouter();

const { mutate: suspendUserMutation, loading: suspendLoading } = useMutation<
  { suspendUser: { id: string; suspended: boolean } },
  { userId: string }
>(SUSPEND_USER);

const { mutate: unsuspendUserMutation, loading: unsuspendLoading } = useMutation<
  { unsuspendUser: { id: string; suspended: boolean } },
  { userId: string }
>(UNSUSPEND_USER);

const { mutate: deleteUserMutation, loading: deleteLoading } = useMutation<
  { deleteAccount: { id: string } },
  { userId: string; permanent: boolean }
>(DELETE_USER);

const dialog = inject<Dialog>("dialog");

const suspendAccount = async (): Promise<void> => {
  dialog?.confirm({
    title: t("Suspend the account?"),
    message: t(
      "Do you really want to suspend this account? The user will not be able to log in, but all their data will be preserved."
    ),
    confirmText: t("Suspend the account"),
    cancelText: t("Cancel"),
    variant: "warning",
    onConfirm: async () => {
      await suspendUserMutation({
        userId: props.id,
      });
      // Refresh user data to show updated status
      window.location.reload();
    },
  });
};

const unsuspendAccount = async (): Promise<void> => {
  dialog?.confirm({
    title: t("Unsuspend the account?"),
    message: t(
      "Do you really want to unsuspend this account? The user will be able to log in again."
    ),
    confirmText: t("Unsuspend the account"),
    cancelText: t("Cancel"),
    variant: "success",
    onConfirm: async () => {
      await unsuspendUserMutation({
        userId: props.id,
      });
      // Refresh user data to show updated status
      window.location.reload();
    },
  });
};

const deleteAccount = async (): Promise<void> => {
  dialog?.confirm({
    title: t("Delete the account permanently?"),
    message: t(
      "Do you really want to permanently delete this account? All of the user's profiles and data will be deleted. This action cannot be undone!"
    ),
    confirmText: t("Delete permanently"),
    cancelText: t("Cancel"),
    variant: "danger",
    onConfirm: async () => {
      await deleteUserMutation({
        userId: props.id,
        permanent: true,
      });
      return router.push({ name: RouteName.USERS });
    },
  });
};

// Get the user's default actor (single profile mode)
const profile = computed((): IPerson | undefined => {
  return user.value?.defaultActor as IPerson | undefined;
});

// Profile metadata for the profile details table
const profileMetadata = computed(
  (): Array<{
    key: string;
    value: string;
    link?: { name: string; params: Record<string, unknown> };
  }> => {
    if (!profile.value) return [];
    return [
      {
        key: t("Profile status"),
        value: profile.value.suspended ? t("Suspended") : t("Active"),
      },
      {
        key: t("Domain"),
        value: profile.value.domain ? profile.value.domain : t("Local"),
        link: profile.value.domain
          ? {
              name: RouteName.INSTANCE,
              params: { domain: profile.value.domain },
            }
          : undefined,
      },
      {
        key: t("Uploaded media size"),
        value: formatBytes(profile.value.mediaSize ?? 0),
      },
    ];
  }
);

// Pagination handlers for profile tables
const onOrganizedEventsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      id: props.id,
      organizedEventsPage: organizedEventsPage.value,
      organizedEventsLimit: EVENTS_PER_PAGE,
    },
  });
};

const onParticipationsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      id: props.id,
      participationsPage: participationsPage.value,
      participationsLimit: EVENTS_PER_PAGE,
    },
  });
};

const onMembershipsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      id: props.id,
      membershipsPage: membershipsPage.value,
      membershipsLimit: EVENTS_PER_PAGE,
    },
  });
};

const confirmUser = async () => {
  isConfirmationModalActive.value = false;
  await updateUser({
    id: props.id,
    confirmed: true,
    notify: newUser.notify,
  });
};

const updateUserRole = async () => {
  isRoleChangeModalActive.value = false;
  await updateUser({
    id: props.id,
    role: newUser.role,
    notify: newUser.notify,
  });
};

const updateUserEmail = async () => {
  isEmailChangeModalActive.value = false;
  await updateUser({
    id: props.id,
    email: newUser.email,
    notify: newUser.notify,
  });
};

const { mutate: updateUser } = useMutation<
  { adminUpdateUser: IUser },
  {
    id: string;
    email?: string;
    notify: boolean;
    confirmed?: boolean;
    role?: ICurrentUserRole;
  }
>(ADMIN_UPDATE_USER);

watch(user, (updatedUser: IUser | undefined, oldUser: IUser | undefined) => {
  if (updatedUser?.role !== oldUser?.role) {
    newUser.role = updatedUser?.role;
  }
});

const userEmailDomain = computed((): string | undefined => {
  if (user.value?.email) {
    return user.value?.email.split("@")[1];
  }
  return undefined;
});
</script>
