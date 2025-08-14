<template>
  <div class="multi-card-group">
    <group-card
      class="group-card"
      v-for="group in groups"
      :group="group"
      :key="group.id"
    />
  </div>
</template>
<script lang="ts" setup>
import { IGroup } from "@/types/actor";
import GroupCard from "./GroupCard.vue";

defineProps<{
  groups: IGroup[];
}>();
</script>
<style lang="scss" scoped>
.multi-card-group {
  display: grid;
  grid-auto-rows: 1fr;
  grid-column-gap: 24px;
  grid-row-gap: 24px;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  
  @media (max-width: 640px) {
    grid-template-columns: 1fr;
    grid-column-gap: 16px;
    grid-row-gap: 16px;
  }
  
  @media (min-width: 641px) and (max-width: 1024px) {
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  }
}

:deep(.group-card) {
  height: 100%;
  min-height: 200px;
}
</style>
