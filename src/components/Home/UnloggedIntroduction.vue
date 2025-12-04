<template>
  <section class="container mx-auto mt-8 mb-12 lg:pl-[20%]">
    <div class="mx-auto">
      <!-- Header with slogan -->
      <div class="relative mb-6">
        <!-- Slogan -->
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
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { computed } from "vue";

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

/* Alternative lozenge - classic diamond shape */
.rhombus-bg-alt {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  clip-path: polygon(10% 0%, 90% 0%, 100% 50%, 90% 100%, 10% 100%, 0% 50%);
  position: relative;
  margin: 0 12px;
  box-shadow: 0 4px 8px rgba(37, 99, 235, 0.3);
  transition: all 0.3s ease;
}

.rhombus-bg-alt:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 12px rgba(37, 99, 235, 0.4);
}

/* Pure diamond lozenge - more geometric */
.lozenge-pure {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  clip-path: polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);
  transform: scaleX(1.3);
  margin: 0 16px;
  box-shadow: 0 3px 6px rgba(37, 99, 235, 0.3);
  transition: all 0.3s ease;
}

.lozenge-pure:hover {
  transform: scaleX(1.4) scale(1.05);
  box-shadow: 0 5px 10px rgba(37, 99, 235, 0.4);
}
</style>
