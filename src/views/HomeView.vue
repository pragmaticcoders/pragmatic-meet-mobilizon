<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <!-- <o-loading v-model:active="$apollo.loading" /> -->
    
    <!-- Unlogged introduction -->
    <unlogged-introduction :config="config" />

    <!-- Welcome back -->
    <section
      class="mx-auto my-6"
      v-if="currentActor?.id && (welcomeBack || newRegisteredUser)"
    >
      <o-notification variant="info" v-if="welcomeBack">{{
        t("Welcome back {username}!", {
          username: displayName(currentActor),
        })
      }}</o-notification>
      <o-notification variant="info" v-if="newRegisteredUser">{{
        t("Welcome to Pragmatic Meet, {username}!", {
          username: displayName(currentActor),
        })
      }}</o-notification>
    </section>
    <!-- Your upcoming events -->
    <section v-if="canShowMyUpcomingEvents" class="mx-auto mb-8 mt-4">
      <h2 class="text-2xl font-bold text-gray-900 mb-6">
        {{ t("Your upcoming events") }}
      </h2>
      <div
        v-for="row of goingToEvents"
        class="text-gray-700 mb-4"
        :key="row[0]"
      >
        <p class="date-component-container" v-if="isInLessThanSevenDays(row[0])">
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
        <div>
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
    </section>
    <!-- Events from your followed groups -->
    <section
      class="mx-auto mb-8"
      v-if="canShowFollowedGroupEvents"
    >
      <h2 class="text-2xl font-bold text-gray-900 mb-2">
        {{ t("Upcoming events from your groups") }}
      </h2>
      <p class="text-gray-600 mb-6">{{ t("That you follow or of which you are a member") }}</p>
      <multi-card :events="filteredFollowedGroupsEvents" />
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
    </section>

    <!-- Recent events (only show when user has no upcoming events) -->
    <div class="mx-auto" v-if="!canShowMyUpcomingEvents">
      <CloseEvents
        @doGeoLoc="performGeoLocation()"
        :userLocation="(userLocation as any) || { lat: 0, lon: 0, name: '', isIPLocation: false }"
        :doingGeoloc="doingGeoloc"
        :distance="distance as any"
      />
    </div>
    <!-- Groups section -->
    <section class="mx-auto mb-8">
      <h2 class="text-2xl font-bold text-gray-900 mb-2">
        {{ groupsSectionTitle }}
      </h2>
      <p class="text-gray-600 mb-6">{{ groupsSectionDescription }}</p>
      
      <!-- Groups content -->
      <div v-if="canShowUserGroups">
        <multi-group-card :groups="displayedGroups" />
        <div class="text-right mt-6" v-if="currentUser?.id">
          <router-link
            class="text-blue-600 hover:text-blue-700 font-medium"
            :to="{ name: ActorRouteName.MY_GROUPS }"
            >{{ t("View everything") }} →</router-link
          >
        </div>
        <div class="text-right mt-6" v-else>
          <router-link
            class="text-blue-600 hover:text-blue-700 font-medium"
            :to="{ name: RouteName.SEARCH }"
            >{{ t("View everything") }} →</router-link
          >
        </div>
      </div>
      
      <!-- Empty state for groups -->
      <empty-content 
        v-else
        icon="account-group" 
        inline 
        center
        class="my-8"
      >
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
import MultiCard from "../components/Event/MultiCard.vue";
import MultiGroupCard from "../components/Group/MultiGroupCard.vue";
import EmptyContent from "../components/Utils/EmptyContent.vue";
import { CURRENT_ACTOR_CLIENT, LOGGED_USER_MEMBERSHIPS } from "../graphql/actor";
import { IPerson, displayName, IGroup } from "../types/actor";
import { ICurrentUser, IUser } from "../types/current-user.model";
import { CURRENT_USER_CLIENT } from "../graphql/user";
import { HOME_USER_QUERIES } from "../graphql/home";
import { IMember } from "../types/actor/member.model";
import { LIST_GROUPS } from "../graphql/group";
import RouteName from "../router/name";
import { ActorRouteName } from "../router/actor";
import { IEvent } from "../types/event.model";
// import { IFollowedGroupEvent } from "../types/followedGroupEvent.model";
import CloseEvents from "@/components/Local/CloseEvents.vue";
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
import SearchFields from "@/components/Home/SearchFields.vue";
import { useHead } from "@unhead/vue";
import {
  addressToLocation,
  geoHashToCoords,
  getAddressFromLocal,
  locationToAddress,
  storeAddressInLocal,
} from "@/utils/location";
import { useServerProvidedLocation } from "@/composition/apollo/config";
import QuickPublish from "@/components/Home/QuickPublish.vue";
import ShortSearch from "@/components/Home/ShortSearch.vue";
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
}>(ABOUT);

