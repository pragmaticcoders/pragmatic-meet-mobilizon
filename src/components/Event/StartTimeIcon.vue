<template>
  <div
    class="starttime-container flex items-center justify-center rounded-lg bg-white text-gray-700"
    :class="{ small }"
  >
    <div class="starttime-container-content flex items-center gap-2 font-bold">
      <Clock class="clock-icon" />
      <time :datetime="dateObj.toISOString()">{{ time }}</time>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { formatTimeString } from "@/filters/datetime";
import { computed } from "vue";

import Clock from "vue-material-design-icons/ClockTimeTenOutline.vue";

const props = withDefaults(
  defineProps<{
    date: string;
    timezone: string | null;
    small?: boolean;
  }>(),
  { small: false }
);

const dateObj = computed<Date>(() => new Date(props.date));

const time = computed<string>(() =>
  formatTimeString(props.date, props.timezone ?? undefined)
);
</script>

<style lang="scss" scoped>
div.starttime-container {
  width: auto;
  border: 1px solid var(--color-gray-200);
  box-shadow: var(--shadow-sm);
  padding: 8px;
  font-family: var(--font-family-primary);

  .starttime-container-content {
    font-size: 30px;
    font-weight: 700;
    line-height: 1.33;
    color: var(--color-gray-700);
  }

  &.small {
    .starttime-container-content {
      font-size: 24px;
    }
  }
}

.clock-icon {
  width: 24px;
  height: 24px;
  color: var(--color-gray-500);
}
</style>
