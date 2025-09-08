<template>
  <nav class="bg-white border-b border-gray-200" id="navbar">
    <div class="max-w-screen-xl mx-auto px-4 md:px-16">
      <div class="flex items-center justify-between h-16">
        <!-- Logo -->
        <router-link
          :to="{ name: RouteName.HOME }"
          class="flex items-center flex-shrink-0"
        >
          <img
            src="/img/pragmatic_logo.svg"
            alt="Pragmatic Meet"
            width="176"
            height="32"
            class="w-[176px] h-8"
          />
        </router-link>

        <!-- Desktop Navigation - Logged In -->
        <div
          v-if="currentUser?.isLoggedIn"
          class="hidden md:flex md:items-center md:space-x-6"
        >
          <nav class="flex items-center space-x-6">
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors"
            >
              {{ t("Search") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.EVENT_CALENDAR }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors relative"
            >
              {{ t("Calendar") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.MY_EVENTS }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors"
            >
              {{ t("My events") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.MY_GROUPS }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors"
            >
              {{ t("My groups") }}
            </router-link>
          </nav>

          <!-- User Actions -->
          <div class="flex items-center space-x-3">
            <!-- Conversations/Inbox -->
            <router-link
              :to="{ name: RouteName.CONVERSATION_LIST }"
              class="relative p-2 text-gray-400 hover:text-gray-600 transition-colors"
              id="conversations-menu-button"
            >
              <span class="sr-only">{{ t("Open conversations") }}</span>
              <Inbox :size="24" />
              <span
                v-show="unreadConversationsCount > 0"
                class="absolute -top-1 -right-1 bg-blue-600 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center"
              >
                {{ unreadConversationsCount }}
              </span>
            </router-link>

            <!-- User Avatar Dropdown -->
            <o-dropdown position="bottom-right">
              <template #trigger>
                <button
                  type="button"
                  class="flex items-center p-1 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500"
                  id="user-menu-button"
                >
                  <span class="sr-only">{{ t("Open user menu") }}</span>
                  <figure class="h-8 w-8" v-if="currentActor?.avatar">
                    <img
                      class="rounded-full w-full h-full object-cover"
                      alt=""
                      :src="currentActor?.avatar.url"
                      width="32"
                      height="32"
                      loading="lazy"
                    />
                  </figure>
                  <AccountCircle v-else :size="32" />
                </button>
              </template>

              <!-- Dropdown menu -->
              <div
                class="z-50 w-64 bg-white rounded-lg shadow-lg border border-gray-100"
              >
                <o-dropdown-item aria-role="listitem">
                  <div class="px-4 py-3 border-b border-gray-100">
                    <span class="block text-sm font-medium text-gray-900">{{
                      displayName(currentActor) || currentUser.email
                    }}</span>
                    <span
                      class="block text-sm text-gray-500 truncate"
                      v-if="
                        currentUser?.role === ICurrentUserRole.ADMINISTRATOR
                      "
                      >{{ t("Administrator") }}</span
                    >
                    <span
                      class="block text-sm text-gray-500 truncate"
                      v-if="currentUser?.role === ICurrentUserRole.MODERATOR"
                      >{{ t("Moderator") }}</span
                    >
                  </div>
                </o-dropdown-item>

                <o-dropdown-item
                  v-for="identity in identities"
                  :active="identity.id === currentActor?.id"
                  :key="identity.id"
                  tabindex="0"
                  @click="
                    setIdentity({
                      preferredUsername: identity.preferredUsername,
                    })
                  "
                  @keyup.enter="
                    setIdentity({
                      preferredUsername: identity.preferredUsername,
                    })
                  "
                >
                  <div class="flex items-center px-4 py-2 hover:bg-gray-50">
                    <div class="flex-shrink-0">
                      <figure class="h-8 w-8" v-if="identity.avatar">
                        <img
                          class="rounded-full object-cover h-full w-full"
                          loading="lazy"
                          :src="identity.avatar.url"
                          alt=""
                          height="32"
                          width="32"
                        />
                      </figure>
                      <AccountCircle v-else :size="32" />
                    </div>
                    <div class="ml-3 flex-1 min-w-0">
                      <p class="text-sm font-medium text-gray-900 truncate">
                        {{ displayName(identity) }}
                      </p>
                      <p
                        class="text-sm text-gray-500 truncate"
                        v-if="identity.name"
                      >
                        @{{ identity.preferredUsername }}
                      </p>
                    </div>
                  </div>
                </o-dropdown-item>

                <div class="border-t border-gray-100">
                  <o-dropdown-item
                    aria-role="listitem"
                    tag="router-link"
                    :to="{ name: RouteName.SETTINGS }"
                  >
                    <span
                      class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                    >
                      {{ t("My account") }}
                    </span>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    v-if="currentUser?.role === ICurrentUserRole.ADMINISTRATOR"
                    tag="router-link"
                    :to="{ name: RouteName.ADMIN_DASHBOARD }"
                  >
                    <span
                      class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                    >
                      {{ t("Administration") }}
                    </span>
                  </o-dropdown-item>
                  <o-dropdown-item
                    aria-role="listitem"
                    @click="performLogout"
                    @keyup.enter="performLogout"
                  >
                    <span
                      class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                    >
                      {{ t("Log out") }}
                    </span>
                  </o-dropdown-item>
                </div>
              </div>
            </o-dropdown>
          </div>
        </div>

        <!-- Desktop Navigation - Not Logged In -->
        <div v-else class="hidden md:flex md:items-center md:space-x-6">
          <nav class="flex items-center space-x-6">
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors"
            >
              {{ t("Search") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.EVENT_CALENDAR }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors relative"
            >
              {{ t("Calendar") }}
            </router-link>
          </nav>

          <div class="flex items-center space-x-4">
            <router-link
              :to="{ name: RouteName.LOGIN }"
              class="text-gray-700 hover:text-blue-600 px-3 py-2 text-sm font-medium transition-colors"
            >
              {{ t("Login") }}
            </router-link>
            <router-link
              v-if="canRegister"
              :to="{ name: RouteName.REGISTER }"
              class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
            >
              {{ t("Register") }}
            </router-link>
          </div>
        </div>

        <!-- Mobile menu button -->
        <button
          @click="showMobileMenu = !showMobileMenu"
          type="button"
          class="md:hidden inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
          aria-controls="mobile-menu"
          aria-expanded="false"
        >
          <span class="sr-only">{{ t("Open main menu") }}</span>
          <svg
            class="h-6 w-6"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            />
          </svg>
        </button>
      </div>

      <!-- Mobile menu -->
      <div v-show="showMobileMenu" class="md:hidden" id="mobile-menu">
        <div class="px-2 pt-2 pb-3 space-y-1 border-t border-gray-200">
          <!-- Logged In Mobile Menu -->
          <template v-if="currentUser?.isLoggedIn">
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Search") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.EVENT_CALENDAR }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Calendar") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.MY_EVENTS }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("My events") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.MY_GROUPS }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("My groups") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.CONVERSATION_LIST }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md relative"
            >
              {{ t("Conversations") }}
              <span
                v-show="unreadConversationsCount > 0"
                class="ml-2 bg-blue-600 text-white text-xs rounded-full px-2 py-1"
              >
                {{ unreadConversationsCount }}
              </span>
            </router-link>
            <div class="border-t border-gray-200 my-2"></div>
            <router-link
              :to="{ name: RouteName.SETTINGS }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("My account") }}
            </router-link>
            <router-link
              v-if="currentUser?.role === ICurrentUserRole.ADMINISTRATOR"
              :to="{ name: RouteName.ADMIN_DASHBOARD }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Administration") }}
            </router-link>
            <button
              @click="performLogout"
              class="block w-full text-left px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Log out") }}
            </button>
          </template>

          <!-- Not Logged In Mobile Menu -->
          <template v-else>
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Search") }}
            </router-link>
            <router-link
              :to="{ name: RouteName.EVENT_CALENDAR }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Calendar") }}
            </router-link>
            <div class="border-t border-gray-200 my-2"></div>
            <router-link
              :to="{ name: RouteName.LOGIN }"
              class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50 rounded-md"
            >
              {{ t("Login") }}
            </router-link>
            <router-link
              v-if="canRegister"
              :to="{ name: RouteName.REGISTER }"
              class="block px-3 py-2 text-base font-medium bg-blue-600 text-white hover:bg-blue-700 rounded-md"
            >
              {{ t("Register") }}
            </router-link>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { logout } from "../utils/auth";
