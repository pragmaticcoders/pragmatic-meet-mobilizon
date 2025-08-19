<template>
  <div class="flex flex-wrap gap-4 justify-between">
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
