<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <!-- Unlogged introduction - only show when user is not logged in -->
    <unlogged-introduction v-if="!currentUser?.id" :config="config" />

    <!-- Logged-in search bar - only show when user is logged in -->
    <logged-search-bar v-if="currentUser?.id" />

    <!-- Welcome back -->
    <section
      class="mx-auto px-16 py-8 text-center max-w-[600px]"
      v-if="currentActor?.id && (welcomeBack || newRegisteredUser)"
    >
      <div
        class="font-bold text-4xl leading-[48px] text-gray-900"
        v-if="welcomeBack"
      >
        <span class="text-[#155eef]">{{
          t("Welcome back {username}!", {
            username: displayName(currentActor),
          })
        }}</span>
      </div>
      <div
        class="font-bold text-4xl leading-[48px] text-gray-900"
        v-if="newRegisteredUser"
      >
        <span class="text-[#155eef]">{{
          t("Welcome to Pragmatic Meet, {username}!", {
            username: displayName(currentActor),
          })
        }}</span>
      </div>
    </section>
    <!-- Your upcoming events - only show if user has events -->
    <section v-if="currentUser?.id && canShowMyUpcomingEvents" class="mx-auto mb-8 mt-4">
      <h2 class="text-2xl font-bold text-gray-900 mb-6">
        {{ t("Your upcoming events") }}
      </h2>
      <div v-if="canShowMyUpcomingEvents">
        <div
          v-for="row of goingToEvents"
          class="text-gray-700 mb-4"
          :key="row[0]"
        >
        <p
          class="date-component-container"
          v-if="isInLessThanSevenDays(row[0])"
        >
          <span v-if="isToday(row[0])">{{
            t(
              "You have one event today.",
              {
                count: row[1].size,
              },
              row[1].size
            )
          }}</span>
          <span v-else-if="isTomorrow(row[0])">{{
            t(
              "You have one event tomorrow.",
              {
                count: row[1].size,
              },
              row[1].size
            )
          }}</span>
          <span v-else-if="isInLessThanSevenDays(row[0])">
            {{
              t(
                "You have one event in {days} days.",
                {
                  count: row[1].size,
                  days: calculateDiffDays(row[0]),
                },
                row[1].size
              )
            }}
          </span>
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <event-participation-card
            v-for="participation in thisWeek(row)"
            :key="participation[1].id"
            :participation="participation[1]"
          />
        </div>
      </div>
        <div class="text-right mt-6">
          <router-link
            :to="{ name: RouteName.MY_EVENTS }"
            class="text-blue-600 hover:text-blue-700 font-medium"
            >{{ t("View everything") }} →</router-link
          >
        </div>
      </div>
      
      <!-- Empty state for upcoming events -->
      <empty-content v-else icon="calendar" inline center class="my-8">
        {{ t("No upcoming events") }}
        <template #desc>
          <p class="text-gray-600 dark:text-gray-300">
            {{ t("You don't have any upcoming events at the moment") }}
          </p>
        </template>
      </empty-content>
    </section>
    <!-- Events from your followed groups - only show if there are events -->
    <section class="mx-auto mb-8" v-if="currentUser?.id && canShowFollowedGroupEvents">
      <h2 class="text-xl font-bold text-gray-900 mb-2">
        {{ t("Upcoming events from your groups") }}
      </h2>
      <p class="text-gray-600 mb-6">
        {{ t("That you follow or of which you are a member") }}
      </p>
      
      <div v-if="canShowFollowedGroupEvents">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <event-participation-card
            v-for="event in filteredFollowedGroupsEvents"
            :key="event.id"
            :participation="createMockParticipation(event)"
          />
        </div>
        <div class="text-right mt-6">
          <router-link
            class="text-blue-600 hover:text-blue-700 font-medium"
            :to="{
              name: RouteName.MY_EVENTS,
              query: {
                showUpcoming: 'true',
                showDrafts: 'false',
                showAttending: 'false',
                showMyGroups: 'true',
              },
            }"
            >{{ t("View everything") }} →</router-link
          >
        </div>
      </div>
      
      <!-- Empty state for group events -->
      <empty-content v-else icon="calendar-account" inline center class="my-8">
        {{ t("No events from your groups") }}
        <template #desc>
          <p class="text-gray-600 dark:text-gray-300">
            {{ t("Events from groups you follow will appear here") }}
          </p>
        </template>
      </empty-content>
    </section>

    <!-- Public events - only show if there are events -->
    <section class="mx-auto mb-8" v-if="canShowPublicEvents">
      <h2 class="text-xl font-bold text-gray-900 mb-2">
        {{ currentUser?.id ? t("More upcoming events") : t("Upcoming events") }}
      </h2>
      <p class="text-gray-600 mb-6">
        {{ t("Discover interesting events happening near you") }}
      </p>
      
      <div v-if="canShowPublicEvents">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <event-participation-card
            v-for="event in displayedPublicEvents"
            :key="event.id"
            :participation="createMockParticipation(event)"
          />
        </div>
        <div class="text-right mt-6">
          <router-link
            class="text-blue-600 hover:text-blue-700 font-medium"
            :to="{ name: RouteName.SEARCH }"
            >{{ t("View everything") }} →</router-link
          >
        </div>
      </div>
      
      <!-- Empty state for public events -->
      <empty-content v-else icon="calendar-blank" inline center class="my-8">
        {{ t("No public events available") }}
        <template #desc>
          <p class="text-gray-600 dark:text-gray-300">
            {{ t("Check back later for upcoming events") }}
          </p>
        </template>
      </empty-content>
    </section>

    <!-- Groups section - only show if there are groups -->
    <section class="mx-auto mb-8" v-if="canShowUserGroups">
      <h2 class="text-xl font-bold text-gray-900 mb-2">
        {{ groupsSectionTitle }}
      </h2>
      <p class="text-gray-600 mb-6">{{ groupsSectionDescription }}</p>

      <!-- Groups content -->
      <div v-if="canShowUserGroups">
        <MultiGroupCard :groups="displayedGroups" />
        <div class="text-right mt-6">
          <router-link
            class="text-blue-600 hover:text-blue-700 font-medium"
            :to="{
              name: RouteName.SEARCH,
              query: { contentType: 'GROUPS', groupPage: '1' },
            }"
            >{{ t("View everything") }} →</router-link
          >
        </div>
      </div>

      <!-- Empty state for groups -->
      <empty-content v-else icon="account-group" inline center class="my-8">
        <template v-if="currentUser?.id">
          {{ t("No groups yet") }}
        </template>
        <template v-else>
          {{ t("No groups available") }}
        </template>
        <template #desc>
          <p class="text-gray-600 dark:text-gray-300">
            <template v-if="currentUser?.id">
              {{ t("Join groups to connect with like-minded people") }}
            </template>
            <template v-else>
              {{ t("Sign up to discover and join groups") }}
            </template>
          </p>
        </template>
      </empty-content>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "../types/participant.model";
