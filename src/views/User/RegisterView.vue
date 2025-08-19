<template>
  <!-- Two-column layout -->
  <div
    class="max-w-screen-xl mx-auto px-4 md:px-16 flex flex-col lg:flex-row py-6 md:py-12 gap-8"
    v-if="!validationSent"
  >
    <!-- Left column - Content (hidden on mobile, shown on tablet+) -->
    <div class="hidden md:flex flex-1">
      <div class="max-w-lg">
        <h1
          class="text-2xl md:text-3xl lg:text-4xl font-bold text-gray-900 mb-2"
        >
          {{ t("Register for account in Pragmatic Meet!") }}
        </h1>

        <p class="text-gray-700 mb-6 text-sm md:text-base">
          {{ t("Pragmatic Meet is an instance of software") }}
          <a href="#" class="text-blue-600 underline">{{ t("Mobilizon") }}</a
          >.
        </p>

        <h2 class="text-base md:text-lg font-semibold text-gray-900 mb-4">
          {{ t("Why is it worth creating an account?") }}
        </h2>

        <ul class="space-y-2 md:space-y-3 text-gray-700 text-sm md:text-base">
          <li class="flex items-start">
            <span
              class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"
            ></span>
            {{ t("To create and manage events") }}
          </li>
          <li class="flex items-start">
            <span
              class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"
            ></span>
            {{
              t(
                "To create and manage multiple identities from the same account"
              )
            }}
          </li>
          <li class="flex items-start">
            <span
              class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"
            ></span>
            {{ t("To create events using one of your identities") }}
          </li>
          <li class="flex items-start">
            <span
              class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"
            ></span>
            {{
              t("To create and join groups and start organizing with others")
            }}
          </li>
          <li class="flex items-start">
            <span
              class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"
            ></span>
            {{
              t(
                "To follow groups and receive information about their latest events"
              )
            }}
          </li>
        </ul>

        <a
          href="#"
          class="inline-flex items-center text-blue-600 hover:text-blue-500 mt-4 md:mt-6 text-sm md:text-base"
        >
          {{ t("Learn more") }}
          <svg
            class="w-4 h-4 ml-1"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M17 8l4 4m0 0l-4 4m4-4H3"
            />
          </svg>
        </a>
      </div>
    </div>

    <!-- Mobile header (only visible on mobile) -->
    <div class="md:hidden text-center mb-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-2">
        {{ t("Register for account in Pragmatic Meet!") }}
      </h1>
      <p class="text-gray-600 text-sm">
        {{ t("Join our community") }}
      </p>
    </div>

    <!-- Right column - Form -->
    <div
      class="w-full lg:flex-1 bg-white px-4 md:px-8 py-6 md:py-8 lg:max-w-md border border-gray-200 shadow-sm"
    >
      <div class="space-y-4">
        <!-- Email field -->
        <div>
          <label
            for="email"
            class="block text-sm font-medium text-gray-700 mb-1"
          >
            {{ t("Email address") }}
          </label>
          <input
            id="email"
            name="email"
            type="email"
            v-model="credentials.email"
            required
            autocomplete="email"
            class="w-full px-3 py-2 border border-gray-300 text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
          />
          <div v-if="emailErrors.length > 0" class="mt-1 text-xs text-red-600">
            <div v-for="error in emailErrors" :key="error.message">
              {{ error.message }}
            </div>
          </div>
        </div>

        <!-- Password field -->
        <div>
          <label
            for="password"
            class="block text-sm font-medium text-gray-700 mb-1"
          >
            {{ t("Password") }}
          </label>
          <input
            id="password"
            name="password"
            type="password"
            v-model="credentials.password"
            required
            minlength="6"
            autocomplete="new-password"
            class="w-full px-3 py-2 border border-gray-300 text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
          />
          <div
            v-if="passwordErrors.length > 0"
            class="mt-1 text-xs text-red-600"
          >
            <div v-for="error in passwordErrors" :key="error.message">
              {{ error.message }}
            </div>
          </div>
        </div>

        <!-- Terms checkboxes -->
        <div class="space-y-2">
          <div class="flex items-start space-x-2">
            <input
              type="checkbox"
              id="accept_terms"
              v-model="acceptTerms"
              required
              class="w-4 h-4 mt-0.5 border border-gray-300 text-blue-600 bg-gray-50 focus:ring-2 focus:ring-blue-500"
            />
            <label for="accept_terms" class="text-xs text-gray-700 leading-4">
              {{ t("I agree to the") }}
              <router-link
                :to="{ name: RouteName.TERMS }"
                class="text-blue-600 hover:text-blue-500 underline"
              >
                {{ t("terms of service") }}
              </router-link>
              {{ t("and") }}
              <router-link
                :to="{ name: RouteName.RULES }"
                class="text-blue-600 hover:text-blue-500 underline"
              >
                {{ t("general terms of use") }}
              </router-link>
              *
            </label>
          </div>

          <div class="flex items-start space-x-2">
            <input
              type="checkbox"
              id="accept_marketing"
              v-model="acceptMarketing"
              class="w-4 h-4 mt-0.5 border border-gray-300 text-blue-600 bg-gray-50 focus:ring-2 focus:ring-blue-500"
            />
            <label
              for="accept_marketing"
              class="text-xs text-gray-700 leading-4"
            >
              {{
                t(
                  "I agree to the use by Pragmatic Coders sp. z o.o. of electronic communication means and my data for the purpose of sending me business information and conducting marketing activities (e.g. newsletter). The consent can be withdrawn at any time through appropriate account settings."
                )
              }}
            </label>
          </div>

          <p class="text-xs text-red-600">* {{ t("Required consent") }}</p>
        </div>

        <!-- Submit buttons -->
        <div class="flex flex-col sm:flex-row gap-3">
          <button
            type="submit"
            @click="submit"
            :disabled="sendingForm || !acceptTerms"
            class="w-full sm:flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-medium py-2.5 px-4 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 text-sm"
          >
            <span v-if="!sendingForm">{{ t("Create account") }}</span>
            <span v-else class="flex items-center justify-center">
              <svg
                class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
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
                  d="M4 12a8 8 0 012.458-7C7.518 4.943 10.523 4 12 4c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                ></path>
              </svg>
              {{ t("Creating...") }}
            </span>
          </button>

          <!-- LinkedIn OAuth button -->
          <a
            v-if="linkedinProvider"
            :href="
              acceptTerms && credentials.email && credentials.password
                ? `/auth/${linkedinProvider.id}`
                : '#'
            "
            :class="[
              'w-full sm:flex-1 font-medium py-2.5 px-4 transition-colors duration-200 focus:outline-none flex items-center justify-center gap-2 text-sm',
              acceptTerms && credentials.email && credentials.password
                ? 'border border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2'
                : 'border border-gray-300 text-gray-400 bg-gray-50 cursor-not-allowed',
            ]"
            @click="
              !(acceptTerms && credentials.email && credentials.password) &&
                $event.preventDefault()
            "
          >
            <!-- LinkedIn Icon -->
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
              <path
                d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
              />
            </svg>
            <span class="hidden sm:inline">{{
              t("Register with LinkedIn")
            }}</span>
            <span class="sm:hidden">{{ t("LinkedIn") }}</span>
          </a>
        </div>

        <!-- Additional links -->
        <div class="mt-8 flex flex-col">
          <router-link
            :to="{
              name: RouteName.RESEND_CONFIRMATION,
              params: { email: credentials.email },
            }"
            class="block text-xs text-blue-600 hover:text-blue-500 underline"
          >
            {{ t("Didn't receive the instructions?") }}
          </router-link>

          <hr class="border-gray-200 my-8" />

          <div class="text-xs text-gray-600">
            {{ t("Already have an account?") }}
            <router-link
              :to="{ name: RouteName.LOGIN }"
              class="text-blue-600 hover:text-blue-500 underline"
            >
              {{ t("Sign in!") }}
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Success state -->
  <div
    v-else
    class="max-w-screen-xl mx-auto px-4 md:px-16 flex items-center justify-center min-h-screen"
  >
    <div class="w-full max-w-md text-center">
      <div
        class="bg-white shadow-sm border border-gray-200 px-4 md:px-6 py-6 md:py-8"
      >
        <!-- Success icon -->
        <div
          class="mx-auto flex items-center justify-center h-16 w-16 bg-green-100 rounded-full mb-6"
        >
          <svg
            class="h-8 w-8 text-green-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        </div>

        <h2 class="text-2xl font-bold text-gray-900 mb-4">
          {{ t("Check your email") }}
        </h2>

        <p class="text-gray-600 mb-2">
          {{ t("We sent a verification link to") }}
        </p>
        <p class="text-gray-900 font-medium mb-6">
          {{ credentials.email }}
        </p>

        <p class="text-gray-600 text-sm mb-8">
          {{
            t(
              "Click the link in the email to verify your account. If you don't see it, check your spam folder."
            )
          }}
        </p>

        <router-link
          :to="{ name: RouteName.HOME }"
          class="inline-block bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-6 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          {{ t("Back to homepage") }}
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { CREATE_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IConfig } from "../../types/config.model";
import { CONFIG } from "../../graphql/config";
import { computed, reactive, ref, watch } from "vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useRoute } from "vue-router";
import { useHead } from "@/utils/head";
import { AbsintheGraphQLErrors } from "@/types/errors.model";

