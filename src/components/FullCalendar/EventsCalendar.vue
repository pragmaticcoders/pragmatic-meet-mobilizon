<template>
  <div
    class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden"
  >
    <FullCalendar ref="calendarRef" :options="calendarOptions">
      <template v-slot:eventContent="arg">
        <div
          class="text-white text-xs font-medium py-1 truncate"
          :title="arg.event.title"
        >
          {{ arg.event.title }}
        </div>
      </template>
    </FullCalendar>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { locale } from "@/utils/i18n";
import { computed, ref, onMounted, onUnmounted } from "vue";
import { useLazyQuery } from "@vue/apollo-composable";
import { IEvent } from "@/types/event.model";
import { Paginate } from "@/types/paginate";
import { SEARCH_CALENDAR_EVENTS } from "@/graphql/search";
import FullCalendar from "@fullcalendar/vue3";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

const calendarRef = ref();

const { t } = useI18n({ useScope: "global" });

// Flag to force fresh data on next load
const forceRefresh = ref(false);

const { load: searchEventsLoad, refetch: searchEventsRefetch } = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_CALENDAR_EVENTS, undefined, () => ({
  fetchPolicy: forceRefresh.value ? 'network-only' : 'cache-first'
}));

// Expose refresh method for external components to trigger calendar refresh
const refreshCalendar = () => {
  if (calendarRef.value) {
    forceRefresh.value = true; // Set flag to force fresh data
    const calendarApi = calendarRef.value.getApi();
    calendarApi.refetchEvents();
  }
};

// Listen for global calendar refresh events
onMounted(() => {
  window.addEventListener('calendar-refresh', refreshCalendar);
  
  // Check if we need to force refresh due to recent event updates
  const lastEventUpdate = localStorage.getItem('lastEventUpdate');
  const lastCalendarRefresh = localStorage.getItem('lastCalendarRefresh');
  
  if (lastEventUpdate && (!lastCalendarRefresh || parseInt(lastEventUpdate) > parseInt(lastCalendarRefresh))) {
    console.log('Calendar: Detected recent event update, forcing refresh');
    forceRefresh.value = true;
    localStorage.setItem('lastCalendarRefresh', Date.now().toString());
  }
});

// Cleanup event listener on unmount
onUnmounted(() => {
  window.removeEventListener('calendar-refresh', refreshCalendar);
});

const calendarOptions = computed((): object => {
  return {
    plugins: [dayGridPlugin, interactionPlugin],
    initialView: "dayGridMonth",
    events: async (
      info: { start: Date; end: Date; startStr: string; endStr: string },
      successCallback: (arg: object[]) => unknown,
      failureCallback: (err: string) => unknown
    ) => {
      const queryVars = {
        limit: 999,
        beginsOn: info.start,
        endsOn: info.end,
      };

      let result;
      if (forceRefresh.value) {
        // Force fresh data from server, bypassing cache completely
        console.log('Calendar: Forcing fresh data fetch for', queryVars);
        result = (await searchEventsRefetch(queryVars))?.data;
        forceRefresh.value = false; // Reset flag after refresh
        console.log('Calendar: Fresh data fetched, events:', result?.searchEvents?.elements?.length);
      } else {
        // Normal flow with cache
        result =
          (await searchEventsLoad(undefined, queryVars)) ||
          (await searchEventsRefetch(queryVars))?.data;
      }

      if (!result) {
        failureCallback("failed to fetch calendar events");
        return;
      }

      successCallback(
        (result.searchEvents.elements ?? []).map((event: IEvent) => {
          // Fix FullCalendar exclusive end date issue
          let adjustedEndDate = event.endsOn;
          
          if (event.endsOn && event.beginsOn) {
            const startDate = new Date(event.beginsOn);
            const endDate = new Date(event.endsOn);
            
            // Check if event spans multiple days by comparing dates only (not times)
            const startDay = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
            const endDay = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
            
            if (endDay.getTime() > startDay.getTime()) {
              // Multi-day event: Add 1 day to end date for FullCalendar (which treats end dates as exclusive)
              const adjustedEnd = new Date(endDate);
              adjustedEnd.setDate(adjustedEnd.getDate() + 1);
              adjustedEndDate = adjustedEnd.toISOString();
            }
          }
          
          return {
            id: event.id,
            title: event.title,
            start: event.beginsOn,
            end: adjustedEndDate,
            startStr: event.beginsOn,
            endStr: adjustedEndDate,
            url: `/events/${event.uuid}`,
            extendedProps: {
              event: event,
            },
          };
        })
      );
    },
    nextDayThreshold: "09:00:00",
    dayMaxEventRows: 5,
    moreLinkClassNames:
      "bg-blue-600 text-white text-xs font-medium px-2 py-1 rounded",
    moreLinkContent: (arg: { num: number; text: string }) => {
      return "+" + arg.num.toString();
    },
    eventClassNames: "bg-blue-600 border-blue-600 text-white rounded text-xs",
    headerToolbar: {
      left: "prev,next",
      center: "title",
      right: "today dayGridMonth,dayGridWeek", // user can switch between the two
    },
    height: "auto",
    aspectRatio: window.innerWidth < 768 ? 0.8 : 1.35,
    locale: locale,
    firstDay: 1,
    buttonText: {
      today: t("Today"),
      month: t("Month"),
      week: t("Week"),
      day: t("Day"),
      list: t("List"),
    },
    eventDisplay: "block",
    eventMouseEnter: function (info: any) {
      info.el.style.transform = "scale(1.02)";
      info.el.style.transition = "transform 0.2s ease";
      info.el.style.zIndex = "10";
    },
    eventMouseLeave: function (info: any) {
      info.el.style.transform = "scale(1)";
      info.el.style.zIndex = "auto";
    },
  };
});
</script>

