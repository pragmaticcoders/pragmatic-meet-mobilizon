<template>
  <span
    class="rounded-md truncate text-sm text-black px-2 py-1"
    :class="[
      typeClasses,
      capitalize,
      withHashTag ? `before:content-['#']` : '',
    ]"
  >
    <slot />
  </span>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    variant?: "info" | "danger" | "warning" | "light" | "primary";
    capitalize?: boolean;
    withHashTag?: boolean;
  }>(),
  { variant: "light", capitalize: false, withHashTag: false }
);

const typeClasses = computed(() => {
  switch (props.variant) {
    default:
    case "light":
      return "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-100";
    case "primary":
      return "bg-primary-100 text-primary-700 dark:bg-primary-700 dark:text-primary-100";
    case "info":
      return "bg-primary-100 text-primary-700 dark:bg-primary-700 dark:text-primary-100";
    case "warning":
      return "bg-warning-100 text-warning-700 dark:bg-warning-700 dark:text-warning-100";
    case "danger":
      return "bg-error-100 text-error-700 dark:bg-error-700 dark:text-error-100";
  }
});
</script>

<style lang="scss" scoped>
span.withHashTag::before {
  content: "#";
}
</style>