import MultiGroupCard from "../components/Group/MultiGroupCard.vue";
import EmptyContent from "../components/Utils/EmptyContent.vue";
import {
  CURRENT_ACTOR_CLIENT,
  LOGGED_USER_MEMBERSHIPS,
} from "../graphql/actor";
import { IPerson, displayName, IGroup } from "../types/actor";
import { ICurrentUser, IUser } from "../types/current-user.model";
import { CURRENT_USER_CLIENT } from "../graphql/user";
import { HOME_USER_QUERIES } from "../graphql/home";
import { IMember } from "../types/actor/member.model";
import { SEARCH_GROUPS, SEARCH_EVENTS } from "../graphql/search";
import RouteName from "../router/name";
import { IEvent } from "../types/event.model";
import {
  computed,
  onMounted,
  reactive,
  ref,
  watch,
  defineAsyncComponent,
} from "vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { REVERSE_GEOCODE } from "@/graphql/address";
import { IAddress } from "@/types/address.model";
import {
  CURRENT_USER_LOCATION_CLIENT,
  UPDATE_CURRENT_USER_LOCATION_CLIENT,
} from "@/graphql/location";
import { LocationType } from "@/types/user-location.model";
import UnloggedIntroduction from "@/components/Home/UnloggedIntroduction.vue";
import LoggedSearchBar from "@/components/Home/LoggedSearchBar.vue";
import { useHead } from "@unhead/vue";
import {
  addressToLocation,
  geoHashToCoords,
  getAddressFromLocal,
} from "@/utils/location";
import { useServerProvidedLocation } from "@/composition/apollo/config";
import { ABOUT } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

const EventParticipationCard = defineAsyncComponent(
  () => import("@/components/Event/EventParticipationCard.vue")
);

