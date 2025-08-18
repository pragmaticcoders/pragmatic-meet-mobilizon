<template>
  <li class="pb-5 border-b border-[#cac9cb] last:border-b-0">
    <router-link
      class="text-[20px] font-bold leading-[30px] text-[#1c1b1f] dark:text-white block mb-5 no-underline"
      v-if="to"
      :to="to"
      >{{ title }}</router-link
    >
    <b
      v-else
      class="text-[20px] leading-[30px] text-[#1c1b1f] dark:text-white block mb-5"
      >{{ title }}</b
    >
    <ul class="flex flex-col">
      <slot></slot>
    </ul>
  </li>
</template>
<script lang="ts" setup>
defineProps<{
  title?: string;
  to: { name: string; params?: Record<string, any> };
}>();

// const route = useRoute();
// const slots = useSlots();

// const sectionActive = computed((): boolean => {
//   if (slots.default) {
//     return slots.default.some(
//       ({
//         componentOptions: {
//           propsData: { to },
//         },
//       }) => to && to.name === route.name
//     );
//   }
//   return false;
// });
</script>