<style>
/* Calendar container styling */
.fc {
  font-family: inherit;
}

/* Header styling */
.fc-toolbar {
  background: #f9fafb;
  padding: 8px 12px;
  border-bottom: 1px solid #e5e7eb;
  flex-wrap: wrap;
  gap: 8px;
}

@media (min-width: 768px) {
  .fc-toolbar {
    padding: 16px;
    flex-wrap: nowrap;
  }
}

.fc-toolbar-title {
  font-size: 16px !important;
  font-weight: 600 !important;
  color: #111827 !important;
}

@media (min-width: 768px) {
  .fc-toolbar-title {
    font-size: 18px !important;
  }
}

/* Button styling */
.fc-button {
  background: #ffffff !important;
  border: 1px solid #d1d5db !important;
  color: #374151 !important;
  font-weight: 500 !important;
  padding: 8px 10px !important;
  font-size: 12px !important;
  min-height: 44px !important;
  min-width: 44px !important;
}

@media (min-width: 768px) {
  .fc-button {
    padding: 6px 12px !important;
    font-size: 14px !important;
    min-height: auto !important;
    min-width: auto !important;
  }
}

.fc-button:hover {
  background: #f3f4f6 !important;
  border-color: #9ca3af !important;
}

.fc-button:focus {
  box-shadow: 0 0 0 2px #3b82f6 !important;
  outline: none !important;
}

.fc-button-active,
.fc-button-active:hover {
  background: #3b82f6 !important;
  border-color: #3b82f6 !important;
  color: #ffffff !important;
}

/* Calendar grid styling */
.fc-daygrid-day {
  border-color: #e5e7eb !important;
}

.fc-daygrid-day-number {
  color: #374151 !important;
  font-weight: 500 !important;
  padding: 4px !important;
  font-size: 14px !important;
}

@media (min-width: 768px) {
  .fc-daygrid-day-number {
    padding: 8px !important;
    font-size: 16px !important;
  }
}

.fc-day-today {
  background: #eff6ff !important;
}

.fc-day-today .fc-daygrid-day-number {
  color: #3b82f6 !important;
  font-weight: 600 !important;
}

/* Event styling */
.fc-event {
  border: none !important;
  font-size: 12px !important;
  padding: 2px 6px !important;
  margin: 1px 2px !important;
}

.fc-event-title {
  color: #ffffff !important;
  font-weight: 500 !important;
}

/* More link styling */
.fc-more-link {
  color: #3b82f6 !important;
  font-size: 12px !important;
  font-weight: 500 !important;
}

/* Popover styling */
.fc-popover {
  background: #ffffff !important;
  border: 1px solid #e5e7eb !important;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1) !important;
}

.fc-popover-header {
  background: #f9fafb !important;
  color: #111827 !important;
  font-weight: 600 !important;
  border-bottom: 1px solid #e5e7eb !important;
  padding: 12px 16px !important;
}

.fc-popover-body {
  padding: 8px !important;
}

/* Day header styling */
.fc-col-header-cell {
  background: #f9fafb !important;
  border-color: #e5e7eb !important;
  padding: 8px 4px !important;
}

@media (min-width: 768px) {
  .fc-col-header-cell {
    padding: 12px 8px !important;
  }
}

.fc-col-header-cell-cushion {
  color: #6b7280 !important;
  font-weight: 600 !important;
  font-size: 12px !important;
  text-transform: uppercase !important;
  letter-spacing: 0.05em !important;
}

@media (min-width: 768px) {
  .fc-col-header-cell-cushion {
    font-size: 14px !important;
  }
}

/* Remove dark mode overrides - using light theme only */
</style>
