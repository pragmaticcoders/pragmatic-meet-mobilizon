<template>
  <!-- Full screen layout with centered content -->
  <div
    class="flex items-center justify-center px-4"
    v-if="!currentUser?.isLoggedIn"
  >
    <div class="w-full max-w-md">
      <!-- Brand and heading section -->
      <div class="text-center mb-8">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">
          {{ t("Welcome back!") }}
        </h1>
      </div>

      <!-- Error notifications -->
      <div class="mb-6 space-y-3" v-if="hasErrors">
        <div
          v-if="errorCode === LoginErrorCode.NEED_TO_LOGIN"
          class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 text-sm"
        >
          {{ t("You need to login.") }}
        </div>
        <div
          v-else-if="errorCode === LoginError.LOGIN_PROVIDER_ERROR"
          class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 text-sm"
        >
          {{
            t(
              "Error while login with {provider}. Retry or login another way.",
              { provider: currentProvider }
            )
          }}
        </div>
        <div
          v-else-if="errorCode === LoginError.LOGIN_PROVIDER_NOT_FOUND"
          class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 text-sm"
        >
          {{
            t(
              "Error while login with {provider}. This login provider doesn't exist.",
              { provider: currentProvider }
            )
          }}
        </div>
        <div
          v-for="error in errors"
          :key="error"
          class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 text-sm"
        >
          {{ error }}
        </div>
      </div>

      <!-- Main login card -->
      <div class="bg-white shadow-sm border border-gray-200 px-6 py-8">
        <!-- Login form -->
        <form
          @submit="loginAction"
          v-if="config?.auth?.databaseLogin"
          class="space-y-6"
        >
          <!-- Email field -->
          <div>
            <label
              for="email"
              class="block text-sm font-medium text-gray-700 mb-2"
            >
              {{ t("Email") }}
            </label>
            <input
              id="email"
              name="email"
              type="email"
              v-model="credentials.email"
              required
              autocomplete="email"
              class="w-full px-3 py-3 border border-gray-300 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="t('Enter your email')"
            />
            <div v-if="caseWarningText" class="mt-1 text-sm text-amber-600">
              {{ caseWarningText }}
            </div>
          </div>

          <!-- Password field -->
          <div>
            <label
              for="password"
              class="block text-sm font-medium text-gray-700 mb-2"
            >
              {{ t("Password") }}
            </label>
            <div class="relative">
              <input
                id="password"
                name="password"
                :type="showPassword ? 'text' : 'password'"
                v-model="credentials.password"
                required
                autocomplete="current-password"
                class="w-full px-3 py-3 pr-10 border border-gray-300 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                :placeholder="t('Enter your password')"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600"
              >
                <svg
                  v-if="!showPassword"
                  class="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                  />
                </svg>
                <svg
                  v-else
                  class="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
                  />
                </svg>
              </button>
            </div>
          </div>

          <!-- "Forgot password" link - placed after password field -->
          <div class="text-left">
            <router-link
              :to="{
                name: RouteName.SEND_PASSWORD_RESET,
                params: { email: credentials.email },
              }"
              class="text-sm text-blue-600 hover:text-blue-500 font-medium"
            >
              {{ t("Forgot your password?") }}
            </router-link>
          </div>

          <!-- Submit button and LinkedIn button in same row -->
          <div class="flex gap-4">
            <!-- Submit button -->
            <button
              type="submit"
              :disabled="submitted"
              class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-medium py-3 px-6 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              <span v-if="!submitted">{{ t("Login") }}</span>
              <span v-else class="flex items-center justify-center">
                <svg
                  class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                {{ t("Signing in...") }}
              </span>
            </button>

            <!-- LinkedIn button (wider, with icon and custom text) -->
            <a
              v-if="linkedinProvider"
              :href="`/auth/${linkedinProvider.id}`"
              class="flex-1 border border-blue-600 text-blue-600 hover:bg-blue-50 font-medium py-3 px-6 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 flex items-center justify-center gap-2"
            >
              <!-- LinkedIn Icon -->
              <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
                />
              </svg>
              {{ t("Log in with LinkedIn") }}
            </a>
          </div>
        </form>

        <!-- "Didn't receive instructions" link - after the form -->
        <div class="mt-6 text-left">
          <router-link
            :to="{
              name: RouteName.RESEND_CONFIRMATION,
              params: { email: credentials.email },
            }"
            class="text-sm text-blue-600 hover:text-blue-500 underline"
          >
            {{ t("Didn't receive the instructions?") }}
          </router-link>
        </div>

        <!-- Bottom separator line -->
        <div class="mt-8 pt-6 border-t border-gray-200">
          <!-- "Create account" link at bottom -->
          <div class="text-left">
            <span class="text-sm text-gray-600">{{
              t("Don't have an account?")
            }}</span>
            <router-link
              v-if="canRegister"
              :to="{
                name: RouteName.REGISTER,
                query: {
                  default_email: credentials.email,
                  default_password: credentials.password,
                },
              }"
              class="ml-1 text-sm text-blue-600 hover:text-blue-500 font-medium underline"
            >
              {{ t("Create an account") }}
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { LOGIN } from "@/graphql/auth";
import { LOGIN_CONFIG } from "@/graphql/config";
import { LOGGED_USER_LOCATION } from "@/graphql/user";
import { UPDATE_CURRENT_USER_CLIENT } from "@/graphql/user";
import { IConfig } from "@/types/config.model";
import { IUser } from "@/types/current-user.model";
import { saveUserData, SELECTED_PROVIDERS } from "@/utils/auth";
import { storeUserLocationAndRadiusFromUserSettings } from "@/utils/location";
import {
  initializeCurrentActor,
  NoIdentitiesException,
} from "@/utils/identity";
import { useMutation, useLazyQuery, useQuery } from "@vue/apollo-composable";
import { computed, reactive, ref, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import { useRoute, useRouter } from "vue-router";
import RouteName from "@/router/name";
import { LoginError, LoginErrorCode } from "@/types/enums";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useHead } from "@/utils/head";
import { enumTransformer, useRouteQuery } from "vue-use-route-query";
import { useLazyCurrentUserIdentities } from "@/composition/apollo/actor";

