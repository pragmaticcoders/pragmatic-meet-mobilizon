<template>
  <LinkOrRouterLink
    :to="to"
    :isInternal="isInternal"
    class="group-card-modern bg-gradient-to-br from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 rounded-xl shadow-lg transform hover:scale-105 transition-all duration-200 text-white flex flex-col items-center justify-center p-6 min-h-[200px] relative overflow-hidden"
  >
    <!-- Background decoration -->
    <div class="absolute top-0 right-0 w-20 h-20 bg-white/10 rounded-full -translate-y-10 translate-x-10"></div>
    <div class="absolute bottom-0 left-0 w-16 h-16 bg-white/5 rounded-full translate-y-8 -translate-x-8"></div>
    
    <!-- Avatar/Icon Section -->
    <div class="flex-none mb-4 z-10">
      <figure class="flex justify-center" v-if="group.avatar">
        <img
          class="rounded-full border-3 border-white/20 shadow-lg"
          :src="group.avatar.url"
          alt=""
          height="80"
          width="80"
        />
      </figure>
      <div v-else class="flex justify-center">
        <AccountGroup :size="80" class="text-white/90" />
      </div>
    </div>
    
    <!-- Content Section -->
    <div class="text-center z-10 flex-1 flex flex-col justify-center">
      <h3
        class="text-xl font-bold text-white mb-2 line-clamp-2 leading-tight"
        dir="auto"
      >
        {{ displayName(group) }}
      </h3>
      <span class="text-white/80 text-sm font-medium">
        {{ `@${usernameWithDomain(group)}` }}
      </span>
      
      <!-- Member count (compact) -->
      <div class="mt-3 flex items-center justify-center gap-1 text-white/70 text-xs" v-if="(group?.members?.total && group?.followers?.total) || group?.membersCount || group?.followersCount">
        <Account :size="14" />
        <span v-if="group?.members?.total && group?.followers?.total">
          {{ group.members.total + group.followers.total }}
        </span>
        <span v-else>
          {{ (group.membersCount ?? 0) + (group.followersCount ?? 0) }}
        </span>
        <span class="ml-1">{{ t("members") }}</span>
      </div>
    </div>
  </LinkOrRouterLink>
</template>

<script lang="ts" setup>
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";
import InlineAddress from "@/components/Address/InlineAddress.vue";
import { addressFullName } from "@/types/address.model";
import { useI18n } from "vue-i18n";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import Account from "vue-material-design-icons/Account.vue";
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
