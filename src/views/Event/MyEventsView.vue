<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16 mb-6">
    <h1>
      {{ t("My events") }}
    </h1>
    <p class="mb-6 max-w-prose">
      {{
        t(
          "You will find here all the events you have created or of which you are a participant, as well as events organized by groups you follow or are a member of."
        )
      }}
    </p>
    <div class="mt-4 mb-8" v-if="!hideCreateEventButton">
      <o-button
        tag="router-link"
        variant="primary"
        :to="{ name: RouteName.CREATE_EVENT }"
        >{{ t("Create event") }}</o-button
      >
    </div>
    <div class="flex flex-wrap gap-6 items-start">
      <div
        class="w-full md:w-80 bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 p-4"
      >
        <o-field
          class="date-filter mb-4"
          expanded
          :label="
            showUpcoming
              ? t('Showing events starting on')
              : t('Showing events before')
          "
          labelFor="events-start-datepicker"
        >
          <div class="flex gap-2">
            <event-date-picker
              id="events-start-datepicker"
              :time="false"
              v-model="datePick"
              class="flex-1"
            ></event-date-picker>
            <o-button
              @click="datePick = new Date()"
              variant="primary"
              class="px-3"
              icon-left="close"
              :title="t('Clear date filter field')"
            />
          </div>
        </o-field>
        <div class="space-y-3" v-if="showUpcoming">
          <o-field>
            <o-checkbox
              v-model="showDrafts"
              class="text-sm text-gray-700 dark:text-gray-300"
              >{{ t("Drafts") }}</o-checkbox
            >
          </o-field>
          <o-field>
            <o-checkbox
              v-model="showAttending"
              class="text-sm text-gray-700 dark:text-gray-300"
              >{{ t("Attending") }}</o-checkbox
            >
          </o-field>
          <o-field>
            <o-checkbox
              v-model="showMyGroups"
              class="text-sm text-gray-700 dark:text-gray-300"
              >{{ t("From my groups") }}</o-checkbox
            >
          </o-field>
        </div>
        <p
          v-if="!showUpcoming"
          class="text-sm text-gray-600 dark:text-gray-400 mt-4"
        >
          {{
            t(
              "You have attended {count} events in the past.",
              {
                count: pastParticipations.total,
              },
              pastParticipations.total
            )
          }}
        </p>
      </div>
      <div class="flex-1 min-w-[300px]">
        <section
          class="py-4 first:pt-0"
          v-if="showUpcoming && showDrafts && drafts && drafts.total > 0"
        >
          <h2 class="text-2xl mb-2 mt-0">{{ t("Drafts") }}</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4">
            <event-participation-card
              v-for="event in drafts.elements"
              :key="event.id"
              :participation="createMockParticipation(event)"
            />
          </div>
          <o-pagination
            class="mt-4"
            v-show="drafts.total > LOGGED_USER_DRAFTS_LIMIT"
            :total="drafts.total"
            v-model:current="draftsPage"
            :per-page="LOGGED_USER_DRAFTS_LIMIT"
            :aria-next-label="t('Next page')"
            :aria-previous-label="t('Previous page')"
            :aria-page-label="t('Page')"
            :aria-current-label="t('Current page')"
          >
          </o-pagination>
        </section>
        <section
          class="py-4 first:pt-0"
          v-if="
            showUpcoming && monthlyFutureEvents && monthlyFutureEvents.size > 0
          "
        >
          <transition-group name="list" tag="p">
            <div
              class="mb-5"
              v-for="month of monthlyFutureEvents"
              :key="month[0]"
            >
              <h2 class="text-2xl mb-2">{{ month[0] }}</h2>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4">
                <template v-for="element in month[1]" :key="element.id">
                  <event-participation-card
                    v-if="'role' in element"
                    :participation="element"
                    @event-deleted="eventDeleted"
                    class="participation"
                  />
                  <event-participation-card
                    v-else-if="
                      element.id &&
                      !monthParticipationsIds(month[1]).includes(element?.id)
                    "
                    :participation="createMockParticipation(element)"
                    class="participation flex-shrink-0"
                  />
                </template>
              </div>
            </div>
          </transition-group>
          <div class="columns is-centered">
            <o-button
              class="column is-narrow"
              v-if="
                hasMoreFutureParticipations &&
                futureParticipations &&
                futureParticipations.length === limit
              "
              @click="loadMoreFutureParticipations"
              size="large"
              variant="primary"
              >{{ t("Load more") }}</o-button
            >
          </div>
        </section>
        <section v-if="loading">
          <div class="text-center prose dark:prose-invert max-w-full">
            <p>{{ t("Loading…") }}</p>
          </div>
        </section>
        <section
          class="text-center not-found py-12"
          v-if="
            showUpcoming &&
            monthlyFutureEvents &&
            monthlyFutureEvents.size === 0 &&
            !loading
          "
        >
          <div class="flex flex-col items-center justify-center">
            <div class="mb-6">
              <svg
                width="48"
                height="48"
                viewBox="0 0 48 48"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                class="text-gray-400"
              >
                <rect
                  x="4"
                  y="10"
                  width="40"
                  height="34"
                  rx="2"
                  stroke="currentColor"
                  stroke-width="2"
                  fill="none"
                />
                <line
                  x1="4"
                  y1="18"
                  x2="44"
                  y2="18"
                  stroke="currentColor"
                  stroke-width="2"
                />
                <line
                  x1="12"
                  y1="4"
                  x2="12"
                  y2="10"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                />
                <line
                  x1="36"
                  y1="4"
                  x2="36"
                  y2="10"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                />
                <rect
                  x="10"
                  y="24"
                  width="6"
                  height="6"
                  fill="currentColor"
                  opacity="0.3"
                />
                <rect
                  x="21"
                  y="24"
                  width="6"
                  height="6"
                  fill="currentColor"
                  opacity="0.3"
                />
                <rect
                  x="32"
                  y="24"
                  width="6"
                  height="6"
                  fill="currentColor"
                  opacity="0.3"
                />
                <rect
                  x="10"
                  y="34"
                  width="6"
                  height="6"
                  fill="currentColor"
                  opacity="0.3"
                />
                <rect
                  x="21"
                  y="34"
                  width="6"
                  height="6"
                  fill="currentColor"
                  opacity="0.3"
                />
              </svg>
            </div>
            <p class="text-gray-600 dark:text-gray-400 text-base mb-2">
              {{ t("Nie masz żadnych nadchodzących wydarzeń.") }}
            </p>
            <p class="text-gray-500 dark:text-gray-500 text-sm">
              {{
                t("Czy chcesz utworzyć wydarzenie lub przejrzeć wydarzenia?")
              }}
            </p>
          </div>
        </section>
        <section v-if="!showUpcoming && pastParticipations.elements.length > 0">
          <transition-group name="list" tag="p">
            <div v-for="month in monthlyPastParticipations" :key="month[0]">
              <h2 class="capitalize inline-block relative">{{ month[0] }}</h2>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4">
                <event-participation-card
                  v-for="participation in month[1]"
                  :key="participation.id"
                  :participation="participation as IParticipant"
                  :options="{ hideDate: false }"
                  @event-deleted="eventDeleted"
                  class="participation"
                />
              </div>
            </div>
          </transition-group>
          <div class="columns is-centered">
            <o-button
              class="column is-narrow"
              v-if="
                hasMorePastParticipations &&
                pastParticipations.elements.length === limit
              "
              @click="loadMorePastParticipations"
              size="large"
              variant="primary"
              >{{ t("Load more") }}</o-button
            >
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ParticipantRole } from "@/types/enums";
import RouteName from "@/router/name";
import type { IParticipant } from "../../types/participant.model";
import { LOGGED_USER_DRAFTS, CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import type { IEvent } from "../../types/event.model";
import type { IPerson } from "@/types/actor";

import {
  LOGGED_USER_PARTICIPATIONS,
  LOGGED_USER_UPCOMING_EVENTS,
} from "@/graphql/participant";
import { useApolloClient, useQuery } from "@vue/apollo-composable";
import { computed, ref, defineAsyncComponent } from "vue";
import { IUser } from "@/types/current-user.model";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { useI18n } from "vue-i18n";
import { useRestrictions } from "@/composition/apollo/config";
import { useHead } from "@/utils/head";
import EventDatePicker from "@/components/Event/EventDatePicker.vue";
import { useCurrentActorType } from "@/composition/actorType";

const EventParticipationCard = defineAsyncComponent(
  () => import("@/components/Event/EventParticipationCard.vue")
);

type Eventable = IParticipant | IEvent;

const { t } = useI18n({ useScope: "global" });

// Get current actor for mock participations
const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT
);
const currentActor = computed<IPerson | undefined>(
  () => currentActorResult.value?.currentActor
);

