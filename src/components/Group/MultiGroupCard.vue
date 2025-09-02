<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
    <group-card-figma v-for="group in groups" :group="group" :key="group.id" />
  </div>
</template>
<script lang="ts" setup>
import { IGroup } from "@/types/actor";
import GroupCardFigma from "./GroupCardFigma.vue";

defineProps<{
  groups: IGroup[];
}>();
</script>
