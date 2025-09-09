<template>
  <close-content
    class="container mx-auto px-2"
    :suggestGeoloc="false"
    v-on="attrs"
  >
    <template #title>
      <template v-if="userLocation?.name">
        {{
          t("Upcoming events nearby {position}", {
            position: userLocation?.name,
          })
        }}
      </template>
      <template v-else>
        {{ t("Upcoming events") }}
      </template>
    </template>
    <template #subtitle>
      <empty-content
        v-if="!loading && events.total == 0"
        icon="calendar"
        inline
        center
        class="my-8"
      >
        <template v-if="userLocation?.name">
          {{
            t(
              "No events found nearby {position}. Try removing your position to see all events!",
              { position: userLocation?.name }
            )
          }}
        </template>
        <template v-else>
          {{ t("No upcoming events at this time.") }}
        </template>
      </empty-content>
    </template>
    <template #content>
      <skeleton-event-result
        v-for="i in 6"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loading"
      />
      <event-card
        v-for="event in events.elements"
        :event="event"
        :key="event.uuid"
      />
    </template>
  </close-content>
</template>

<script lang="ts" setup>
import { LocationType } from "../../types/user-location.model";
import CloseContent from "./CloseContent.vue";
import { watch, computed, useAttrs } from "vue";
import { FETCH_EVENTS } from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import { useQuery } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import EmptyContent from "../Utils/EmptyContent.vue";
import { useI18n } from "vue-i18n";
import { coordsToGeoHash } from "@/utils/location";
import { EventSortField, SortDirection } from "@/types/enums";

const props = defineProps<{
  userLocation: LocationType;
  doingGeoloc?: boolean;
  distance: number | null;
}>();
defineEmits(["doGeoLoc"]);

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const userLocation = computed(() => props.userLocation);

const geoHash = computed(() => {
  console.debug("userLocation updated", userLocation.value);
  const geo = coordsToGeoHash(userLocation.value.lat, userLocation.value.lon);
  console.debug("geohash:", geo);
  return geo;
});

const distance = computed<number>(() => {
  return props.distance ?? 25;
});

const eventsQuery = useQuery<{
  searchEvents: Paginate<IEvent>;
}>(FETCH_EVENTS, () => ({
  orderBy: EventSortField.BEGINS_ON,
  direction: SortDirection.ASC,
  longEvents: false,
  location: geoHash.value ?? "",
  radius: distance.value,
  limit: 93,
}));

const events = computed(
  () => eventsQuery.result.value?.searchEvents ?? { elements: [], total: 0 }
);
watch(events, (e) => console.debug("events: ", e));

const loading = computed(() => props.doingGeoloc || eventsQuery.loading.value);
watch(loading, (l) => console.debug("loading: ", l));
</script>
