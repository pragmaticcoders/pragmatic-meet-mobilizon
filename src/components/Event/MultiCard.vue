<template>
  <div
    class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
  >
    <event-card
      class="flex flex-col h-full"
      v-for="event in events"
      :event="event"
      :key="event.uuid"
    />
  </div>
</template>
<script lang="ts" setup>
import { IEvent } from "@/types/event.model";

import EventCard from "./EventCard.vue";

defineProps<{
  events: IEvent[];
}>();
</script>