const futurePage = ref(1);
const pastPage = ref(1);
const limit = ref(10);

function startOfDay(d: Date): string {
  // Create a new date object at the start of the selected day in local timezone
  const startOfLocalDay = new Date(
    d.getFullYear(),
    d.getMonth(),
    d.getDate(),
    0,
    0,
    0,
    0
  );
  // Subtract 1 second to ensure we capture events exactly at day boundary
  startOfLocalDay.setSeconds(startOfLocalDay.getSeconds() - 1);
  // Return ISO string which automatically handles timezone conversion
  return startOfLocalDay.toISOString();
}

const showUpcoming = useRouteQuery("showUpcoming", true, booleanTransformer);
const showDrafts = useRouteQuery("showDrafts", true, booleanTransformer);
const showAttending = useRouteQuery("showAttending", true, booleanTransformer);
const showMyGroups = useRouteQuery("showMyGroups", false, booleanTransformer);
const dateFilter = useRouteQuery("dateFilter", startOfDay(new Date()), {
  fromQuery(query) {
    if (query && /(\d{4}-\d{2}-\d{2})/.test(query)) {
      return `${query}T00:00:00Z`;
    }
    return startOfDay(new Date());
  },
  toQuery(value: string) {
    return value.slice(0, 10);
  },
});

