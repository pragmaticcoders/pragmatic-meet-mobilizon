<template>
  <div
    class="relative max-w-screen-xl mx-auto w-full min-h-[500px] md:min-h-[600px] lg:min-h-[700px]"
    style="
      border-radius: 50px;
      overflow: hidden;
      background:
        linear-gradient(
          180deg,
          #fff 0%,
          rgba(255, 255, 255, 0.8) 36.94%,
          rgba(255, 255, 255, 0) 52.9%
        ),
        url(/img/landing.jpg) lightgray center / cover no-repeat;
    "
  >
    <!-- Content -->
    <div
      class="absolute inset-0 flex flex-col items-center justify-start px-6 md:px-12 lg:px-[150px] xl:px-[300px]"
    >
      <!-- Hero Text -->
      <div class="text-center max-w-2xl">
        <h1
          class="text-[#121212] text-2xl md:text-3xl lg:text-4xl font-bold leading-tight mb-4"
        >
          {{ t("landingPageHeading") }}
        </h1>
        <p
          class="text-[#121212] text-base md:text-lg font-medium leading-relaxed"
        >
          {{ t("landingPageDescription") }}
        </p>
      </div>

      <!-- CTA Button -->
      <div class="mt-8 md:mt-10">
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
