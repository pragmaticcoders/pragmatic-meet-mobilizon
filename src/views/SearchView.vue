<template>
  <div class="max-w-screen-xl mx-auto px-6 md:px-16 py-8">
    <!-- Page Title -->
    <h1 class="text-3xl font-bold text-gray-900 text-center mb-8">
      {{ t("Browse events and groups:") }}
    </h1>

    <!-- Search Fields -->
    <search-fields
      v-model:search="search"
      v-model:address="address"
      v-model:distance="radius as any"
      :numberOfSearch="numberOfSearch"
      :addressDefaultText="addressName"
      :fromLocalStorage="true"
    />

    <!-- Content Type Tabs -->
    <div class="flex justify-center mt-6 mb-8">
      <div class="flex overflow-hidden gap-4">
        <button
          @click="contentType = ContentType.EVENTS"
          :class="[
            'flex items-center gap-2 px-6 py-3 text-sm font-medium transition-colors border border-gray-300',
            contentType === ContentType.EVENTS
              ? 'bg-blue-600 text-white'
              : 'bg-white text-gray-700 hover:bg-gray-50',
          ]"
        >
          <svg
            class="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
          {{ t("Events") }}
        </button>
        <button
          @click="contentType = ContentType.GROUPS"
          :class="[
            'flex items-center gap-2 px-6 py-3 text-sm font-medium transition-colors border border-gray-300',
            contentType === ContentType.GROUPS
              ? 'bg-blue-600 text-white'
              : 'bg-white text-gray-700 hover:bg-gray-50',
          ]"
        >
          <svg
            class="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          {{ t("Groups") }}
        </button>
      </div>
    </div>
  </div>
  <div
    class="max-w-screen-xl mx-auto px-6 md:px-16 py-6 flex flex-col lg:flex-row gap-6"
  >
    <aside
      v-show="contentType !== ContentType.GROUPS"
      class="flex-none lg:block lg:sticky top-8 w-full lg:w-80 flex-col justify-between bg-white border border-gray-200 rounded-lg p-6 shadow-sm"
    >
      <o-button
        @click="toggleFilters"
        icon-left="filter"
        class="w-full inline-flex lg:!hidden bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-3 justify-center focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
      >
        <span v-if="!filtersPanelOpened">{{ t("Hide filters") }}</span>
        <span v-else>{{ t("Show filters") }}</span>
      </o-button>
      <div class="hidden lg:block mb-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          {{ t("Filters") }}
        </h3>
      </div>
      <form
        @submit.prevent="() => {}"
        :class="{ hidden: filtersPanelOpened }"
        class="lg:block mt-4"
      >
        <div
          class="py-4 border-b border-gray-200"
          v-show="contentType !== 'GROUPS'"
        >
          <div class="flex items-center justify-between">
            <label class="text-sm font-medium text-gray-900">{{
              t("Online events")
            }}</label>
            <o-switch v-model="isOnline" />
          </div>
        </div>

        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventDate"
          :title="t('Event date')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Event date") }}</legend>
              <div
                v-for="(eventStartDateRangeOption, key) in dateOptions"
                :key="key"
              >
                <input
                  :id="key"
                  v-model="when"
                  type="radio"
                  name="eventStartDateRange"
                  :value="key"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-500 text-blue-600"
                />
                <label
                  :for="key"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900"
                  >{{ eventStartDateRangeOption.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
            >
              {{
                Object.entries(dateOptions).find(([key]) => key === when)?.[1]
                  ?.label
              }}
            </span>
          </template>
        </filter-section>

        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventCategory"
          :title="t('Categories')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Categories") }}</legend>
              <div v-for="category in orderedCategories" :key="category.id">
                <input
                  :id="category.id"
                  v-model="categoryOneOf"
                  type="checkbox"
                  name="category"
                  :value="category.id"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-500 text-blue-600"
                />
                <label
                  :for="category.id"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900"
                  >{{ category.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-if="categoryOneOf.length > 2"
            >
              {{
                t("{numberOfCategories} selected", {
                  numberOfCategories: categoryOneOf.length,
                })
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-else-if="categoryOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  categoryOneOf.map(
                    (category) =>
                      (eventCategories ?? []).find(({ id }) => id === category)
                        ?.label ?? ""
                  )
                )
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-else-if="categoryOneOf.length === 0"
            >
              {{ t("Categories", "All") }}
            </span>
          </template>
        </filter-section>
        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventStatus"
          :title="t('Event status')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Event status") }}</legend>
              <div
                v-for="eventStatusOption in eventStatuses"
                :key="eventStatusOption.id"
              >
                <input
                  :id="eventStatusOption.id"
                  v-model="statusOneOf"
                  type="checkbox"
                  name="eventStatus"
                  :value="eventStatusOption.id"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-500 text-blue-600"
                />
                <label
                  :for="eventStatusOption.id"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900"
                  >{{ eventStatusOption.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-if="statusOneOf.length === Object.values(EventStatus).length"
            >
              {{ t("Statuses", "All") }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-else-if="statusOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  statusOneOf.map(
                    (status) =>
                      eventStatuses.find(({ id }) => id === status)?.label ?? ""
                  )
                )
              }}
            </span>
          </template>
        </filter-section>

        <filter-section
          v-if="false"
          v-model:opened="searchFilterSectionsOpenStatus.eventLanguage"
          :title="t('Languages')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Languages") }}</legend>
              <div>
                <input
                  id="en"
                  type="checkbox"
                  name="eventStartDateRange"
                  value="en"
                  v-model="languageOneOf"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-500 text-blue-600"
                />
                <label
                  for="en"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900"
                  >🇬🇧 English</label
                >
              </div>
              <div>
                <input
                  id="pl"
                  type="checkbox"
                  name="eventStartDateRange"
                  value="pl"
                  v-model="languageOneOf"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-500 text-blue-600"
                />
                <label
                  for="pl"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900"
                  >🇵🇱 Polski</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-if="languageOneOf.length > 2"
            >
              {{
                t("{numberOfLanguages} selected", {
                  numberOfLanguages: languageOneOf.length,
                })
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-else-if="languageOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  languageOneOf.map((lang) =>
                    lang === "en"
                      ? "🇬🇧 English"
                      : lang === "pl"
                        ? "🇵🇱 Polski"
                        : lang
                  )
                )
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full grow-0"
              v-else-if="languageOneOf.length === 0"
            >
              {{ t("Languages", "All") }}
            </span>
          </template>
        </filter-section>

        <div class="sr-only">
          <button
            class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-5 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            type="submit"
          >
            {{ t("Apply filters") }}
          </button>
        </div>

        <o-button
          @click="toggleFilters"
          icon-left="filter"
          class="w-full inline-flex lg:!hidden bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-3 justify-center focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          {{ t("Hide filters") }}
        </o-button>
      </form>
    </aside>
    <div
      class="flex-1 bg-white rounded-lg border border-gray-200 shadow-sm p-6"
    >
      <div
        id="results-anchor"
        class="hidden sm:flex items-center justify-between mb-6"
      >
        <p v-if="searchLoading">{{ t("Loading search results...") }}</p>
        <p v-else-if="totalCount === 0">
          <span v-if="contentType === ContentType.EVENTS">{{
            t("No events found")
          }}</span>

          <span v-else-if="contentType === ContentType.GROUPS">{{
            t("No groups found")
          }}</span>
          <span v-else>{{ t("No results found") }}</span>
        </p>
        <p v-else>
          <span v-if="contentType === ContentType.EVENTS">
            {{
              t(
                "{eventsCount} events found",
                { eventsCount: searchEvents?.total },
                searchEvents?.total ?? 0
              )
            }}
          </span>

          <span v-else-if="contentType === ContentType.GROUPS">
            {{
              t(
                "{groupsCount} groups found",
                { groupsCount: searchGroups?.total },
                searchGroups?.total ?? 0
              )
            }}
          </span>
          <span v-else>
            {{
              t(
                "{resultsCount} results found",
                { resultsCount: totalCount },
                totalCount
              )
            }}
          </span>
        </p>
        <div class="flex gap-2">
          <label class="sr-only" for="sortOptionSelect">{{
            t("Sort by")
          }}</label>
          <o-select
            v-if="contentType !== ContentType.GROUPS"
            :placeholder="t('Sort by events')"
            v-model="sortByEvents"
            id="sortOptionSelectEvents"
          >
            <option
              v-for="sortOption in sortOptionsEvents"
              :key="sortOption.key"
              :value="sortOption.key"
            >
              {{ sortOption.label }}
            </option>
          </o-select>
          <o-select
            v-if="contentType === ContentType.GROUPS"
            :placeholder="t('Sort by groups')"
            v-model="sortByGroups"
            id="sortOptionSelectGroups"
          >
            <option
              v-for="sortOption in sortOptionsGroups"
              :key="sortOption.key"
              :value="sortOption.key"
            >
              {{ sortOption.label }}
            </option>
          </o-select>
          <o-button
            v-show="!isOnline"
            @click="
              () =>
                (mode = mode === ViewMode.MAP ? ViewMode.LIST : ViewMode.MAP)
            "
            :icon-left="mode === ViewMode.MAP ? 'view-list' : 'map'"
          >
            <span v-if="mode === ViewMode.LIST">
              {{ t("Map") }}
            </span>
            <span v-else-if="mode === ViewMode.MAP">
              {{ t("List") }}
            </span>
          </o-button>
        </div>
      </div>
      <div v-if="mode === ViewMode.LIST">
        <template v-if="contentType === ContentType.EVENTS">
          <template v-if="searchLoading">
            <SkeletonEventResultList v-for="i in 8" :key="i" />
          </template>
          <template v-if="searchEvents && searchEvents.total > 0">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
              <event-participation-card
                v-for="event in searchEvents?.elements"
                :key="event.uuid"
                :participation="createMockParticipation(event)"
              />
            </div>
            <o-pagination
              v-show="searchEvents && searchEvents?.total > EVENT_PAGE_LIMIT"
              :total="searchEvents.total"
              v-model:current="eventPage"
              :per-page="EVENT_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </template>
          <EmptyContent v-else-if="searchLoading === false" icon="calendar">
            <span v-if="searchIsUrl">
              {{ t("No event found at this address") }}
            </span>
            <span v-else-if="!search">
              {{ t("No events found") }}
            </span>

            <i18n-t keypath="No events found for {search}" tag="span" v-else>
              <template #search>
                <b>{{ search }}</b>
              </template>
            </i18n-t>
            <template #desc v-if="searchIsUrl && !currentUser?.id">
              {{
                t(
                  "Only registered users may fetch remote events from their URL."
                )
              }}
            </template>
            <template #desc v-else>
              <p class="my-2 text-start">
                {{ t("Suggestions:") }}
              </p>
              <ul class="list-disc list-inside text-start">
                <li>
                  {{ t("Make sure that all words are spelled correctly.") }}
                </li>
                <li>{{ t("Try different keywords.") }}</li>
                <li>{{ t("Try more general keywords.") }}</li>
                <li>{{ t("Try fewer keywords.") }}</li>
                <li>{{ t("Change the filters.") }}</li>
              </ul>
            </template>
          </EmptyContent>
        </template>
        <template v-else-if="contentType === ContentType.GROUPS">
          <o-notification v-if="features && !features.groups" variant="danger">
            {{ t("Groups are not enabled on this instance.") }}
          </o-notification>
          <template v-else-if="searchLoading">
            <SkeletonGroupResultList v-for="i in 6" :key="i" />
          </template>
          <template v-else-if="searchGroups && searchGroups?.total > 0">
            <MultiGroupCard
              :groups="searchGroups?.elements || []"
              class="mb-6"
            />
            <o-pagination
              v-show="searchGroups && searchGroups?.total > GROUP_PAGE_LIMIT"
              :total="searchGroups?.total"
              v-model:current="groupPage"
              :per-page="GROUP_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </template>
          <EmptyContent
            v-else-if="searchLoading === false"
            icon="account-multiple"
          >
            <span v-if="!search">
              {{ t("No groups found") }}
            </span>
            <i18n-t keypath="No groups found for {search}" tag="span" v-else>
              <template #search>
                <b>{{ search }}</b>
              </template>
            </i18n-t>
            <template #desc>
              <p class="my-2 text-start">
                {{ t("Suggestions:") }}
              </p>
              <ul class="list-disc list-inside text-start">
                <li>
                  {{ t("Make sure that all words are spelled correctly.") }}
                </li>
                <li>{{ t("Try different keywords.") }}</li>
                <li>{{ t("Try more general keywords.") }}</li>
                <li>{{ t("Try fewer keywords.") }}</li>
                <li>{{ t("Change the filters.") }}</li>
              </ul>
            </template>
          </EmptyContent>
        </template>
      </div>
      <event-marker-map
        v-if="mode === ViewMode.MAP"
        :contentType="contentType"
        :latitude="latitude"
        :longitude="longitude"
        :locationName="addressName"
        @map-updated="setBounds"
        :events="searchEvents || { elements: [], total: 0 }"
        :groups="searchGroups || { elements: [], total: 0 }"
        :isLoggedIn="currentUser?.isLoggedIn"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  endOfToday,
  addDays,
  startOfDay,
  endOfDay,
  endOfWeek,
  addWeeks,
  startOfWeek,
  endOfMonth,
  addMonths,
  startOfMonth,
  eachWeekendOfInterval,
} from "date-fns";
import {
  ContentType,
  EventStatus,
  SearchTargets,
  ParticipantRole,
} from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { SEARCH_EVENTS_AND_GROUPS, SEARCH_EVENTS } from "@/graphql/search";
import { Paginate } from "@/types/paginate";
import { IGroup, IPerson } from "@/types/actor";
import MultiGroupCard from "@/components/Group/MultiGroupCard.vue";
import { IParticipant } from "@/types/participant.model";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { ICurrentUser } from "@/types/current-user.model";
import { useQuery } from "@vue/apollo-composable";
import { computed, defineAsyncComponent, inject, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import {
  floatTransformer,
  integerTransformer,
  useRouteQuery,
  enumTransformer,
  booleanTransformer,
} from "vue-use-route-query";

import { useHead } from "@/utils/head";
import type { Locale } from "date-fns";
import FilterSection from "@/components/Search/filters/FilterSection.vue";
import { listShortDisjunctionFormatter } from "@/utils/listFormat";
import {
  useEventCategories,
  useFeatures,
  useSearchConfig,
} from "@/composition/apollo/config";
import { coordsToGeoHash } from "@/utils/location";
import SearchFields from "@/components/Home/SearchFields.vue";
import { refDebounced } from "@vueuse/core";
import { IAddress } from "@/types/address.model";
import { IConfig } from "@/types/config.model";
import { TypeNamed } from "@/types/apollo";
import { LatLngBounds } from "leaflet";
import lodashSortBy from "lodash/sortBy";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import SkeletonGroupResultList from "@/components/Group/SkeletonGroupResultList.vue";
import SkeletonEventResultList from "@/components/Event/SkeletonEventResultList.vue";
import { arrayTransformer } from "@/utils/route";

const EventMarkerMap = defineAsyncComponent(
  () => import("@/components/Search/EventMarkerMap.vue")
);

const EventParticipationCard = defineAsyncComponent(
  () => import("@/components/Event/EventParticipationCard.vue")
);

const search = useRouteQuery("search", "");
const searchDebounced = refDebounced(search, 1000);
const addressName = useRouteQuery("locationName", null);
const address = ref<IAddress | null>(null);

watch(address, (newAddress: IAddress | null) => {
  console.debug("address change", newAddress);
  if (newAddress?.geom) {
    latitude.value = parseFloat(newAddress?.geom.split(";")[1]);
    longitude.value = parseFloat(newAddress?.geom.split(";")[0]);
    addressName.value = newAddress?.description;
    console.debug("set address", [
      latitude.value,
      longitude.value,
      addressName.value,
    ]);
  } else {
    console.debug("address emptied");
    latitude.value = undefined;
    longitude.value = undefined;
    addressName.value = null;
  }
});

interface ISearchTimeOption {
  label: string;
  start?: string | null;
  end?: string | null;
}

enum ViewMode {
  LIST = "list",
  MAP = "map",
}

enum EventSortValues {
  CREATED_AT_ASC = "CREATED_AT_ASC",
  CREATED_AT_DESC = "CREATED_AT_DESC",
  START_TIME_ASC = "START_TIME_ASC",
  START_TIME_DESC = "START_TIME_DESC",
  PARTICIPANT_COUNT_DESC = "PARTICIPANT_COUNT_DESC",
}

enum GroupSortValues {
  CREATED_AT_DESC = "CREATED_AT_DESC",
  MEMBER_COUNT_DESC = "MEMBER_COUNT_DESC",
  LAST_EVENT_ACTIVITY = "LAST_EVENT_ACTIVITY",
}

const props = defineProps<{
  tag?: string;
}>();
const tag = computed(() => props.tag);

const eventPage = useRouteQuery("eventPage", 1, integerTransformer);
const groupPage = useRouteQuery("groupPage", 1, integerTransformer);

const latitude = useRouteQuery("lat", undefined, floatTransformer);
const longitude = useRouteQuery("lon", undefined, floatTransformer);

const distance = useRouteQuery("distance", "10_km");
const when = useRouteQuery("when", "any");
const contentType = useRouteQuery(
  "contentType",
  ContentType.EVENTS,
  enumTransformer(ContentType)
);
const isOnline = useRouteQuery("isOnline", false, booleanTransformer);
const categoryOneOf = useRouteQuery("categoryOneOf", [], arrayTransformer);
const statusOneOf = useRouteQuery(
  "statusOneOf",
  [EventStatus.CONFIRMED],
  arrayTransformer
);
const languageOneOf = useRouteQuery("languageOneOf", [], arrayTransformer);

// Default to INTERNAL since we removed the search target selector from UI
const searchTarget = useRouteQuery(
  "target",
  SearchTargets.INTERNAL,
  enumTransformer(SearchTargets)
);
const mode = useRouteQuery("mode", ViewMode.LIST, enumTransformer(ViewMode));
const sortByEvents = useRouteQuery(
  "sortByEvents",
  EventSortValues.START_TIME_ASC,
  enumTransformer(EventSortValues)
);
const sortByGroups = useRouteQuery(
  "sortByGroups",
  GroupSortValues.LAST_EVENT_ACTIVITY,
  enumTransformer(GroupSortValues)
);
const bbox = useRouteQuery("bbox", null);
const zoom = useRouteQuery("zoom", undefined, integerTransformer);

const EVENT_PAGE_LIMIT = 16;

const GROUP_PAGE_LIMIT = 16;

const { features } = useFeatures();
const { eventCategories } = useEventCategories();

const orderedCategories = computed(() => {
  if (!eventCategories.value) return [];
  return lodashSortBy(eventCategories.value, ["label"]);
});

const searchEvents = computed(() => searchElementsResult.value?.searchEvents);
const searchShortEvents = computed(
  () => searchShortElementsResult.value?.searchEvents
);

const searchGroups = computed(() => searchElementsResult.value?.searchGroups);

const numberOfSearch = computed(() => {
  return {
    EVENTS: searchShortEvents.value?.total,
    GROUPS: searchGroups.value?.total,
  };
});

const { result: currentUserResult } = useQuery<{ currentUser: ICurrentUser }>(
  CURRENT_USER_CLIENT,
  undefined,
  { fetchPolicy: "cache-and-network", notifyOnNetworkStatusChange: false }
);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT,
  undefined,
  { fetchPolicy: "cache-and-network", notifyOnNetworkStatusChange: false }
);
const currentActor = computed<IPerson | undefined>(
  () => currentActorResult.value?.currentActor
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Explore events")),
});

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const weekend = computed((): { start: Date; end: Date } => {
  const now = new Date();
  const endOfWeekDate = endOfWeek(now, { locale: dateFnsLocale });
  const startOfWeekDate = startOfWeek(now, { locale: dateFnsLocale });
  const [start, end] = eachWeekendOfInterval({
    start: startOfWeekDate,
    end: endOfWeekDate,
  });
  return { start: startOfDay(start), end: endOfDay(end) };
});