const { result: aboutConfigResult } = useQuery<{
  config: Pick<
    IConfig,
    "name" | "description" | "slogan" | "registrationsOpen"
  >;
}>(ABOUT, undefined, {
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
});

const config = computed(() => aboutConfigResult.value?.config);

const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT,
  undefined,
  { fetchPolicy: "cache-and-network", notifyOnNetworkStatusChange: false }
);
const currentActor = computed<IPerson | undefined>(
  () => currentActorResult.value?.currentActor
);

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT, undefined, {
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
});

const currentUser = computed(() => currentUserResult.value?.currentUser);

const instanceName = computed(() => config.value?.name);

// Get start of today to include all of today's events
const todayStart = new Date();
todayStart.setHours(0, 0, 0, 0);

const { result: userResult } = useQuery<{ loggedUser: IUser }>(
  HOME_USER_QUERIES,
  { afterDateTime: todayStart.toISOString() },
  () => ({
    enabled: currentUser.value?.id != undefined,
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: false,
  })
);

const loggedUser = computed(() => userResult.value?.loggedUser);
const followedGroupEvents = computed(
  () => userResult.value?.loggedUser?.followedGroupEvents
);

// Fetch user's group memberships (when logged in)
const { result: userMembershipsResult } = useQuery<{
  loggedUser: { memberships: { elements: IMember[] } };
}>(LOGGED_USER_MEMBERSHIPS, { limit: 6 }, () => ({
  enabled: currentUser.value?.id != undefined,
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
}));

// Note: SEARCH_GROUPS query and displayedGroups moved below userLocation definition to avoid initialization error

const currentUserParticipations = computed(
  () => loggedUser.value?.participations.elements
);

const address = ref<IAddress | null>(null);
const noAddress = ref(false);
const current_distance = ref<number | null>(null);

const isToday = (date: string): boolean => {
  return new Date(date).toDateString() === new Date().toDateString();
};

const isTomorrow = (date: string): boolean => {
  return isInDays(date, 1);
};

const isInDays = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) === nbDays;
};

const isBefore = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) < nbDays;
};

const isInLessThanSevenDays = (date: string): boolean => {
  return isBefore(date, 7);
};

const thisWeek = (
  row: [string, Map<string, IParticipant>]
): Map<string, IParticipant> => {
  if (isInLessThanSevenDays(row[0])) {
    return row[1];
  }
  return new Map();
};

const calculateDiffDays = (date: string): number => {
  return Math.ceil(
    (new Date(date).getTime() - new Date().getTime()) / 1000 / 60 / 60 / 24
  );
};

const thisWeekGoingToEvents = computed<IParticipant[]>(() => {
  const allParticipations = currentUserParticipations.value || [];

  const res = allParticipations.filter(({ event, role }) => {
    if (!event.beginsOn || role === ParticipantRole.REJECTED) {
      return false;
    }

    const diffDays = calculateDiffDays(event.beginsOn);

    // Include events that are today or in the future (up to 30 days)
    // For today's events, even if the time has passed, we still want to show them
    const isUpcoming = diffDays >= 0 && diffDays < 30;

    return isToday(event.beginsOn) || isUpcoming;
  });
  res.sort(
    (a: IParticipant, b: IParticipant) =>
      new Date(a.event.beginsOn).getTime() -
      new Date(b.event.beginsOn).getTime()
  );
  return res;
});

const goingToEvents = computed<Map<string, Map<string, IParticipant>>>(() => {
  return thisWeekGoingToEvents.value?.reduce(
    (
      acc: Map<string, Map<string, IParticipant>>,
      participation: IParticipant
    ) => {
      const day = new Date(participation.event.beginsOn).toDateString();
      const participations: Map<string, IParticipant> =
        acc.get(day) || new Map();
      participations.set(
        `${participation.event.uuid}${participation.actor.id}`,
        participation
      );
      acc.set(day, participations);
      return acc;
    },
    new Map()
  );
});

const canShowMyUpcomingEvents = computed<boolean>(() => {
  return currentActor.value?.id != undefined && goingToEvents.value.size > 0;
});

const canShowFollowedGroupEvents = computed<boolean>(() => {
  // Show section if user is logged in and has any events from followed groups
  // (regardless of whether they've joined them or not)
  return (
    currentActor.value?.id != undefined &&
    (followedGroupEvents.value?.elements || []).length > 0
  );
});

