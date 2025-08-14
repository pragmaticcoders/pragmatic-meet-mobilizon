<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16 mb-6">
    <h1 v-if="!isMobile">
      {{ t("Calendar") }}
    </h1>

    <div>
      <EventsCalendar v-if="!isMobile" />
      <EventsAgenda v-else />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import EventsAgenda from "@/components/FullCalendar/EventsAgenda.vue";
import EventsCalendar from "@/components/FullCalendar/EventsCalendar.vue";

const { t } = useI18n({ useScope: "global" });

const isMobile = window.innerWidth < 760;
</script>
