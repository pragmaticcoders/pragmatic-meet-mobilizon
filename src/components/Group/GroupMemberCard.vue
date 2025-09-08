<template>
  <div
    class="border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:shadow-md transition-shadow duration-200 h-48 flex flex-col w-full max-w-full"
  >
    <div
      class="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 flex items-center gap-2 px-2 sm:px-4 py-3"
      dir="auto"
    >
      <figure class="flex-shrink-0" v-if="member.actor.avatar">
        <img
          class="rounded-full"
          :src="member.actor.avatar.url"
          alt=""
          width="24"
          height="24"
        />
      </figure>
      <AccountCircle v-else :size="24" class="text-gray-400" />
      <span
        class="text-sm font-medium text-gray-700 dark:text-gray-300 truncate"
      >
        {{ displayNameAndUsername(member.actor) }}
      </span>
    </div>
    <div class="p-2 sm:p-4 flex-1 flex flex-col">
      <div class="flex items-start gap-2 sm:gap-3 flex-1">
        <div class="flex-shrink-0">
          <figure class="h-12 w-12 sm:h-14 sm:w-14" v-if="member.parent.avatar">
            <img
              class="rounded-full w-full h-full object-cover border-2 border-gray-100 dark:border-gray-700"
              :src="member.parent.avatar.url"
              alt=""
              width="56"
              height="56"
            />
          </figure>
          <div
            v-else
            class="h-12 w-12 sm:h-14 sm:w-14 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center"
          >
            <AccountGroup :size="28" class="text-gray-400 dark:text-gray-500" />
          </div>
        </div>
        <div class="flex-1 min-w-0 flex flex-col">
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(member.parent),
              },
            }"
            class="hover:text-primary-600 dark:hover:text-primary-400 transition-colors flex-shrink-0"
          >
            <h3
              class="text-base sm:text-lg font-semibold text-gray-900 dark:text-white truncate"
            >
              {{ member.parent.name }}
            </h3>
            <div class="flex flex-col gap-1 mt-1">
              <span class="text-sm text-gray-500 dark:text-gray-400 truncate">
                @{{ usernameWithDomain(member.parent) }}
              </span>
              <div class="flex flex-wrap gap-1 mt-1">
                <span
                  v-if="member.role === MemberRole.ADMINISTRATOR"
                  class="inline-flex items-center px-2 py-0.5 text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200 truncate"
                >
                  {{ t("Administrator") }}
                </span>
                <span
                  v-else-if="member.role === MemberRole.MODERATOR"
                  class="inline-flex items-center px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 truncate"
                >
                  {{ t("Moderator") }}
                </span>
                <span
                  v-if="
                    member.parent.approvalStatus ===
                    ApprovalStatus.PENDING_APPROVAL
                  "
                  class="inline-flex items-center px-2 py-0.5 text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200 truncate"
                >
                  {{ t("Pending Admin Approval") }}
                </span>
                <span
                  v-else-if="
                    member.parent.approvalStatus === ApprovalStatus.REJECTED
                  "
                  class="inline-flex items-center px-2 py-0.5 text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200 truncate"
                >
                  {{ t("Rejected") }}
                </span>
              </div>
            </div>
          </router-link>
        </div>
        <div class="flex-shrink-0">
          <o-dropdown aria-role="list" position="bottom-left">
            <template #trigger>
              <button
                class="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <DotsHorizontal
                  class="cursor-pointer text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
                />
              </button>
            </template>

            <o-dropdown-item
              class="inline-flex items-center gap-2 hover:bg-red-50 dark:hover:bg-red-900/20"
              aria-role="listitem"
              @click="emit('leave')"
            >
              <ExitToApp class="text-red-600 dark:text-red-400" :size="20" />
              <span class="text-red-600 dark:text-red-400">{{
                t("Leave")
              }}</span>
            </o-dropdown-item>
          </o-dropdown>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { displayNameAndUsername, usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole, ApprovalStatus } from "@/types/enums";
import RouteName from "../../router/name";
import ExitToApp from "vue-material-design-icons/ExitToApp.vue";
import DotsHorizontal from "vue-material-design-icons/DotsHorizontal.vue";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useI18n } from "vue-i18n";

defineProps<{
  member: IMember;
}>();

const emit = defineEmits(["leave"]);

const { t } = useI18n({ useScope: "global" });
</script>