const canShowUserGroups = computed<boolean>(() => {
  return displayedGroups.value.length > 0;
});

const displayedPublicEvents = computed<IEvent[]>(() => {
  // Show public upcoming events for both logged-in and logged-out users
  const rawEvents = publicEventsResult.value?.searchEvents?.elements || [];

  todayStart.setHours(0, 0, 0, 0); // Start of today

  const filteredEvents = rawEvents.filter((event) => {
    // Only show upcoming events (today and future)
    if (!event.beginsOn) {
      return false;
    }

    const eventDate = new Date(event.beginsOn);
    return eventDate >= todayStart;
  });

  // Limit to max 6 events
  return filteredEvents.slice(0, 6);
});

const canShowPublicEvents = computed<boolean>(() => {
  // Show public events for both logged-in and logged-out users if there are events
  const hasEvents = displayedPublicEvents.value.length > 0;
  return hasEvents;
});

const groupsSectionTitle = computed(() => {
  return currentUser.value?.id ? t("Your groups") : t("Discover groups");
});

const groupsSectionDescription = computed(() => {
  return currentUser.value?.id
    ? t("Groups you're a member of")
    : t("Find and join interesting groups");
});

const filteredFollowedGroupsEvents = computed<IEvent[]>(() => {
  // Show all events from followed groups (don't filter out joined events)
  // Events can appear in both "Your upcoming events" and "Events from your groups"
  return (followedGroupEvents.value?.elements || [])
    .map(({ event }: { event: IEvent }) => event)
    .slice(0, 93);
});

const welcomeBack = ref(false);
const newRegisteredUser = ref(false);

onMounted(() => {
  if (window.localStorage.getItem("welcome-back")) {
    welcomeBack.value = true;
    window.localStorage.removeItem("welcome-back");
  }
  if (window.localStorage.getItem("new-registered-user")) {
    newRegisteredUser.value = true;
    window.localStorage.removeItem("new-registered-user");
  }
});

const router = useRouter();

watch(loggedUser, (loggedUserValue) => {
  if (
    loggedUserValue?.id &&
    loggedUserValue?.settings === null &&
    loggedUserValue.defaultActor?.id
  ) {
    console.info("No user settings, going to onboarding", loggedUserValue);
    router.push({
      name: RouteName.WELCOME_SCREEN,
      params: { step: "1" },
    });
  }
});

/**
 * Geolocation stuff
 */

// The location hash saved in the user settings (should be the default)
const userSettingsLocationGeoHash = computed(
  () => loggedUser.value?.settings?.location?.geohash
);

// The location provided by the server
const { location: serverLocation } = useServerProvidedLocation();

// The coords from the user location or the server provided location
const coords = computed(() => {
  const userSettingsCoords = geoHashToCoords(
    userSettingsLocationGeoHash.value ?? undefined
  );

  return { ...serverLocation.value, isIPLocation: !userSettingsCoords };
});

const { result: reverseGeocodeResult } = useQuery<{
  reverseGeocode: IAddress[];
}>(REVERSE_GEOCODE, coords, () => ({
  enabled: coords.value?.longitude != undefined,
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
}));

const userSettingsLocation = computed(() => {
  const location = reverseGeocodeResult.value?.reverseGeocode[0];
  const placeName = location?.locality ?? location?.region ?? location?.country;
  if (placeName) {
    return {
      lat: coords.value?.latitude,
      lon: coords.value?.longitude,
      name: placeName,
      picture: location?.pictureInfo,
      isIPLocation: coords.value?.isIPLocation,
    };
  } else {
    return {};
  }
});

const { result: currentUserLocationResult } = useQuery<{
  currentUserLocation: LocationType;
}>(CURRENT_USER_LOCATION_CLIENT, undefined, {
  fetchPolicy: "cache-and-network",
  notifyOnNetworkStatusChange: false,
});

// The user's location currently in the Apollo cache
const currentUserLocation = computed(() => {
  return {
    ...(currentUserLocationResult.value?.currentUserLocation ?? {
      lat: undefined,
      lon: undefined,
      accuracy: undefined,
      isIPLocation: undefined,
      name: undefined,
      picture: undefined,
    }),
    isIPLocation: false,
  };
});