import { displayName, IPerson } from "../types/actor";
import RouteName from "../router/name";
import { computed, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Inbox from "vue-material-design-icons/Inbox.vue";
import { useCurrentUserClient } from "@/composition/apollo/user";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
} from "@/composition/apollo/actor";
import { useLazyQuery, useMutation } from "@vue/apollo-composable";
import { UPDATE_DEFAULT_ACTOR } from "@/graphql/actor";
import { changeIdentity } from "@/utils/identity";
import { useRegistrationConfig } from "@/composition/apollo/config";
import { useOruga } from "@oruga-ui/oruga-next";
import {
  UNREAD_ACTOR_CONVERSATIONS,
  UNREAD_ACTOR_CONVERSATIONS_SUBSCRIPTION,
} from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";

const { currentUser } = useCurrentUserClient();
const { currentActor } = useCurrentActorClient();

const router = useRouter();
const route = useRoute();

const { identities } = useCurrentUserIdentities();
const { registrationsOpen, registrationsAllowlist, databaseLogin } =
  useRegistrationConfig();

const canRegister = computed(() => {
  return (
    ((registrationsOpen.value || registrationsAllowlist.value) &&
      databaseLogin.value) ??
    false
  );
});

const { t } = useI18n({ useScope: "global" });

const unreadConversationsCount = computed(() => {
  const count = unreadActorConversationsResult.value?.loggedUser.defaultActor
    ?.unreadConversationsCount ?? 0;
  console.debug("NavBar: unreadConversationsCount computed", {
    count,
    hasResult: !!unreadActorConversationsResult.value,
    hasLoggedUser: !!unreadActorConversationsResult.value?.loggedUser,
    hasDefaultActor: !!unreadActorConversationsResult.value?.loggedUser?.defaultActor,
    rawCount: unreadActorConversationsResult.value?.loggedUser?.defaultActor?.unreadConversationsCount
  });
  return count;
});