// bridge between datepicker expecting a Date object and dateFilter being a string
const datePick = computed({
  get: () => {
    return new Date(dateFilter.value);
  },
  set: (d: Date) => {
    dateFilter.value = startOfDay(d);
  },
});

const hasMoreFutureParticipations = ref(true);
const hasMorePastParticipations = ref(true);

const {
  result: loggedUserUpcomingEventsResult,
  fetchMore: fetchMoreUpcomingEvents,
  loading,
} = useQuery<{
  loggedUser: IUser;
}>(
  LOGGED_USER_UPCOMING_EVENTS,
  () => ({
    page: 1,
    limit: 10,
    afterDateTime: dateFilter.value,
  }),
  () => ({
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: false,
  })
);

const futureParticipations = computed(
  () =>
    loggedUserUpcomingEventsResult.value?.loggedUser.participations.elements ??
    []
);
const groupEvents = computed(
  () =>
    loggedUserUpcomingEventsResult.value?.loggedUser.followedGroupEvents
      .elements ?? []
);

const LOGGED_USER_DRAFTS_LIMIT = 10;
const draftsPage = useRouteQuery("draftsPage", 1, integerTransformer);

const { result: draftsResult } = useQuery<{
  loggedUser: Pick<IUser, "drafts">;
}>(
  LOGGED_USER_DRAFTS,
  () => ({ page: draftsPage.value, limit: LOGGED_USER_DRAFTS_LIMIT }),
  () => ({ fetchPolicy: "cache-and-network" })
);
const drafts = computed(() => draftsResult.value?.loggedUser.drafts);

const { result: participationsResult, fetchMore: fetchMoreParticipations } =
  useQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>(
    LOGGED_USER_PARTICIPATIONS,
    () => ({ page: 1, limit: 10 }),
    () => ({
      fetchPolicy: "cache-and-network",
      notifyOnNetworkStatusChange: false,
    })
  );
const pastParticipations = computed(
  () =>
    participationsResult.value?.loggedUser.participations ?? {
      elements: [],
      total: 0,
    }
);

