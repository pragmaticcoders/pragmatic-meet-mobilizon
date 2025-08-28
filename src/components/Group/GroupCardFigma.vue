<template>
  <LinkOrRouterLink
    :to="to"
    :isInternal="isInternal"
    class="bg-white border border-[#cac9cb] overflow-hidden flex flex-col w-full h-[400px]"
  >
    <!-- Group cover image -->
    <div class="relative h-[154px] bg-gray-100 flex-shrink-0">
      <img
        v-if="group.banner?.url"
        :src="group.banner.url"
        alt=""
        class="w-full h-full object-cover"
      />
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
            class="w-6 h-6 rounded-full overflow-hidden"
          >
            <img
              class="w-full h-full object-cover"
              :src="group.avatar.url"
              alt=""
            />
          </figure>
          <div
            v-else
            class="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center"
          >
            <AccountGroup class="w-6 h-6 text-gray-500" />
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
        class="text-[15px] font-medium text-black leading-[23px] line-clamp-3 flex-1 min-h-0 mb-4 overflow-hidden"
        v-html="group.summary"
      ></div>
      <div v-else class="flex-1 mb-4"></div>

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
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import MapMarker from "vue-material-design-icons/MapMarker.vue";
import { computed } from "vue";
import LinkOrRouterLink from "../core/LinkOrRouterLink.vue";

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
</script>
