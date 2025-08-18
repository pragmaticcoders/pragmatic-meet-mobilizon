<template>
  <div class="flex justify-center" style="height: 284px; overflow: hidden">
    <lazy-image-wrapper :picture="picture" />
  </div>
</template>
<script lang="ts" setup>
import { IMedia } from "@/types/media.model";
import LazyImageWrapper from "../Image/LazyImageWrapper.vue";

withDefaults(
  defineProps<{
    picture: IMedia | null;
  }>(),
  { picture: null }
);
</script>