const {
  result: unreadActorConversationsResult,
  load: loadUnreadConversations,
  subscribeToMore,
} = useLazyQuery<{
  loggedUser: Pick<ICurrentUser, "id" | "defaultActor">;
}>(UNREAD_ACTOR_CONVERSATIONS);

watch(currentActor, async (currentActorValue, previousActorValue) => {
  console.debug("NavBar: currentActor changed", {
    currentActorId: currentActorValue?.id,
    currentActorUsername: currentActorValue?.preferredUsername,
    previousActorId: previousActorValue?.id,
    previousActorUsername: previousActorValue?.preferredUsername,
    conditionMet: !!(
      currentActorValue?.id &&
      (currentActorValue.preferredUsername !==
        previousActorValue?.preferredUsername ||
        previousActorValue === null ||
        previousActorValue === undefined)
    )
  });
  
  if (
    currentActorValue?.id &&
    (currentActorValue.preferredUsername !==
      previousActorValue?.preferredUsername ||
      previousActorValue === null ||
      previousActorValue === undefined)
  ) {
    console.debug("NavBar: Setting up unread conversations subscription for actor", currentActorValue.id);
    const result = await loadUnreadConversations();
    console.debug("NavBar: Initial unread conversations loaded", {
      result,
      count: result && typeof result === 'object' ? result.loggedUser?.defaultActor?.unreadConversationsCount : null
    });

    subscribeToMore<
      { personId: string },
      { personUnreadConversationsCount: number }
    >({
      document: UNREAD_ACTOR_CONVERSATIONS_SUBSCRIPTION,
      variables: {
        personId: currentActor.value?.id as string,
      },
      updateQuery: (previousResult, { subscriptionData }) => {
        const newCount = subscriptionData?.data?.personUnreadConversationsCount;
        const previousCount = previousResult.loggedUser.defaultActor?.unreadConversationsCount;
        
        console.debug(
          "NavBar: Updating actor unread conversations count via subscription",
          {
            newCount,
            previousCount,
            subscriptionData: subscriptionData?.data
          }
        );
        
        return {
          ...previousResult,
          loggedUser: {
            id: previousResult.loggedUser.id,
            defaultActor: {
              ...previousResult.loggedUser.defaultActor,
              unreadConversationsCount: newCount ?? previousCount,
            } as IPerson, // no idea why,
          },
        };
      },
    });
  }
});

onMounted(() => {});

watch(identities, () => {
  // If we don't have any identities, the user has validated their account,
  // is logging for the first time but didn't create an identity somehow
  if (identities.value && identities.value.length === 0) {
    console.warn(
      "We have no identities listed for current user",
      identities.value
    );
    console.info("Pushing route to CREATE_IDENTITY");
    router.push({
      name: RouteName.CREATE_IDENTITY,
    });
  }
});

const { onDone, mutate: setIdentity } = useMutation<{
  changeDefaultActor: { id: string; defaultActor: { id: string } };
}>(UPDATE_DEFAULT_ACTOR);

onDone(({ data }) => {
  const identity = identities.value?.find(
    ({ id }) => id === data?.changeDefaultActor?.defaultActor?.id
  );
  if (!identity) return;
  changeIdentity(identity);
});

const showMobileMenu = ref(false);

const { notification } = useOruga();

const performLogout = async () => {
  console.debug("Logging out client...");
  await logout();
  notification.open({
    message: t("You have been logged-out"),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });

  if (route.meta["requiredAuth"] === true) {
    return router.push({ name: RouteName.HOME });
  }
};
</script>
