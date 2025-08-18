<template>
  <li
    class="w-full"
    :class="{
      'bg-[#e8effd]': isActive,
      'bg-white hover:bg-gray-50 dark:bg-gray-800 dark:hover:bg-gray-700':
        !isActive,
    }"
  >
    <router-link
      v-if="to"
      :to="to"
      class="flex items-center px-3 py-2 w-full no-underline"
    >
      <span
        class="font-small text-[17px] leading-[26px] truncate"
        :class="{
          'text-[#155eef]': isActive,
          'text-[#1c1b1f] dark:text-white': !isActive,
        }"
        >{{ title }}</span
      >
    </router-link>
    <span
      v-else
      class="flex items-center px-3 py-2 w-full font-medium text-[17px] leading-[26px] text-[#1c1b1f] dark:text-white"
      >{{ title }}</span
    >
  </li>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";

const props = defineProps<{
  title?: string;
  to: { name: string; params?: Record<string, any> };
}>();

const route = useRoute();

const isActive = computed((): boolean => {
  if (props.to.name === route.name) {
    if (props.to.params) {
      return props.to.params.identityName === route.params.identityName;
    }
    return true;
  }
  return false;
});
</script>
