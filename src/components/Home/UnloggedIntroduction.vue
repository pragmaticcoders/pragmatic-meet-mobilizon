<template>
  <section class="container mx-auto my-8 px-4">
    <div class="max-w-4xl mx-auto">
      <!-- Header with slogan and publish button -->
      <div class="relative mb-6">
        <!-- Publish button positioned at far right -->
        <div class="absolute top-0 right-0 z-10">
          <router-link
            :to="{ name: RouteName.CREATE_EVENT }"
            class="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg transition-colors duration-200"
          >
            <Plus :size="20" />
            {{ t("Publish") }}
          </router-link>
        </div>
        
        <!-- Slogan with space for button -->
        <h1 class="dark:text-white font-bold text-3xl md:text-4xl lg:text-5xl leading-tight pr-32">
          <span class="bg-blue-600 text-white px-3 py-1 rounded-lg">{{ t("Free") }}</span>
          <span class="ml-2">{{ restOfSlogan }}</span>
        </h1>
      </div>

      <!-- Description with max width -->
      <div class="max-w-3xl mx-auto">
        <p class="dark:text-white text-lg md:text-xl text-center leading-relaxed text-gray-600 dark:text-gray-300">
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
  return slogan.replace(/^(Free|Darmowe)\s*/, '').trim();
});
</script>
