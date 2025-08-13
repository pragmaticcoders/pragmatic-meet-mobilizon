<template>
  <div style="margin-bottom: 20px;">
    <h2 class="text-gray-700" style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary); margin-bottom: 8px;">{{ title }}</h2>
    <div class="flex items-center eventMetadataBlock" style="gap: 12px;">
      <slot name="icon"></slot>
      <div class="content-wrapper overflow-hidden w-full" style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
        <slot></slot>
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
defineProps<{
  title: string;
}>();
</script>
<style lang="scss" scoped>
div.eventMetadataBlock {
  .content-wrapper {
    max-width: calc(100vw - 32px - 20px);

    &.padding-left {
      padding: 0 20px;

      a {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }
  }
}
</style>