const userLocation = computed(() => {
  if (noAddress.value) {
    return {
      lon: null,
      lat: null,
      name: null,
    };
  }
  if (address.value) {
    return addressToLocation(address.value);
  }
  const local_address = getAddressFromLocal();
  if (local_address) {
    return addressToLocation(local_address);
  }
  if (
    !userSettingsLocation.value ||
    (userSettingsLocation.value?.isIPLocation &&
      currentUserLocation.value?.name)
  ) {
    return currentUserLocation.value;
  }
  return userSettingsLocation.value;
});

const distance = computed<number | null>({
  get(): number | null {
    if (noAddress.value || !userLocation.value?.name) {
      return null;
    } else if (current_distance.value == null) {
      return userLocation.value?.isIPLocation ? 150 : 25;
    }
    return current_distance.value;
  },
  set(newDistance: number | null) {
    current_distance.value = newDistance;
  },
});

// Fetch all available groups (when not logged in) - use SEARCH_GROUPS (public API)
// Placed here after userLocation and distance are defined to avoid initialization errors
const { result: allGroupsResult } = useQuery<{
  searchGroups: { elements: IGroup[] };
}>(
  SEARCH_GROUPS,
  () => ({
    limit: 6,
    groupPage: 1,
    term: "", // Empty term to get all public groups
    location: userLocation.value?.name || undefined,
    radius: distance.value || undefined,
  }),
  () => {
    const isEnabled = !currentUser.value?.id;
    return {
      enabled: isEnabled,
      fetchPolicy: "cache-and-network",
      notifyOnNetworkStatusChange: false,
    };
  }
);

// Define displayedGroups here after allGroupsResult is available
const displayedGroups = computed<IGroup[]>(() => {
  const result = (() => {
    if (currentUser.value?.id) {
      // User is logged in - show their groups
      return (
        userMembershipsResult.value?.loggedUser?.memberships?.elements || []
      )
        .map((membership: IMember) => membership.parent)
        .slice(0, 6);
    } else {
      // User is not logged in - show public groups from search
      return (allGroupsResult.value?.searchGroups?.elements || []).slice(0, 6);
    }
  })();

  return result;
});

// Fetch public events (when not logged in) - use SEARCH_EVENTS (public API)
const { result: publicEventsResult } = useQuery<{
  searchEvents: { elements: IEvent[] };
}>(
  SEARCH_EVENTS,
  () => {
    const queryParams = {
      limit: 6,
      eventPage: 1,
      longEvents: false,
      term: "", // Empty term to get all public events
      location: userLocation.value?.name || undefined,
      radius: distance.value || undefined,
    };

    return queryParams;
  },
  () => {
    const isEnabled = !currentUser.value?.id; // true if user is not logged in (null or undefined)

    return {
      enabled: isEnabled,
      fetchPolicy: "cache-and-network",
      notifyOnNetworkStatusChange: false,
    };
  }
);

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

  saveCurrentUserLocation({
    lat: reverseGeoCodeInformation.latitude,
    lon: reverseGeoCodeInformation.longitude,
    accuracy: Math.round(reverseGeoCodeInformation.accuracy ?? 12) / 1000,
    isIPLocation: false,
    name: placeName,
    picture: geoLocationInformation.pictureInfo,
  });
});

const fetchAndSaveCurrentLocationName = async ({
  coords: { latitude, longitude, accuracy },
}: // eslint-disable-next-line no-undef
GeolocationPosition) => {
  reverseGeoCodeInformation.latitude = latitude;
  reverseGeoCodeInformation.longitude = longitude;
  reverseGeoCodeInformation.accuracy = accuracy;
  doingGeoloc.value = false;
};

const doingGeoloc = ref(false);

const performGeoLocation = () => {
  doingGeoloc.value = true;
  navigator.geolocation.getCurrentPosition(
    fetchAndSaveCurrentLocationName,
    () => {
      doingGeoloc.value = false;
    }
  );
};

/**
 * Helper function to create mock participation for events without participation data
 */
const createMockParticipation = (event: IEvent): IParticipant => {
  return {
    id: `mock-${event.id}`,
    event,
    actor: currentActor.value || ({} as IPerson),
    role: ParticipantRole.NOT_APPROVED,
    metadata: {},
    insertedAt: new Date(),
    updatedAt: new Date(),
  } as IParticipant;
};

/**
 * View Head
 */
useHead({
  title: computed(() => instanceName.value ?? ""),
});
</script>
