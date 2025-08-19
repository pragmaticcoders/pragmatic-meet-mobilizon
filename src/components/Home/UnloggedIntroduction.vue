<template>
  <section class="container mx-auto my-8 lg:pl-[20%]">
    <div class="mx-auto">
      <!-- Header with slogan and publish button -->
      <div class="relative mb-6 md:pr-[10%]">
        <!-- Publish button positioned at far right on desktop, hidden on mobile -->
        <div class="hidden md:block absolute top-0 right-0 z-10">
          <router-link
            :to="{ name: RouteName.CREATE_EVENT }"
            class="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg transition-colors duration-200"
          >
            <Plus :size="20" />
            {{ t("Publish") }}
          </router-link>
        </div>

        <!-- Slogan with space for button on desktop -->
        <h1
          class="dark:text-white font-bold text-3xl md:text-4xl lg:text-5xl md:pr-[15%] leading-[1.4]"
        >
          <span class="bg-blue-600 text-white px-3 py-1 rounded-lg">{{
            t("Free")
          }}</span>
          <span class="ml-4">{{ restOfSlogan }}</span>
        </h1>

        <!-- Publish button below slogan on mobile -->
        <div class="md:hidden mt-4">
          <router-link
            :to="{ name: RouteName.CREATE_EVENT }"
            class="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg transition-colors duration-200"
          >
            <Plus :size="20" />
            {{ t("Publish") }}
          </router-link>
        </div>
      </div>

      <!-- Description with max width -->
      <div class="md:pr-[20%]">
        <p
          class="dark:text-white text-lg md:text-xl text-center leading-relaxed text-gray-600"
        >
          {{ description }}
        </p>
      </div>
    </div>
  </section>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { computed } from "vue";
import RouteName from "../../router/name";
import Plus from "vue-material-design-icons/Plus.vue";

const { t } = useI18n({ useScope: "global" });

const fullSlogan = computed(() => t("mainPageSlogan"));
const description = computed(() => t("mainPageDescription"));

// Split the slogan to highlight "Free" separately
const restOfSlogan = computed(() => {
  const slogan = fullSlogan.value;
  // Remove "Free" from the beginning and clean up
  return slogan.split(" ").slice(1).join(" ");
});
</script>
