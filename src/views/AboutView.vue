<template>
  <div>
    <section class="max-w-screen-xl mx-auto px-4 md:px-16">
      <div class="flex flex-col md:flex-row gap-8">
        <aside class="w-full md:w-80 mt-8">
          <div
            class="bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-700 p-5"
          >
            <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-5">
              {{ t("Legal Information") }}
            </h2>
            <nav class="flex flex-col">
              <router-link
                class="flex items-center justify-start px-3 py-2 text-[17px] font-medium transition-colors"
                :class="
                  $route.name === RouteName.TERMS
                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                    : 'text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800'
                "
                :to="{ name: RouteName.TERMS }"
              >
                {{ t("Terms of Service") }}
              </router-link>

              <router-link
                class="flex items-center justify-start px-3 py-2 text-[17px] font-medium transition-colors"
                :class="
                  $route.name === RouteName.PRIVACY
                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                    : 'text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800'
                "
                :to="{ name: RouteName.PRIVACY }"
              >
                {{ t("Privacy Policy") }}
              </router-link>

              <router-link
                class="flex items-center justify-start px-3 py-2 text-[17px] font-medium transition-colors"
                :class="
                  $route.name === RouteName.RULES
                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                    : 'text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800'
                "
                :to="{ name: RouteName.RULES }"
              >
                {{ t("Rules") }}
              </router-link>

              <router-link
                class="flex items-center justify-start px-3 py-2 text-[17px] font-medium transition-colors"
                :class="
                  $route.name === RouteName.GLOSSARY
                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                    : 'text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800'
                "
                :to="{ name: RouteName.GLOSSARY }"
              >
                {{ t("Glossary") }}
              </router-link>
            </nav>
          </div>
        </aside>

        <div class="flex-1 min-w-0">
          <router-view />
        </div>
      </div>
    </section>
    <div class="bg-gray-100 dark:bg-gray-800 p-12 mt-16">
      <div class="max-w-screen-xl mx-auto px-4 md:px-16">
        <h2 class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-4">
          Powered by Open Source
        </h2>
        <p class="text-lg text-gray-600 dark:text-gray-300 mb-6">
          Pragmatic Meet is built on Mobilizon - a user-friendly, emancipatory
          and ethical tool for gathering, organizing, and mobilizing.
        </p>
        <o-button
          tag="a"
          icon-left="open-in-new"
          class="bg-primary-600 text-white hover:bg-primary-700"
          href="https://joinmobilizon.org"
          >Learn more about Mobilizon</o-button
        >
      </div>
    </div>
    <div
      v-if="!currentUser || !currentUser.id"
      class="bg-primary-50 dark:bg-gray-900 py-16"
    >
      <div class="max-w-screen-xl mx-auto px-4 md:px-16 text-center">
        <div class="grid md:grid-cols-2 gap-12">
          <div v-if="config && config.registrationsOpen">
            <h2
              class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-4"
            >
              Join Pragmatic Meet
            </h2>
            <p class="text-lg text-gray-600 dark:text-gray-300 mb-6">
              Create an account to start organizing and discovering events in
              your community.
            </p>
            <o-button
              tag="router-link"
              class="bg-primary-600 text-white hover:bg-primary-700 text-lg px-6 py-3"
              :to="{ name: RouteName.REGISTER }"
              >Create an account</o-button
            >
          </div>
          <div>
            <h2
              class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-4"
            >
              Explore Other Instances
            </h2>
            <p class="text-lg text-gray-600 dark:text-gray-300 mb-6">
              Find a Mobilizon instance that fits your community's needs.
            </p>
            <o-button
              tag="a"
              class="bg-secondary-600 text-white hover:bg-secondary-700 text-lg px-6 py-3"
              href="https://mobilizon.org"
              >Browse instances</o-button
            >
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ABOUT } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import RouteName from "../router/name";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { useRoute } from "vue-router";

const { currentUser } = useCurrentUserClient();
const $route = useRoute();

const { result: configResult } = useQuery<{ config: IConfig }>(ABOUT);

const config = computed(() => configResult.value?.config);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() =>
    t("About {instance}", { instance: config.value?.name })
  ),
});

// metaInfo() {
//   return {
//     title: this.t("About {instance}", {
//       // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//       // @ts-ignore
//       instance: this?.config?.name,
//     }) as string,
//   };
// },
</script>
