<template>
  <close-content
    class="container mx-auto px-2"
    :suggestGeoloc="false"
    v-on="attrs"
  >
    <template #title>
      <div class="w-full">
        <div
          class="flex flex-col sm:flex-row gap-2 items-start sm:items-center mb-2"
        >
          <h2
            class="text-xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2"
          >
            <o-icon icon="map-marker-distance" customSize="24" />
            <span>{{ sectionTitle }}</span>
          </h2>
        </div>
        <p class="text-gray-600 dark:text-gray-300 text-base font-normal mb-4">
          {{ t("Select a location method to fetch local events") }}
        </p>
        <!-- Location Mode and Radius Dropdowns -->
        <div class="flex flex-col sm:flex-row gap-2">
          <!-- Location Mode Dropdown -->
          <o-dropdown
            v-model="locationMode"
            position="bottom-left"
            class="flex-shrink-0 location-mode-dropdown"
          >
            <template #trigger="{ active }">
              <o-button
                class="w-full sm:w-auto px-3 text-sm"
                style="height: 40px"
                :title="t('Select location source')"
                :icon-right="active ? 'menu-up' : 'menu-down'"
              >
                {{ locationModeText }}
              </o-button>
            </template>
            <o-dropdown-item
              value="profile"
              :label="profileLocationLabel"
              :disabled="!hasProfileLocation"
              class="dropdown-item-custom"
            />
            <o-dropdown-item
              value="last_searched"
              :label="lastSearchedLocationLabel"
              :disabled="!hasLastSearchedLocation"
              class="dropdown-item-custom"
            />
            <o-dropdown-item
              value="gps"
              :label="gpsLocationLabel"
              class="dropdown-item-custom"
            />
            <o-dropdown-item
              value="entire_poland"
              :label="t('Entire Poland')"
              class="dropdown-item-custom"
            />
            <o-dropdown-item
              value="online_only"
              :label="t('Online only')"
              class="dropdown-item-custom"
            />
          </o-dropdown>

          <!-- Radius Dropdown (only show for profile and last_searched) -->
          <o-dropdown
            v-if="showRadiusDropdown"
            v-model="radius"
            position="bottom-left"
            class="flex-shrink-0 radius-dropdown"
          >
            <template #trigger="{ active }">
              <o-button
                class="w-full sm:w-auto px-3 text-sm"
                style="height: 40px"
                :title="t('Select distance')"
                :icon-right="active ? 'menu-up' : 'menu-down'"
              >
                {{ radiusText }}
              </o-button>
            </template>
            <o-dropdown-item
              v-for="distance_item in distanceList"
              :value="distance_item.distance"
              :label="distance_item.label"
              :key="distance_item.distance"
              class="dropdown-item-custom"
            />
          </o-dropdown>
        </div>
      </div>
    </template>
    <template #subtitle>
      <empty-content
        v-if="!loading && events.total == 0"
        icon="map-marker-distance"
        inline
        center
        class="my-8"
      >
        {{ emptyStateMessage }}
        <template #desc>
          <p class="text-gray-600 dark:text-gray-300">
            {{ emptyStateDescription }}
          </p>
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
import { watch, computed, useAttrs, ref, onMounted, reactive } from "vue";
import { SEARCH_EVENTS } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { useQuery, useMutation } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import EmptyContent from "../Utils/EmptyContent.vue";
import { useI18n } from "vue-i18n";
import {
  coordsToGeoHash,
  getCloseEventsLocationMode,
  setCloseEventsLocationMode,
  getCloseEventsRadius,
  setCloseEventsRadius,
  getAddressFromLocal,
  addressToLocation,
} from "@/utils/location";
import { IAddress } from "@/types/address.model";
import { REVERSE_GEOCODE } from "@/graphql/address";
import { UPDATE_CURRENT_USER_LOCATION_CLIENT } from "@/graphql/location";

const props = defineProps<{
  userLocation: LocationType;
  doingGeoloc?: boolean;
  distance: number | null;
  userSettingsLocation?: LocationType;
}>();
defineEmits(["doGeoLoc"]);

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

// Location mode state
const locationMode = ref<string>(getCloseEventsLocationMode());
const radius = ref<number>(getCloseEventsRadius() || 25);

// GPS geolocation state
const gpsLocation = ref<{
  lat: number;
  lon: number;
  name?: string;
} | null>(null);
const isGettingGPSLocation = ref(false);

