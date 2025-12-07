<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16 mb-6">
    <div v-if="!isMobile" class="flex justify-between mb-4 header-container">
      <h1>
        {{ t("Calendar") }}
      </h1>

      <div class="filter-buttons">
        <button
          :class="['filter-btn', { active: eventFilter === 'my' }]"
          :disabled="!currentUser?.isLoggedIn"
          @click="eventFilter = 'my'"
        >
          {{ t("My events") }}
        </button>
        <button
          :class="['filter-btn', { active: eventFilter === 'all' }]"
          @click="eventFilter = 'all'"
        >
          {{ t("All events") }}
        </button>
      </div>
    </div>

    <h1 v-else>
      {{ t("Calendar") }}
    </h1>

    <div v-if="isMobile" class="filter-buttons-mobile mb-4">
      <button
        :class="['filter-btn', { active: eventFilter === 'my' }]"
        :disabled="!currentUser?.isLoggedIn"
        @click="eventFilter = 'my'"
      >
        {{ t("My events") }}
      </button>
      <button
        :class="['filter-btn', { active: eventFilter === 'all' }]"
        @click="eventFilter = 'all'"
      >
        {{ t("All events") }}
      </button>
    </div>

    <div>
      <EventsCalendar v-if="!isMobile" :filter="eventFilter" />
      <EventsAgenda v-else :filter="eventFilter" />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { ref, computed, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useQuery } from "@vue/apollo-composable";
import EventsAgenda from "@/components/FullCalendar/EventsAgenda.vue";
import EventsCalendar from "@/components/FullCalendar/EventsCalendar.vue";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";

const { t } = useI18n({ useScope: "global" });

const isMobile = window.innerWidth < 760;

// Get current user for authentication check
const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT, undefined, {
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
});

const currentUser = computed(() => currentUserResult.value?.currentUser);

// Filter state - start with 'my' as default, will adjust based on login status
const eventFilter = ref<"all" | "my">("my");

// Watch for currentUser to load and set default filter if not logged in
watch(
  currentUser,
  (user) => {
    if (user && !user.isLoggedIn && eventFilter.value === "my") {
      eventFilter.value = "all";
    }
  },
  { immediate: true }
);
</script>

<style scoped>
.header-container {
  align-items: flex-start;
}

.header-container h1 {
  margin-top: 0.67em;
  margin-bottom: 0.67em;
}

.filter-buttons {
  display: flex;
  gap: 0;
  margin-top: 2em;
  margin-bottom: 0.67em;
}

.filter-buttons-mobile {
  display: flex;
  gap: 0;
  width: 100%;
}

.filter-btn {
  background: #ffffff;
  border: 1px solid #d1d5db;
  color: #374151;
  font-weight: 500;
  padding: 6px 12px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
  border-radius: 0;
  min-height: 36px;
}

.filter-buttons-mobile .filter-btn {
  flex: 1;
  font-size: 12px;
  padding: 8px 10px;
  min-height: 44px;
}

@media (min-width: 768px) {
  .filter-buttons-mobile .filter-btn {
    font-size: 14px;
    padding: 6px 12px;
    min-height: auto;
  }
}

.filter-btn:first-child {
  border-top-left-radius: 4px;
  border-bottom-left-radius: 4px;
}

.filter-btn:last-child {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 4px;
  border-left: none;
}

.filter-btn:hover:not(:disabled) {
  background: #f3f4f6;
  border-color: #9ca3af;
}

.filter-btn.active:hover:not(:disabled) {
  background: #2563eb;
  border-color: #2563eb;
  color: #ffffff;
}

.filter-btn:focus {
  box-shadow: 0 0 0 2px #3b82f6;
  outline: none;
  z-index: 1;
}

.filter-btn.active {
  background: #3b82f6;
  border-color: #3b82f6;
  color: #ffffff;
  z-index: 1;
}

.filter-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #f9fafb;
  color: #9ca3af;
}
</style>