const dateOptions: Record<string, ISearchTimeOption> = {
  past: {
    label: t("In the past") as string,
    start: null,
    end: new Date().toISOString(),
  },
  today: {
    label: t("Today") as string,
    start: new Date().toISOString(),
    end: endOfToday().toISOString(),
  },
  tomorrow: {
    label: t("Tomorrow") as string,
    start: startOfDay(addDays(new Date(), 1)).toISOString(),
    end: endOfDay(addDays(new Date(), 1)).toISOString(),
  },
  weekend: {
    label: t("This weekend") as string,
    start: weekend.value.start.toISOString(),
    end: weekend.value.end.toISOString(),
  },
  week: {
    label: t("This week") as string,
    start: new Date().toISOString(),
    end: endOfWeek(new Date(), { locale: dateFnsLocale }).toISOString(),
  },
  next_week: {
    label: t("Next week") as string,
    start: startOfWeek(addWeeks(new Date(), 1), {
      locale: dateFnsLocale,
    }).toISOString(),
    end: endOfWeek(addWeeks(new Date(), 1), {
      locale: dateFnsLocale,
    }).toISOString(),
  },
  month: {
    label: t("This month") as string,
    start: new Date().toISOString(),
    end: endOfMonth(new Date()).toISOString(),
  },
  next_month: {
    label: t("Next month") as string,
    start: startOfMonth(addMonths(new Date(), 1)).toISOString(),
    end: endOfMonth(addMonths(new Date(), 1)).toISOString(),
  },
  any: {
    label: t("Any day") as string,
    start: new Date().toISOString(),
    end: null,
  },
};

