<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <!-- Hero Section -->
    <section class="container mx-auto mt-8 mb-12 lg:pl-[20%]">
      <div class="mx-auto">
        <!-- Header with slogan -->
        <div class="relative mb-6">
          <h1
            class="dark:text-white font-bold text-3xl md:text-4xl lg:text-5xl leading-[1.4]"
          >
            <span class="rhombus-bg text-white px-5 py-1 inline-block">{{
              t("Free")
            }}</span>
            <span class="ml-4">{{ restOfSlogan }}</span>
          </h1>
        </div>

        <!-- Description -->
        <div>
          <p
            class="dark:text-white text-lg md:text-xl text-center leading-relaxed text-gray-600"
          >
            {{ description }}
          </p>
        </div>
      </div>
    </section>

    <!-- Call-to-Action Buttons -->
    <section class="container mx-auto mb-12 text-center">
      <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
        <o-button
          tag="router-link"
          :to="{ name: RouteName.CREATE_EVENT }"
          size="lg"
          variant="primary"
          class="min-w-[200px]"
        >
          <o-icon icon="calendar-plus" />
          <span class="ml-2">{{ t("Create an Event") }}</span>
        </o-button>

        <o-button
          tag="router-link"
          :to="{ name: RouteName.DISCOVER }"
          size="lg"
          variant="text"
          class="min-w-[200px]"
        >
          <o-icon icon="compass" />
          <span class="ml-2">{{ t("Browse Events") }}</span>
        </o-button>
      </div>
    </section>
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

const fullSlogan = computed(() => t("mainPageSlogan"));
const description = computed(() => t("mainPageDescription"));
const restOfSlogan = computed(() => {
  const slogan = fullSlogan.value;
  return slogan.split(" ").slice(1).join(" ");
});

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

<style scoped>
.rhombus-bg {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  clip-path: polygon(15% 0%, 85% 0%, 100% 50%, 85% 100%, 15% 100%, 0% 50%);
  position: relative;
  transform: skew(-20deg);
  box-shadow: 0 4px 8px rgba(37, 99, 235, 0.3);
  transition: all 0.3s ease;
  margin: 0 8px;
}

.rhombus-bg:hover {
  transform: skew(-15deg) scale(1.05);
  box-shadow: 0 6px 12px rgba(37, 99, 235, 0.4);
}
</style>
