<template>
  <div
    class="relative w-[1280px] mx-auto"
    style="
      border-radius: 50px;
      overflow: hidden;
      height: 696.304px;
      background:
        linear-gradient(
          180deg,
          #fff 0%,
          rgba(255, 255, 255, 0.8) 36.94%,
          rgba(255, 255, 255, 0) 52.9%
        ),
        url(/img/landing.jpg) lightgray 0px -0.057px / 100% 119.319% no-repeat;
    "
  >
    <!-- Content -->
    <div class="absolute inset-0 flex flex-col items-center px-[300px]">
      <!-- Hero Text -->
      <div class="text-center">
        <h1 class="text-[#121212] text-[36px] font-bold leading-[57.6px] mb-2">
          {{ t("landingPageHeading") }}
        </h1>
        <p class="text-[#121212] text-[17px] font-medium leading-[27.2px]">
          {{ t("landingPageDescription") }}
        </p>
      </div>

      <!-- CTA Button -->
      <div class="mt-10">
        <o-button
          tag="router-link"
          :to="{ name: RouteName.CREATE_EVENT }"
          size="lg"
          variant="primary"
          class="min-w-[200px]"
        >
          <o-icon icon="calendar-plus" />
          <span class="ml-2">{{ t("landingPageButton") }}</span>
        </o-button>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed, watch, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { useQuery } from "@vue/apollo-composable";
import RouteName from "@/router/name";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";

const { t } = useI18n({ useScope: "global" });

const router = useRouter();

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT, undefined, {
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
});

const currentUser = computed(() => currentUserResult.value?.currentUser);
const currentUserId = computed(() => currentUser.value?.id);

const redirectLoggedInUser = () => {
  if (currentUser.value?.id) {
    router.replace({ name: RouteName.DISCOVER });
  }
};

onMounted(() => {
  redirectLoggedInUser();
});

watch(currentUserId, (userId) => {
  if (userId) {
    redirectLoggedInUser();
  }
});
</script>