const start = computed((): string | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].start;
  }
  return undefined;
});

const end = computed((): string | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].end;
  }
  return undefined;
});

const searchIsUrl = computed((): boolean => {
  let url;
  if (!searchDebounced.value) return false;
  try {
    url = new URL(searchDebounced.value);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
});

const eventStatuses = computed(() => {
  return [
    {
      id: EventStatus.CONFIRMED,
      label: t("Confirmed"),
    },
    {
      id: EventStatus.TENTATIVE,
      label: t("Tentative"),
    },
    {
      id: EventStatus.CANCELLED,
      label: t("Cancelled"),
    },
  ];
});

const searchFilterSectionsOpenStatus = ref({
  eventDate: true,
  eventLanguage: false,
  eventCategory: false,
  eventStatus: false,
  eventDistance: false,
});

const filtersPanelOpened = ref(true);

const toggleFilters = () =>
  (filtersPanelOpened.value = !filtersPanelOpened.value);

const geoHashLocation = computed(() =>
  coordsToGeoHash(latitude.value, longitude.value)
);

const radius = computed<number | null>({
  get(): number | null {
    if (addressName.value) {
      return Number.parseInt(distance.value.slice(0, -3));
    } else {
      return null;
    }
  },
  set(newRadius: number | null) {
    if (newRadius !== null) {
      distance.value = newRadius.toString() + "_km";
    }
  },
});

const longEvents = computed(() => {
  if (contentType.value === ContentType.EVENTS) {
    return false;
  } else {
    return null;
  }
});

const totalCount = computed(() => {
  return (searchEvents.value?.total ?? 0) + (searchGroups.value?.total ?? 0);
});

const sortOptionsGroups = computed(() => {
  const options = [
    {
      key: GroupSortValues.LAST_EVENT_ACTIVITY,
      label: t("Last event activity"),
    },
    {
      key: GroupSortValues.MEMBER_COUNT_DESC,
      label: t("Decreasing number of members"),
    },
    {
      key: GroupSortValues.CREATED_AT_DESC,
      label: t("Decreasing creation date"),
    },
  ];

  return options;
});

const sortOptionsEvents = computed(() => {
  const options = [
    {
      key: EventSortValues.START_TIME_ASC,
      label: t("Event date"),
    },
    {
      key: EventSortValues.CREATED_AT_DESC,
      label: t("Most recently published"),
    },
    {
      key: EventSortValues.CREATED_AT_ASC,
      label: t("Least recently published"),
    },
    {
      key: EventSortValues.PARTICIPANT_COUNT_DESC,
      label: t("With the most participants"),
    },
  ];

  return options;
});

const { searchConfig, onResult: onSearchConfigResult } = useSearchConfig();

onSearchConfigResult(({ data }) =>
  handleSearchConfigChanged(data?.config?.search)
);

const handleSearchConfigChanged = (
  searchConfigChanged: IConfig["search"] | undefined
) => {
  if (
    searchConfigChanged?.global?.isEnabled &&
    searchConfigChanged?.global?.isDefault
  ) {
    searchTarget.value = SearchTargets.INTERNAL;
  }
};

watch(searchConfig, (newSearchConfig) =>
  handleSearchConfigChanged(newSearchConfig)
);

const setBounds = ({
  bounds,
  zoom: boundsZoom,
}: {
  bounds: LatLngBounds;
  zoom: number;
}) => {
  bbox.value = `${bounds.getNorthWest().lat}, ${bounds.getNorthWest().lng}:${
    bounds.getSouthEast().lat
  }, ${bounds.getSouthEast().lng}`;
  zoom.value = boundsZoom;
};

watch(mode, (newMode) => {
  if (newMode === ViewMode.MAP) {
    isOnline.value = false;
  }
});

watch(isOnline, (newIsOnline) => {
  if (newIsOnline) {
    mode.value = ViewMode.LIST;
  }
});

const sortByForType = (
  value: EventSortValues,
  allowed: typeof EventSortValues
): EventSortValues | undefined => {
  if (value === EventSortValues.START_TIME_ASC && when.value === "past") {
    value = EventSortValues.START_TIME_DESC;
  }
  return Object.values(allowed).includes(value) ? value : undefined;
};

const boostLanguagesQuery = computed((): string[] => {
  const languages = new Set<string>();

  for (const completeLanguage of navigator.languages) {
    const language = completeLanguage.split("-")[0];

    if (["en", "pl"].includes(language)) {
      languages.add(language);
    }
  }

  return Array.from(languages);
});

// When search criteria changes, reset page number to 1
watch(
  [
    contentType,
    searchDebounced,
    geoHashLocation,
    start,
    end,
    radius,
    isOnline,
    categoryOneOf,
    statusOneOf,
    languageOneOf,
    searchTarget,
    bbox,
    zoom,
    sortByEvents,
    sortByGroups,
    boostLanguagesQuery,
  ],
  ([newContentType]) => {
    switch (newContentType) {
      case ContentType.EVENTS:
        eventPage.value = 1;
        break;

      case ContentType.GROUPS:
        groupPage.value = 1;
        break;
    }
  }
);

const { result: searchElementsResult, loading: searchLoading } = useQuery<{
  searchEvents: Paginate<TypeNamed<IEvent>>;
  searchGroups: Paginate<TypeNamed<IGroup>>;
}>(
  SEARCH_EVENTS_AND_GROUPS,
  () => ({
    term: searchDebounced.value,
    tags: tag.value,
    location: geoHashLocation.value,
    beginsOn: start.value,
    endsOn: end.value,
    longEvents: longEvents.value,
    radius: geoHashLocation.value ? radius.value : undefined,
    eventPage: eventPage.value,
    groupPage: groupPage.value,
    limit: EVENT_PAGE_LIMIT,
    type: isOnline.value ? "ONLINE" : undefined,
    categoryOneOf: categoryOneOf.value,
    statusOneOf: statusOneOf.value,
    languageOneOf: languageOneOf.value,
    searchTarget: searchTarget.value,
    bbox: mode.value === ViewMode.MAP ? bbox.value : undefined,
    zoom: zoom.value,
    sortByEvents: sortByForType(sortByEvents.value, EventSortValues),
    sortByGroups: sortByGroups.value,
    boostLanguages: boostLanguagesQuery.value,
  }),
  { fetchPolicy: "cache-and-network", notifyOnNetworkStatusChange: false }
);

const { result: searchShortElementsResult } = useQuery<{
  searchEvents: Paginate<TypeNamed<IEvent>>;
}>(
  SEARCH_EVENTS,
  () => ({
    term: searchDebounced.value,
    tags: tag.value,
    location: geoHashLocation.value,
    beginsOn: start.value,
    endsOn: end.value,
    longEvents: false,
    radius: geoHashLocation.value ? radius.value : undefined,
    limit: 0,
    type: isOnline.value ? "ONLINE" : undefined,
    categoryOneOf: categoryOneOf.value,
    statusOneOf: statusOneOf.value,
    languageOneOf: languageOneOf.value,
    searchTarget: searchTarget.value,
    bbox: mode.value === ViewMode.MAP ? bbox.value : undefined,
    zoom: zoom.value,
    boostLanguages: boostLanguagesQuery.value,
  }),
  { fetchPolicy: "cache-and-network", notifyOnNetworkStatusChange: false }
);

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
</script>