// Watch and save location mode changes
watch(locationMode, (newMode) => {
  setCloseEventsLocationMode(newMode);
});

// Watch and save radius changes
watch(radius, (newRadius) => {
  setCloseEventsRadius(newRadius);
});

// Compute profile location availability
const hasProfileLocation = computed(() => {
  console.log(
    "CloseEvents - userSettingsLocation:",
    props.userSettingsLocation
  );
  console.log(
    "CloseEvents - hasProfileLocation:",
    !!props.userSettingsLocation?.name
  );
  return !!props.userSettingsLocation?.name;
});

const profileLocationName = computed(() => {
  return props.userSettingsLocation?.name || "";
});

const profileLocationLabel = computed(() => {
  if (hasProfileLocation.value) {
    return t("Profile location: {location}", {
      location: profileLocationName.value,
    });
  }
  return t("Profile location") + ": " + t("Not set");
});

// Compute last searched location availability
const lastSearchedAddress = ref<IAddress | null>(null);

onMounted(() => {
  lastSearchedAddress.value = getAddressFromLocal();
});

const hasLastSearchedLocation = computed(() => {
  return !!lastSearchedAddress.value?.description;
});

const lastSearchedLocationName = computed(() => {
  return lastSearchedAddress.value?.description || "";
});

const lastSearchedLocationLabel = computed(() => {
  if (hasLastSearchedLocation.value) {
    return t("Last searched: {location}", {
      location: lastSearchedLocationName.value,
    });
  }
  return t("Last searched") + ": " + t("Not set");
});

// GPS location availability
const hasGPSLocation = computed(() => {
  return !!gpsLocation.value?.name;
});

const gpsLocationLabel = computed(() => {
  if (hasGPSLocation.value) {
    return t("GPS location: {location}", {
      location: gpsLocation.value?.name || "",
    });
  }
  return t("Use GPS location");
});

// Show radius dropdown only for profile, last_searched, and gps modes
const showRadiusDropdown = computed(() => {
  return (
    locationMode.value === "profile" ||
    locationMode.value === "last_searched" ||
    locationMode.value === "gps"
  );
});

// Location mode display text
const locationModeText = computed(() => {
  switch (locationMode.value) {
    case "profile":
      return hasProfileLocation.value
        ? profileLocationName.value
        : t("Profile location");
    case "last_searched":
      return hasLastSearchedLocation.value
        ? lastSearchedLocationName.value
        : t("Last searched");
    case "gps":
      return hasGPSLocation.value
        ? gpsLocation.value?.name || t("GPS location")
        : t("GPS location");
    case "online_only":
      return t("Online only");
    case "entire_poland":
    default:
      return t("Entire Poland");
  }
});

// Radius display text
const radiusText = computed(() => {
  return radius.value + " km";
});

// Distance list for dropdown
const distanceList = computed(() => {
  const distances: { distance: number; label: string }[] = [];
  [5, 10, 25, 50, 100, 150].forEach((value) => {
    distances.push({
      distance: value,
      label: t(
        "{number} kilometers",
        {
          number: value,
        },
        value
      ),
    });
  });
  return distances;
});

// GPS Geolocation functionality
const { mutate: saveCurrentUserLocation } = useMutation<any, LocationType>(
  UPDATE_CURRENT_USER_LOCATION_CLIENT
);

const reverseGeoCodeInformation = reactive<{
  latitude: number | undefined;
  longitude: number | undefined;
  accuracy: number | undefined;
}>({
  latitude: undefined,
  longitude: undefined,
  accuracy: undefined,
});

const { onResult: onReverseGeocodeResult } = useQuery<{
  reverseGeocode: IAddress[];
}>(REVERSE_GEOCODE, reverseGeoCodeInformation, () => ({
  enabled: reverseGeoCodeInformation.latitude !== undefined,
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
}));

onReverseGeocodeResult((result) => {
  if (!result?.data) return;
  const geoLocationInformation = result?.data?.reverseGeocode[0];
  const placeName =
    geoLocationInformation.locality ??
    geoLocationInformation.region ??
    geoLocationInformation.country;

  // Save to GPS location state
  gpsLocation.value = {
    lat: reverseGeoCodeInformation.latitude!,
    lon: reverseGeoCodeInformation.longitude!,
    name: placeName,
  };

  // Also save to Apollo cache
  saveCurrentUserLocation({
    lat: reverseGeoCodeInformation.latitude,
    lon: reverseGeoCodeInformation.longitude,
    accuracy: Math.round(reverseGeoCodeInformation.accuracy ?? 12) / 1000,
    isIPLocation: false,
    name: placeName,
    picture: geoLocationInformation.pictureInfo,
  });

  isGettingGPSLocation.value = false;
});

