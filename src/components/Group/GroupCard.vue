<template>
  <LinkOrRouterLink
    :to="to"
    :isInternal="isInternal"
    class="group-card bg-white border border-gray-200 hover:shadow-lg transition-shadow duration-200 flex overflow-hidden"
  >
    <!-- Image Section -->
    <div
      class="flex-shrink-0 w-[370px] min-h-[176px] bg-cover bg-center bg-gray-100"
      :style="
        group.avatar ? { backgroundImage: `url(${group.avatar.url})` } : {}
      "
    >
      <div
        v-if="!group.avatar"
        class="w-full h-full flex items-center justify-center bg-primary-50"
      >
        <AccountGroup :size="80" class="text-primary-500" />
      </div>
    </div>

    <!-- Content Section -->
    <div class="flex-1 flex flex-col justify-between p-5">
      <!-- Title Section -->
      <div class="flex flex-col gap-0.5">
        <!-- Date/Time placeholder - you can replace with actual event date if available -->
        <div class="text-xs font-medium text-gray-600 leading-[18px]">
          {{ group.domain || "" }}
        </div>
        <h3
          class="text-[17px] font-bold text-gray-700 leading-[26px] line-clamp-2"
          dir="auto"
        >
          {{ displayName(group) }}
        </h3>
      </div>

      <!-- Info Section -->
      <div class="flex flex-col gap-2">
        <!-- Group Name with Avatar -->
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div
              class="w-6 h-6 rounded-full overflow-hidden bg-gray-100 flex-shrink-0"
            >
              <img
                v-if="group.avatar"
                :src="group.avatar.url"
                alt=""
                class="w-full h-full object-cover"
              />
              <div
                v-else
                class="w-full h-full flex items-center justify-center"
              >
                <AccountGroup :size="16" class="text-gray-500" />
              </div>
            </div>
            <span class="text-[15px] font-bold text-gray-700 leading-[23px]">
              {{ displayName(group) }}
            </span>
          </div>

          <!-- Username -->
          <div class="flex items-center gap-2">
            <div class="w-6 h-6 flex items-center justify-center">
              <div class="w-6 h-6 text-gray-500">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path
                    d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"
                  />
                </svg>
              </div>
            </div>
            <span class="text-[15px] font-medium text-gray-600 leading-[23px]">
              @{{ usernameWithDomain(group) }}
            </span>
          </div>
        </div>

        <!-- Tags Section -->
        <div class="flex gap-1 items-center flex-wrap">
          <!-- Member count as tag -->
          <div
            v-if="
              (group?.members?.total !== undefined && group?.followers?.total !== undefined) ||
              group?.membersCount ||
              group?.followersCount
            "
            class="bg-primary-50 px-2 py-1 flex items-center gap-1.5"
          >
            <span class="text-[15px] text-primary-500 leading-[23px]">
              <span v-if="group?.members?.total !== undefined && group?.followers?.total !== undefined">
                {{ group.members.total + group.followers.total }}
              </span>
              <span v-else>
                {{ (group.membersCount ?? 0) + (group.followersCount ?? 0) }}
              </span>
              {{ t("members") }}
            </span>
          </div>

          <!-- Domain tag if available -->
          <div v-if="group.domain" class="bg-primary-50 px-2 py-1">
            <span class="text-[15px] text-primary-500 leading-[23px]">
              {{ group.domain }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </LinkOrRouterLink>
</template>

<script lang="ts" setup>
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";
import { useI18n } from "vue-i18n";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import { computed } from "vue";
import LinkOrRouterLink from "../core/LinkOrRouterLink.vue";

const props = withDefaults(
  defineProps<{
    group: IGroup;
    showSummary?: boolean;
    isRemoteGroup?: boolean;
    isLoggedIn?: boolean;
    mode?: "row" | "column";
  }>(),
  { showSummary: true, isRemoteGroup: false, isLoggedIn: true, mode: "column" }
);

const { t } = useI18n({ useScope: "global" });

const isInternal = computed(() => {
  return props.isRemoteGroup && props.isLoggedIn === false;
});

const to = computed(() => {
  if (props.isRemoteGroup) {
    if (props.isLoggedIn === false) {
      return props.group.url;
    }
    return {
      name: RouteName.INTERACT,
      query: { uri: encodeURI(props.group.url) },
    };
  }
  return {
    name: RouteName.GROUP,
    params: { preferredUsername: usernameWithDomain(props.group) },
  };
});
</script>
