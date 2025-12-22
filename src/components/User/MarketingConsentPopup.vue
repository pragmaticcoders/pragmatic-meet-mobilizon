<template>
  <div class="bg-white p-6 w-full max-w-xl rounded-lg">
    <h2 class="text-xl font-bold text-gray-900 mb-4">
      {{ t("Unlock knowledge expansion opportunities with Pragmatic Coders materials") }}
    </h2>

    <section class="mb-6">
      <p class="text-gray-700 text-sm leading-relaxed">
        {{ t("I consent to receiving messages, updates, and promotional emails from Pragmatic Coders based on my data. Consent can be withdrawn at any time.") }}
      </p>
    </section>

    <footer class="flex justify-end gap-3">
      <o-button
        variant="text"
        @click="handleOptOut"
        :disabled="isLoading"
        class="px-6 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 font-medium"
      >
        {{ t("No, opt-me out") }}
      </o-button>
      <o-button
        variant="primary"
        @click="handleAgree"
        :disabled="isLoading"
        class="px-6 py-2 font-medium text-white bg-blue-600 hover:bg-blue-700"
      >
        {{ t("Yes, I agree") }}
      </o-button>
    </footer>
  </div>
</template>

<script lang="ts" setup>
import { ref } from "vue";
import { useI18n } from "vue-i18n";

const emit = defineEmits<{
  (e: "consent", value: boolean): void;
}>();

const { t } = useI18n({ useScope: "global" });

const isLoading = ref(false);

const handleAgree = () => {
  isLoading.value = true;
  emit("consent", true);
};

const handleOptOut = () => {
  isLoading.value = true;
  emit("consent", false);
};
</script>