const { t } = useI18n({ useScope: "global" });
const router = useRouter();
const route = useRoute();

const { currentUser } = useCurrentUserClient();

const configQuery = useQuery<{
  config: Pick<
    IConfig,
    "auth" | "registrationsOpen" | "registrationsAllowlist"
  >;
}>(LOGIN_CONFIG);

const config = computed(() => configQuery.result.value?.config);

const canRegister = computed(() => {
  return (
    (config.value?.registrationsOpen || config.value?.registrationsAllowlist) &&
    config.value?.auth?.databaseLogin
  );
});

const errors = ref<string[]>([]);
const submitted = ref(false);
const showPassword = ref(false);

const credentials = reactive({
  email: typeof route.query.email === "string" ? route.query.email : "",
  password:
    typeof route.query.password === "string" ? route.query.password : "",
});

const redirect = useRouteQuery("redirect", "");
const errorCode = useRouteQuery("code", null, enumTransformer(LoginErrorCode));

const hasErrors = computed(() => {
  return errorCode.value || errors.value.length > 0;
});

// Login
const loginMutation = useMutation(LOGIN);
// Load user identities
const currentUserIdentitiesQuery = useLazyCurrentUserIdentities();
// Update user in cache
const currentUserMutation = useMutation(UPDATE_CURRENT_USER_CLIENT);
// Retrieve preferred location
const loggedUserLocationQuery = useLazyQuery<{
  loggedUser: IUser;
}>(LOGGED_USER_LOCATION);

// form submit action
const loginAction = async (e: Event) => {
  e.preventDefault();
  if (submitted.value) {
    return;
  }
  submitted.value = true;
  errors.value = [];

  try {
    // Step 1: login the user
    const result = await loginMutation.mutate({
      email: credentials.email,
      password: credentials.password,
    });
    submitted.value = false;
    if (!result || !result.data) {
      throw new Error("Login: user's data is undefined");
    }
    const loginData = result.data;

    // Login saved to local storage
    saveUserData(loginData.login);

    // Step 2: save login in apollo cache
    await currentUserMutation.mutate({
      id: loginData.login.user.id,
      email: credentials.email,
      isLoggedIn: true,
      role: loginData.login.user.role,
    });

    // Step 3a: Retrieving user location
    const loggedUserLocationPromise = loggedUserLocationQuery.load();

    // Step 3b: Setuping user's identities
    // FIXME this promise never resolved the first time
    // no idea why !
    // this appends even with the last version of apollo-composable (4.0.2)
    // may be related to that : https://github.com/vuejs/apollo/issues/1543
    // EDIT: now it works :shrug:
    const currentUserIdentitiesResult = await currentUserIdentitiesQuery.load();
    if (!currentUserIdentitiesResult) {
      throw new Error("Loading user's identities failed");
    }

    await initializeCurrentActor(currentUserIdentitiesResult.loggedUser.actors);

    // Step 3a following
    const loggedUserLocationResult = (await loggedUserLocationPromise) as
      | false
      | { loggedUser: IUser };
    storeUserLocationAndRadiusFromUserSettings(
      loggedUserLocationResult && (loggedUserLocationResult as any).loggedUser
        ? (loggedUserLocationResult as any).loggedUser.settings?.location
        : undefined
    );

    // Soft redirect
    if (redirect.value) {
      console.debug("We have a redirect", redirect.value);
      router.push(redirect.value);
      return;
    }
    console.debug("No redirect, going to homepage");
    if (window.localStorage) {
      console.debug("Has localstorage, setting welcome back");
      window.localStorage.setItem("welcome-back", "yes");
    }
    router.replace({ name: RouteName.HOME });

    // Hard redirect
    // since we fail to refresh the navbar properly, we force a page reload.
    // see the explanation of the bug bellow
    // window.location = redirect.value || "/";
  } catch (err: any) {
    if (err instanceof NoIdentitiesException && currentUser.value) {
      console.debug("No identities, redirecting to profile registration");
      await router.push({
        name: RouteName.CREATE_IDENTITY,
      });
    } else {
      console.error(err);
      submitted.value = false;
      if (err.graphQLErrors) {
        err.graphQLErrors.forEach(({ message }: { message: string }) => {
          errors.value.push(message);
        });
      } else if (err.networkError) {
        errors.value.push(err.networkError.message);
      }
    }
  }
};

const hasCaseWarning = computed<boolean>(() => {
  return credentials.email !== credentials.email.toLowerCase();
});

const caseWarningText = computed<string | undefined>(() => {
  if (hasCaseWarning.value) {
    return t(
      "Emails usually don't contain capitals, make sure you haven't made a typo."
    ) as string;
  }
  return undefined;
});

const currentProvider = computed(() => {
  const queryProvider = route?.query.provider as string | undefined;
  if (queryProvider) {
    return SELECTED_PROVIDERS[queryProvider];
  }
  return "unknown provider";
});

const linkedinProvider = computed(() => {
  return config.value?.auth?.oauthProviders?.find(
    (provider) => provider.id === "linkedin"
  );
});

onMounted(() => {
  // Already-logged-in and accessing /login
  if (currentUser.value?.isLoggedIn) {
    console.debug(
      "Current user is already logged-in, redirecting to Homepage",
      currentUser.value
    );
    router.push("/");
  }
});

useHead({
  title: computed(() => t("Login")),
});
</script>
