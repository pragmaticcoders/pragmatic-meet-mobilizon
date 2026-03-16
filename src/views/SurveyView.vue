<template>
  <div class="max-w-screen-md mx-auto px-4 md:px-8 py-12">
    <h1 class="text-2xl font-bold text-gray-900 mb-4">
      Survey engine v.0.0.1
    </h1>
    <p class="text-gray-700">
      {{ currentDateTime }}
    </p>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";

const currentDateTime = computed(() =>
  new Date().toLocaleString(undefined, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  })
);
</script>