const monthlyEvents = (elements: Eventable[]): Map<string, Eventable[]> => {
  const res = elements.filter((element: Eventable) => {
    if ("role" in element) {
      return (
        element.event.beginsOn != null &&
        element.role !== ParticipantRole.REJECTED
      );
    }
    return element.beginsOn != null;
  });
  // sort by start date, ascending
  res.sort((a: Eventable, b: Eventable) => {
    const aTime = "role" in a ? a.event.beginsOn : a.beginsOn;
    const bTime = "role" in b ? b.event.beginsOn : b.beginsOn;
    return new Date(aTime).getTime() - new Date(bTime).getTime();
  });
  return res.reduce((acc: Map<string, Eventable[]>, element: Eventable) => {
    const month = new Date(
      "role" in element ? element.event.beginsOn : element.beginsOn
    ).toLocaleDateString(undefined, {
      year: "numeric",
      month: "long",
    });
    const filteredElements: Eventable[] = acc.get(month) || [];
    filteredElements.push(element);
    acc.set(month, filteredElements);
    return acc;
  }, new Map());
};

const monthlyFutureEvents = computed((): Map<string, Eventable[]> => {
  let eventable = [] as Eventable[];
  if (showAttending.value) {
    eventable = [...eventable, ...futureParticipations.value];
  }
  if (showMyGroups.value) {
    eventable = [...eventable, ...groupEvents.value.map(({ event }) => event)];
  }
  return monthlyEvents(eventable);
});

const monthlyPastParticipations = computed((): Map<string, Eventable[]> => {
  return monthlyEvents(pastParticipations.value.elements);
});

const monthParticipationsIds = (elements: Eventable[]): string[] => {
  const res = elements.filter((element: Eventable) => {
    return "role" in element;
  }) as IParticipant[];
  return res.map(({ event }: { event: IEvent }) => {
    return event.id as string;
  });
};

const loadMoreFutureParticipations = (): void => {
  futurePage.value += 1;
  if (fetchMoreUpcomingEvents) {
    fetchMoreUpcomingEvents({
      // New variables
      variables: {
        page: futurePage.value,
        limit: limit.value,
      },
    });
  }
};

const loadMorePastParticipations = (): void => {
  pastPage.value += 1;
  if (fetchMoreParticipations) {
    fetchMoreParticipations({
      // New variables
      variables: {
        page: pastPage.value,
        limit: limit.value,
      },
    });
  }
};

const apollo = useApolloClient();

const eventDeleted = (eventid: string): void => {
  /**
   * Remove event from upcoming event participations
   */
  const upcomingEventsData = apollo.client.cache.readQuery<{
    loggedUser: IUser;
  }>({
    query: LOGGED_USER_UPCOMING_EVENTS,
    variables: () => ({
      page: 1,
      limit: 10,
      afterDateTime: dateFilter.value,
    }),
  });
  if (!upcomingEventsData) return;
  const loggedUser = upcomingEventsData?.loggedUser;
  const participations = loggedUser?.participations;
  apollo.client.cache.writeQuery<{ loggedUser: IUser }>({
    query: LOGGED_USER_UPCOMING_EVENTS,
    variables: () => ({
      page: 1,
      limit: 10,
      afterDateTime: dateFilter.value,
    }),
    data: {
      loggedUser: {
        ...loggedUser,
        participations: {
          total: participations.total - 1,
          elements: participations.elements.filter(
            (participation) => participation.event.id !== eventid
          ),
        },
      },
    },
  });

  /**
   * Remove event from past event participations
   */
  const participationData = apollo.client.cache.readQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>({
    query: LOGGED_USER_PARTICIPATIONS,
    variables: () => ({ page: 1, limit: 10 }),
  });
  if (!participationData) return;
  const loggedUser2 = participationData?.loggedUser;
  const participations2 = loggedUser?.participations;
  apollo.client.cache.writeQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>({
    query: LOGGED_USER_PARTICIPATIONS,
    variables: () => ({ page: 1, limit: 10 }),
    data: {
      loggedUser: {
        ...loggedUser2,
        participations: {
          total: participations2.total - 1,
          elements: participations2.elements.filter(
            (participation) => participation.event.id !== eventid
          ),
        },
      },
    },
  });
};

useRestrictions();
const { isCurrentActorGroup } = useCurrentActorType();

const hideCreateEventButton = computed((): boolean => {
  // Hide create event button for individual users (persons) - only show for groups
  return !isCurrentActorGroup.value;
});

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

useHead({
  title: computed(() => t("My events")),
});
</script>
