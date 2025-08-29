<template>
  <LinkOrRouterLink
    :to="to"
    :isInternal="isInternal"
    class="bg-white border border-[#cac9cb] overflow-hidden flex flex-col w-full h-[380px]"
  >
    <!-- Group cover image -->
    <div class="relative h-[200px] bg-gray-100 flex-shrink-0 overflow-hidden">
      <div v-if="group.banner?.url" class="w-full h-full">
        <lazy-image-wrapper :picture="group.banner" class="w-full h-full" />
      </div>
      <div
        v-else
        class="w-full h-full flex items-center justify-center bg-gray-50"
      >
        <svg
          width="64"
          height="64"
          viewBox="0 0 48 48"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          class="text-gray-300 empty-state-icon"
        >
          <!-- Group/People icon -->
          <circle
            cx="20"
            cy="16"
            r="6"
            stroke="currentColor"
            stroke-width="2"
            fill="none"
          />
          <circle
            cx="32"
            cy="20"
            r="4"
            stroke="currentColor"
            stroke-width="2"
            fill="none"
          />
          <path
            d="M8 38v-4c0-4.418 3.582-8 8-8h8c4.418 0 8 3.582 8 8v4"
            stroke="currentColor"
            stroke-width="2"
            fill="none"
            stroke-linecap="round"
          />
          <path
            d="M36 38v-2c0-2.761-1.567-5.149-3.861-6.349"
            stroke="currentColor"
            stroke-width="2"
            fill="none"
            stroke-linecap="round"
          />
        </svg>
      </div>
    </div>

    <!-- Group details -->
    <div class="p-5 flex flex-col flex-1 min-h-0 overflow-hidden">
      <!-- Title section -->
      <div class="flex flex-col mb-4">
        <div class="flex items-center gap-2">
          <figure
            v-if="group.avatar"
            class="w-6 h-6 rounded-full overflow-hidden flex-shrink-0"
          >
            <img
              class="w-full h-full object-cover"
              :src="group.avatar.url"
              alt=""
            />
          </figure>
          <div
            v-else
            class="w-6 h-6 bg-gray-200 flex items-center justify-center flex-shrink-0 rounded-full"
          >
            <svg class="w-3 h-3 text-gray-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 12.75c1.63 0 3.07.39 4.24.9 1.08.48 1.76 1.56 1.76 2.73V18H6v-1.61c0-1.18.68-2.26 1.76-2.73 1.17-.52 2.61-.91 4.24-.91zM4 13c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm1.13 1.1c-.37-.06-.74-.1-1.13-.1-.99 0-1.93.21-2.78.58A2.01 2.01 0 0 0 0 16.43V18h4.5v-1.61c0-.83.23-1.61.63-2.29zM20 13c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm4 3.43c0-.81-.48-1.53-1.22-1.85A6.95 6.95 0 0 0 20 14c-.39 0-.76.04-1.13.1.4.68.63 1.46.63 2.29V18H24v-1.57zM12 6c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3z"/>
            </svg>
          </div>
          <h3
            class="text-[15px] font-bold text-[#1c1b1f] leading-[23px] flex-1 truncate"
          >
            {{ displayName(group) }}
          </h3>
        </div>
        <div class="pl-8">
          <span class="text-xs font-medium text-[#37363a] leading-[18px] truncate block">
            @{{ usernameWithDomain(group) }}
          </span>
        </div>
      </div>

      <!-- Group description -->
      <div
        v-if="group.summary"
        class="text-[13px] font-medium text-black leading-[18px] h-[36px] overflow-hidden"
        :title="stripHtml(group.summary)"
      >
        {{ truncatedSummary }}
      </div>
      <div v-else class="h-[36px]"></div>

      <!-- Group info -->
      <div class="flex flex-col gap-1 mt-auto">
        <div class="flex items-center gap-2">
          <div class="w-6 h-6 flex items-center justify-center">
            <AccountMultiple class="w-5 h-5 text-gray-500" />
          </div>
          <span class="text-[15px] font-medium text-black leading-[23px] truncate">
            {{ getMemberCount }} {{ t("members") }}
          </span>
        </div>
        <div v-if="group.physicalAddress" class="flex items-center gap-2">
          <div class="w-6 h-6 flex items-center justify-center">
            <MapMarker class="w-5 h-5 text-gray-500" />
          </div>
          <span class="text-[15px] font-medium text-[#37363a] leading-[23px] truncate">
            {{ group.physicalAddress.locality || group.physicalAddress.region }}
          </span>
        </div>
      </div>
    </div>
  </LinkOrRouterLink>
</template>

<script lang="ts" setup>
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";
import { useI18n } from "vue-i18n";

import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import MapMarker from "vue-material-design-icons/MapMarker.vue";
import { computed } from "vue";
import LinkOrRouterLink from "../core/LinkOrRouterLink.vue";
import LazyImageWrapper from "../Image/LazyImageWrapper.vue";

const props = withDefaults(
  defineProps<{
    group: IGroup;
    isRemoteGroup?: boolean;
    isLoggedIn?: boolean;
  }>(),
  { isRemoteGroup: false, isLoggedIn: true }
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

const getMemberCount = computed(() => {
  if (props.group?.members?.total !== undefined && props.group?.followers?.total !== undefined) {
    return props.group.members.total + props.group.followers.total;
  }
  return (props.group.membersCount ?? 0) + (props.group.followersCount ?? 0);
});

// Helper function to strip HTML tags
const stripHtml = (html: string): string => {
  const tmp = document.createElement("div");
  tmp.innerHTML = html;
  return tmp.textContent || tmp.innerText || "";
};

// Computed property for truncated summary
const truncatedSummary = computed(() => {
  if (!props.group.summary) return "";
  
  const plainText = stripHtml(props.group.summary);
  const maxLength = 120; // Adjust this number as needed
  
  if (plainText.length <= maxLength) {
    return plainText;
  }
  
  return plainText.substring(0, maxLength).trim() + "...";
});
</script>
