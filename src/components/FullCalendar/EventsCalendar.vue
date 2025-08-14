<template>
  <div class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
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
import { computed, ref } from "vue";
import { useLazyQuery } from "@vue/apollo-composable";
import { IEvent } from "@/types/event.model";
import { Paginate } from "@/types/paginate";
import { SEARCH_CALENDAR_EVENTS } from "@/graphql/search";
import FullCalendar from "@fullcalendar/vue3";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

const calendarRef = ref();

const { t } = useI18n({ useScope: "global" });

const { load: searchEventsLoad, refetch: searchEventsRefetch } = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_CALENDAR_EVENTS);

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

      const result =
        (await searchEventsLoad(undefined, queryVars)) ||
        (await searchEventsRefetch(queryVars))?.data;

      if (!result) {
        failureCallback("failed to fetch calendar events");
        return;
      }

      successCallback(
        (result.searchEvents.elements ?? []).map((event: IEvent) => {
          return {
            id: event.id,
            title: event.title,
            start: event.beginsOn,
            end: event.endsOn,
            startStr: event.beginsOn,
            endStr: event.endsOn,
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
    moreLinkClassNames: "bg-blue-600 text-white text-xs font-medium px-2 py-1 rounded",
    moreLinkContent: (arg: { num: number; text: string }) => {
      return "+" + arg.num.toString();
    },
    eventClassNames: "bg-blue-600 border-blue-600 text-white rounded text-xs",
    headerToolbar: {
      left: "prev,next today",
      center: "title",
      right: "dayGridMonth,dayGridWeek", // user can switch between the two
    },
    height: "auto",
    aspectRatio: 1.35,
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
    eventMouseEnter: function(info: any) {
      info.el.style.transform = "scale(1.02)";
      info.el.style.transition = "transform 0.2s ease";
      info.el.style.zIndex = "10";
    },
    eventMouseLeave: function(info: any) {
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
  padding: 16px;
  border-bottom: 1px solid #e5e7eb;
}

.fc-toolbar-title {
  font-size: 18px !important;
  font-weight: 600 !important;
  color: #111827 !important;
}

/* Button styling */
.fc-button {
  background: #ffffff !important;
  border: 1px solid #d1d5db !important;
  color: #374151 !important;
  font-weight: 500 !important;
  padding: 6px 12px !important;
  border-radius: 6px !important;
  font-size: 14px !important;
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
  padding: 8px !important;
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
  border-radius: 4px !important;
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
  border-radius: 8px !important;
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
  padding: 12px 8px !important;
}

.fc-col-header-cell-cushion {
  color: #6b7280 !important;
  font-weight: 600 !important;
  font-size: 14px !important;
  text-transform: uppercase !important;
  letter-spacing: 0.05em !important;
}

/* Remove dark mode overrides - using light theme only */
</style>