const fetchAndSaveCurrentLocationName = async ({
  coords: { latitude, longitude, accuracy },
}: GeolocationPosition) => {
  reverseGeoCodeInformation.latitude = latitude;
  reverseGeoCodeInformation.longitude = longitude;
  reverseGeoCodeInformation.accuracy = accuracy;
};

const performGeoLocation = () => {
  isGettingGPSLocation.value = true;
  navigator.geolocation.getCurrentPosition(
    fetchAndSaveCurrentLocationName,
    (error) => {
      console.error("Geolocation error:", error);
      isGettingGPSLocation.value = false;
    }
  );
};

// Watch for GPS location mode selection
watch(locationMode, (newMode) => {
  if (newMode === "gps" && !gpsLocation.value) {
    performGeoLocation();
  }
});

// Compute the geohash based on selected location mode
const geoHash = computed(() => {
  switch (locationMode.value) {
    case "profile":
      if (props.userSettingsLocation?.lat && props.userSettingsLocation?.lon) {
        return coordsToGeoHash(
          props.userSettingsLocation.lat,
          props.userSettingsLocation.lon
        );
      }
      return undefined;
    case "last_searched":
      if (lastSearchedAddress.value) {
        const location = addressToLocation(lastSearchedAddress.value);
        if (location?.lat && location?.lon) {
          return coordsToGeoHash(location.lat, location.lon);
        }
      }
      return undefined;
    case "gps":
      if (gpsLocation.value?.lat && gpsLocation.value?.lon) {
        return coordsToGeoHash(gpsLocation.value.lat, gpsLocation.value.lon);
      }
      return undefined;
    case "entire_poland":
    case "online_only":
    default:
      return undefined;
  }
});

// Section title based on location mode
const sectionTitle = computed(() => {
  if (locationMode.value === "online_only") {
    return t("Online upcoming events");
  }
  if (geoHash.value && locationModeText.value) {
    return t("Upcoming events nearby {position}", {
      position: locationModeText.value,
    });
  }
  return t("Upcoming events");
});

// Empty state message
const emptyStateMessage = computed(() => {
  if (locationMode.value === "online_only") {
    return t("No online events at this time.");
  }
  if (geoHash.value) {
    return t("No upcoming events in the selected location at this time.");
  }
  return t("No upcoming events in the selected location at this time.");
});

// Empty state description
const emptyStateDescription = computed(() => {
  return t("Events from the selected location will appear here");
});

// Events query with dynamic parameters based on location mode
const eventsQuery = useQuery<{
  searchEvents: Paginate<IEvent>;
}>(
  SEARCH_EVENTS,
  () => {
    const params: any = {
      longEvents: false,
      limit: 93,
    };

    switch (locationMode.value) {
      case "profile":
      case "last_searched":
      case "gps":
        if (geoHash.value) {
          params.location = geoHash.value;
          params.radius = radius.value;
        }
        break;
      case "online_only":
        params.type = "ONLINE";
        break;
      case "entire_poland":
      default:
        // No location or type filter - shows all events
        break;
    }

    return params;
  },
  {
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: false,
  }
);

const events = computed(
  () => eventsQuery.result.value?.searchEvents ?? { elements: [], total: 0 }
);

const loading = computed(
  () =>
    props.doingGeoloc || eventsQuery.loading.value || isGettingGPSLocation.value
);
</script>

<style scoped>
/* Make dropdown items match the radius dropdown styling */
:deep(.location-mode-dropdown .o-drop__item),
:deep(.radius-dropdown .o-drop__item),
:deep(.dropdown-item-custom) {
  font-weight: normal !important;
  font-size: 16px !important;
  min-width: max-content !important;
}

:deep(.location-mode-dropdown .o-drop__item--disabled),
:deep(.radius-dropdown .o-drop__item--disabled),
:deep(.dropdown-item-custom[disabled]) {
  opacity: 0.5 !important;
  cursor: not-allowed !important;
}

:deep(.location-mode-dropdown .o-drop__item .o-drop__item-label),
:deep(.radius-dropdown .o-drop__item .o-drop__item-label) {
  font-weight: normal !important;
}
</style>