const config = computed(() => aboutConfigResult.value?.config);

const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT
);
const currentActor = computed<IPerson | undefined>(
  () => currentActorResult.value?.currentActor
);

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const instanceName = computed(() => config.value?.name);

const { result: userResult } = useQuery<{ loggedUser: IUser }>(
  HOME_USER_QUERIES,
  { afterDateTime: new Date().toISOString() },
  () => ({
    enabled: currentUser.value?.id != undefined,
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
}));

// Fetch all available groups (when not logged in)
const { result: allGroupsResult } = useQuery<{
  groups: { elements: IGroup[] };
}>(LIST_GROUPS, { limit: 6 }, () => ({
  enabled: currentUser.value?.id === undefined,
}));

const displayedGroups = computed<IGroup[]>(() => {
  if (currentUser.value?.id) {
    // User is logged in - show their groups
    return (userMembershipsResult.value?.loggedUser?.memberships?.elements || [])
      .map((membership: IMember) => membership.parent)
      .slice(0, 6);
  } else {
    // User is not logged in - show all available groups
    return (allGroupsResult.value?.groups?.elements || []).slice(0, 6);
  }
});

const currentUserParticipations = computed(
  () => loggedUser.value?.participations.elements
);

const increated = ref(0);
const address = ref<IAddress | null>(null);
const search = ref<string | null>(null);
const noAddress = ref(false);
const current_distance = ref<number | null>(null);

watch(address, (newAdd, oldAdd) =>
  console.debug("ADDRESS UPDATED from", oldAdd, " to ", newAdd)
);

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

const isAfter = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) >= nbDays;
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
  const res = (currentUserParticipations.value || []).filter(
    ({ event, role }) =>
      event.beginsOn != null &&
      isAfter(event.beginsOn, 0) &&
      isBefore(event.beginsOn, 7) &&
      role !== ParticipantRole.REJECTED
  );
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
  return filteredFollowedGroupsEvents.value.length > 0;
});

const canShowUserGroups = computed<boolean>(() => {
  return displayedGroups.value.length > 0;
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
  return (followedGroupEvents.value?.elements || [])
    .map(({ event }: { event: IEvent }) => event)
    .filter(
      ({ id }) =>
        !thisWeekGoingToEvents.value
          .map(({ event: { id: event_id } }) => event_id)
          .includes(id)
    )
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
const isLoggedIn = computed(() => loggedUser.value?.id !== undefined);

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
}));

const userSettingsLocation = computed(() => {
  const location = reverseGeocodeResult.value?.reverseGeocode[0];
  const placeName = location?.locality ?? location?.region ?? location?.country;
  console.debug(
    "userSettingsLocation from reverseGeocode",
    reverseGeocodeResult.value,
    coords.value,
    placeName
  );
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
}>(CURRENT_USER_LOCATION_CLIENT);

// The user's location currently in the Apollo cache
const currentUserLocation = computed(() => {
  console.debug(
    "currentUserLocation from LocationType",
    currentUserLocationResult.value
  );
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
  console.debug("new userLocation");
  if (noAddress.value) {
    return {
      lon: null,
      lat: null,
      name: null,
    };
  }
  if (address.value) {
    console.debug("userLocation is typed location");
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

const userAddress = computed<IAddress | null>({
  get(): IAddress | null {
    if (noAddress.value) {
      return null;
    }
    if (address.value) {
      return address.value;
    }
    const local_address = getAddressFromLocal();
    if (local_address) {
      return local_address;
    }
    if (
      !userSettingsLocation.value ||
      (userSettingsLocation.value?.isIPLocation &&
        currentUserLocation.value?.name)
    ) {
      return locationToAddress(currentUserLocation.value);
    }
    return locationToAddress(userSettingsLocation.value as any);
  },
  set(newAddress: IAddress | null) {
    address.value = newAddress;
    noAddress.value = newAddress == null;
  },
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

const updateAddress = (newAddress: IAddress | null) => {
  if (address.value?.geom !== newAddress?.geom || newAddress == null) {
    increated.value += 1;
    storeAddressInLocal(newAddress);
  }
  address.value = newAddress;
  noAddress.value = newAddress == null;
};

/**
 * View Head
 */
useHead({
  title: computed(() => instanceName.value ?? ""),
});
</script>