type errorType = "danger" | "warning";
type errorMessage = { type: errorType; message: string };
type credentialsType = { email: string; password: string; locale: string };

const { t, locale } = useI18n({ useScope: "global" });
const route = useRoute();
const validationSent = ref(false);
const acceptTerms = ref(false);
const acceptMarketing = ref(false);

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed(() => configResult.value?.config);

const linkedinProvider = computed(() => {
  return config.value?.auth?.oauthProviders?.find(
    (provider) => provider.id === "linkedin"
  );
});

const credentials = reactive<credentialsType>({
  email: typeof route.query.email === "string" ? route.query.email : "",
  password:
    typeof route.query.password === "string" ? route.query.password : "",
  locale: "en",
});

const emailErrors = ref<errorMessage[]>([]);
const passwordErrors = ref<errorMessage[]>([]);

const sendingForm = ref(false);

const title = computed((): string => {
  return t("Create your account");
});

useHead({
  title: () => title.value,
});

const { onDone, onError, mutate } = useMutation(CREATE_USER);

onDone(() => {
  validationSent.value = true;
});

onError((error) => {
  (error.graphQLErrors as AbsintheGraphQLErrors).forEach(
    ({ field, message }) => {
      switch (field) {
        case "email":
          emailErrors.value.push({
            type: "danger" as errorType,
            message: message[0] as string,
          });
          break;
        case "password":
          passwordErrors.value.push({
            type: "danger" as errorType,
            message: message[0] as string,
          });
          break;
        default:
      }
    }
  );
  sendingForm.value = false;
});

const submit = async (): Promise<void> => {
  sendingForm.value = true;
  credentials.locale = locale as unknown as string;
  try {
    emailErrors.value = [];
    passwordErrors.value = [];

    mutate(credentials);
  } catch (error: any) {
    console.error(error);
    sendingForm.value = false;
  }
};

watch(credentials, () => {
  if (credentials.email !== credentials.email.toLowerCase()) {
    const error = {
      type: "warning" as errorType,
      message: t(
        "Emails usually don't contain capitals, make sure you haven't made a typo."
      ),
    };
    emailErrors.value = [error];
  } else {
    emailErrors.value = emailErrors.value.filter(
      (error) => error.type !== "warning"
    );
  }
});
</script>
