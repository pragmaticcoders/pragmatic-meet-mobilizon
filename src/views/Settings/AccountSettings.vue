<template>
  <div v-if="loggedUser" class="max-w-4xl mx-auto">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.ACCOUNT_SETTINGS,
          text: t('Account'),
        },
        {
          name: RouteName.ACCOUNT_SETTINGS_GENERAL,
          text: t('General'),
        },
      ]"
    />
    
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div class="p-6 border-b border-gray-200">
        <h1 class="text-2xl font-bold text-gray-900">{{ t("Account Settings") }}</h1>
        <p class="text-gray-600 mt-1">{{ t("Manage your account information and security settings") }}</p>
      </div>

      <!-- Email Section -->
      <div class="p-6 border-b border-gray-200">
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">{{ t("Email Address") }}</h3>
            <p class="text-gray-600 mb-4">
              {{ t("Your current email is") }} <span class="font-medium text-gray-900">{{ loggedUser.email }}</span>
            </p>
            
            <o-notification
              v-if="!canChangeEmail && loggedUser.provider"
              variant="warning"
              :closable="false"
              class="mb-4"
            >
              {{
                t(
                  "Your email address was automatically set based on your {provider} account.",
                  {
                    provider: providerName(loggedUser.provider),
                  }
                )
              }}
            </o-notification>
          </div>
          <div v-if="canChangeEmail">
            <button
              @click="openChangeEmailModal"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              {{ t("Change Email") }}
            </button>
          </div>
        </div>
      </div>

      <!-- Password Section -->
      <div class="p-6 border-b border-gray-200">
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">{{ t("Password") }}</h3>
            <p class="text-gray-600 mb-4">{{ t("Update your password to keep your account secure") }}</p>
            
            <o-notification
              v-if="!canChangePassword && loggedUser.provider"
              variant="warning"
              :closable="false"
              class="mb-4"
            >
              {{
                t(
                  "You can't change your password because you are registered through {provider}.",
                  {
                    provider: providerName(loggedUser.provider),
                  }
                )
              }}
            </o-notification>
          </div>
          <div v-if="canChangePassword">
            <button
              @click="openChangePasswordModal"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              {{ t("Change Password") }}
            </button>
          </div>
        </div>
      </div>

      <!-- Delete Account Section -->
      <div class="p-6">
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-red-600 mb-2">{{ t("Delete Account") }}</h3>
            <p class="text-gray-600 mb-4">
              {{ t("Permanently delete your account and all associated data. This action cannot be undone.") }}
            </p>
          </div>
          <div>
            <button
              @click="openDeleteAccountModal"
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
            >
              {{ t("Delete Account") }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Change Email Modal -->
    <o-modal
      v-model:active="isChangeEmailModalActive"
      :close-button-aria-label="t('Close')"
      has-modal-card
      :can-cancel="['escape', 'outside']"
    >
      <div class="bg-white rounded-lg max-w-md mx-auto">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">{{ t("Change Email Address") }}</h2>
        </div>
        
        <form @submit.prevent="resetEmailAction" ref="emailForm" class="p-6">
          <o-notification
            variant="danger"
            has-icon
            aria-close-label="Close notification"
            role="alert"
            :key="error"
            v-for="error in changeEmailErrors"
            class="mb-4"
          >
            {{ error }}
          </o-notification>

          <div class="mb-4">
            <label for="modal-email" class="block text-sm font-medium text-gray-700 mb-2">
              {{ t('New Email Address') }}
            </label>
            <input
              type="email"
              id="modal-email"
              v-model="newEmail"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="t('Enter new email address')"
            />
            <p class="text-sm text-gray-500 mt-1">{{ t("You'll receive a confirmation email.") }}</p>
          </div>

          <div class="mb-6">
            <label for="modal-email-password" class="block text-sm font-medium text-gray-700 mb-2">
              {{ t('Current Password') }}
            </label>
            <input
              type="password"
              id="modal-email-password"
              v-model="passwordForEmailChange"
              required
              minlength="6"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="t('Enter your current password')"
            />
          </div>

          <div class="flex gap-3">
            <button
              type="button"
              @click="isChangeEmailModalActive = false"
              class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              {{ t("Cancel") }}
            </button>
            <button
              type="submit"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              {{ t("Update Email") }}
            </button>
          </div>
        </form>
      </div>
    </o-modal>

    <!-- Change Password Modal -->
    <o-modal
      v-model:active="isChangePasswordModalActive"
      :close-button-aria-label="t('Close')"
      has-modal-card
      :can-cancel="['escape', 'outside']"
    >
      <div class="bg-white rounded-lg max-w-md mx-auto">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900">{{ t("Change Password") }}</h2>
        </div>
        
        <form @submit.prevent="resetPasswordAction" ref="passwordForm" class="p-6">
          <o-notification
            variant="danger"
            has-icon
            aria-close-label="Close notification"
            role="alert"
            :key="error"
            v-for="error in changePasswordErrors"
            class="mb-4"
          >
            {{ error }}
          </o-notification>

          <div class="mb-4">
            <label for="modal-old-password" class="block text-sm font-medium text-gray-700 mb-2">
              {{ t('Current Password') }}
            </label>
            <input
              type="password"
              id="modal-old-password"
              v-model="oldPassword"
              required
              minlength="6"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="t('Enter your current password')"
            />
          </div>

          <div class="mb-6">
            <label for="modal-new-password" class="block text-sm font-medium text-gray-700 mb-2">
              {{ t('New Password') }}
            </label>
            <input
              type="password"
              id="modal-new-password"
              v-model="newPassword"
              required
              minlength="6"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="t('Enter new password')"
            />
            <p class="text-sm text-gray-500 mt-1">{{ t("Password must be at least 6 characters long.") }}</p>
          </div>

          <div class="flex gap-3">
            <button
              type="button"
              @click="isChangePasswordModalActive = false"
              class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              {{ t("Cancel") }}
            </button>
            <button
              type="submit"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              {{ t("Update Password") }}
            </button>
          </div>
        </form>
      </div>
    </o-modal>

    <!-- Delete Account Modal -->
    <o-modal
      v-model:active="isDeleteAccountModalActive"
      :close-button-aria-label="t('Close')"
      has-modal-card
      :can-cancel="false"
    >
      <div class="bg-white rounded-lg max-w-md mx-auto">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-red-600">{{ t("Delete Account") }}</h2>
        </div>
        
        <div class="p-6">
          <div class="mb-6">
            <p class="text-gray-600 mb-4">
              {{
                t(
                  "Are you really sure you want to delete your whole account? You'll lose everything. Identities, settings, events created, messages and participations will be gone forever."
                )
              }}
            </p>
            <p class="text-red-600 font-medium">
              {{ t("There will be no way to recover your data.") }}
            </p>
          </div>

          <form @submit.prevent="deleteAccount">
            <div v-if="deletePasswordErrors.length > 0" class="mb-4">
              <div
                v-for="message in deletePasswordErrors"
                :key="message"
                class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-2"
              >
                {{ message }}
              </div>
            </div>

            <div v-if="hasUserGotAPassword" class="mb-6">
              <label for="delete-password" class="block text-sm font-medium text-gray-700 mb-2">
                {{ t("Please enter your password to confirm this action.") }}
              </label>
              <input
                type="password"
                id="delete-password"
                v-model="passwordForAccountDeletion"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                :placeholder="t('Enter your password')"
              />
            </div>

            <div class="flex gap-3">
              <button
                type="button"
                @click="isDeleteAccountModalActive = false"
                class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
              >
                {{ t("Cancel") }}
              </button>
              <button
                type="submit"
                class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
              >
                {{ t("Delete Everything") }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </o-modal>
  </div>
</template>

<script lang="ts" setup>
import { useLoggedUser } from "@/composition/apollo/user";
import { Notifier } from "@/plugins/notifier";
import { IAuthProvider } from "@/types/enums";
import { useMutation } from "@vue/apollo-composable";
import { useHead } from "@/utils/head";
import { GraphQLError } from "graphql/error/GraphQLError";
import { computed, inject, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import {
  CHANGE_EMAIL,
  CHANGE_PASSWORD,
  DELETE_ACCOUNT,
} from "../../graphql/user";
import RouteName from "../../router/name";
import { logout, SELECTED_PROVIDERS } from "../../utils/auth";
import { useOruga } from "@oruga-ui/oruga-next";

const { t } = useI18n({ useScope: "global" });

const { loggedUser } = useLoggedUser();

useHead({
  title: computed(() => t("General settings")),
});

const passwordForm = ref<HTMLFormElement>();
const emailForm = ref<HTMLFormElement>();

const passwordForEmailChange = ref("");
const newEmail = ref("");
const changeEmailErrors = ref<string[]>([]);
const oldPassword = ref("");
const newPassword = ref("");
const changePasswordErrors = ref<string[]>([]);
const deletePasswordErrors = ref<string[]>([]);
const isDeleteAccountModalActive = ref(false);
const isChangeEmailModalActive = ref(false);
const isChangePasswordModalActive = ref(false);
const passwordForAccountDeletion = ref("");

const notifier = inject<Notifier>("notifier");

const {
  mutate: changeEmailMutation,
  onDone: changeEmailMutationDone,
  onError: changeEmailMutationError,
} = useMutation(CHANGE_EMAIL);

changeEmailMutationDone(() => {
  notifier?.info(
    t(
      "The account's email address was changed. Check your emails to verify it."
    )
  );
  newEmail.value = "";
  passwordForEmailChange.value = "";
  isChangeEmailModalActive.value = false;
});

changeEmailMutationError((err) => {
  handleErrors("email", err);
});

const resetEmailAction = async (): Promise<void> => {
  if (emailForm.value?.reportValidity()) {
    changeEmailErrors.value = [];

    changeEmailMutation({
      email: newEmail.value,
      password: passwordForEmailChange.value,
    });
  }
};

const {
  mutate: changePasswordMutation,
  onDone: onChangePasswordMutationDone,
  onError: onChangePasswordMutationError,
} = useMutation(CHANGE_PASSWORD);

onChangePasswordMutationDone(() => {
  oldPassword.value = "";
  newPassword.value = "";
  notifier?.success(t("The password was successfully changed"));
  isChangePasswordModalActive.value = false;
});

onChangePasswordMutationError((err) => {
  handleErrors("password", err);
});

const resetPasswordAction = async (): Promise<void> => {
  if (passwordForm.value?.reportValidity()) {
    changePasswordErrors.value = [];

    changePasswordMutation({
      oldPassword: oldPassword.value,
      newPassword: newPassword.value,
    });
  }
};

const openDeleteAccountModal = (): void => {
  passwordForAccountDeletion.value = "";
  isDeleteAccountModalActive.value = true;
};

const openChangeEmailModal = (): void => {
  changeEmailErrors.value = [];
  newEmail.value = "";
  passwordForEmailChange.value = "";
  isChangeEmailModalActive.value = true;
};

const openChangePasswordModal = (): void => {
  changePasswordErrors.value = [];
  oldPassword.value = "";
  newPassword.value = "";
  isChangePasswordModalActive.value = true;
};

const router = useRouter();

const {
  mutate: deleteAccountMutation,
  onDone: deleteAccountMutationDone,
  onError: deleteAccountMutationError,
} = useMutation<{ deleteAccount: { id: string } }, { password?: string }>(
  DELETE_ACCOUNT
);

const { notification } = useOruga();

deleteAccountMutationDone(async () => {
  console.debug("Deleted account, logging out client...");
  await logout(false);
  notification.open({
    message: t("Your account has been successfully deleted"),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });

  return router.push({ name: RouteName.HOME });
});

deleteAccountMutationError((err) => {
  deletePasswordErrors.value = err.graphQLErrors.map(
    ({ message }: GraphQLError) => message
  );
});

const deleteAccount = () => {
  deletePasswordErrors.value = [];
  console.debug("Asking to delete account...");
  deleteAccountMutation({
    password: hasUserGotAPassword.value
      ? passwordForAccountDeletion.value
      : undefined,
  });
};

const canChangePassword = computed((): boolean => {
  return !loggedUser.value?.provider;
});

const canChangeEmail = computed((): boolean => {
  return !loggedUser.value?.provider;
});

const providerName = (id: string): string => {
  if (SELECTED_PROVIDERS[id]) {
    return SELECTED_PROVIDERS[id];
  }
  return id;
};

const hasUserGotAPassword = computed((): boolean => {
  return (
    loggedUser.value?.provider == null ||
    loggedUser.value?.provider === IAuthProvider.LDAP
  );
});

const deleteAccountPasswordFieldType = computed((): string | null => {
  return deletePasswordErrors.value.length > 0 ? "is-danger" : null;
});

const handleErrors = (type: string, err: any) => {
  console.error(err);

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(({ message }: { message: string }) => {
      switch (type) {
        case "password":
          changePasswordErrors.value.push(message);
          break;
        case "email":
        default:
          changeEmailErrors.value.push(message);
          break;
      }
    });
  }
};
</script>
