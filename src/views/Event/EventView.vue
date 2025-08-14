<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <o-loading v-model:active="eventLoading" />
    <div class="flex flex-col mb-3">
      <!-- Event Banner with Floating Elements -->
      <div class="relative mb-4">
        <event-banner :picture="event?.picture" />
        
        <!-- Floating Calendar Icon - positioned over banner -->
        <div 
          class="absolute bg-white shadow-lg border border-gray-200 z-10 left-4 md:left-8 bottom-[-32px] w-20"
          v-if="event?.beginsOn"
        >
          <skeleton-date-calendar-icon
            v-if="eventLoading"
            class="w-full"
          />
          <date-calendar-icon
            v-else
            :date="event.beginsOn.toString()"
            class="w-full"
          />
        </div>

        <!-- Floating Time Icon - positioned over banner -->
        <div 
          class="absolute bg-white shadow-lg border border-gray-200 z-10 right-0 bottom-0 flex items-center gap-2"
          v-if="event?.beginsOn && event?.options.showStartTime"
        >
          <start-time-icon
            :date="event.beginsOn.toString()"
            :timezone="event.options.timezone"
            class="flex items-center gap-2"
          />
        </div>
      </div>

      <!-- Event Info Section -->
      <div
        class="flex flex-col relative pb-2 bg-white rounded-lg shadow-sm border border-gray-200"
        style="margin-bottom: 16px;"
      >

        <section class="intro" style="padding: 20px;" dir="auto">
          <div class="flex flex-wrap justify-end" style="gap: 16px;">
            <div class="flex-1 min-w-[300px]">
              <div
                v-if="eventLoading"
                class="animate-pulse mb-3 h-12 bg-slate-200 w-3/4 rounded"
              />
              <h1
                v-else
                class="text-2xl font-bold text-gray-700 m-0 mb-3"
                style="font-size: 36px; line-height: 1.33; font-family: var(--font-family-primary);"
                dir="auto"
                :lang="event?.language"
              >
                {{ event?.title }}
              </h1>
              <div class="organizer">
                <div
                  v-if="eventLoading"
                  class="animate-pulse mb-2 h-6 space-y-6 bg-slate-200 w-64"
                />
                <div v-else-if="event?.organizerActor && !event?.attributedTo">
                  <popover-actor-card
                    :actor="event.organizerActor"
                    :inline="true"
                  >
                    <i18n-t
                      keypath="By {username}"
                      dir="auto"
                      class="block truncate max-w-xs md:max-w-sm text-gray-600"
                      style="font-size: 15px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);"
                    >
                      <template #username>
                        <span dir="ltr">{{
                          displayName(event.organizerActor)
                        }}</span>
                      </template>
                    </i18n-t>
                  </popover-actor-card>
                </div>
                <span v-else-if="event?.attributedTo">
                  <popover-actor-card
                    :actor="event.attributedTo"
                    :inline="true"
                  >
                    <i18n-t
                      keypath="By {group}"
                      dir="auto"
                      class="block truncate max-w-xs md:max-w-sm text-gray-600"
                      style="font-size: 15px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);"
                    >
                      <template #group>
                        <router-link
                          :to="{
                            name: RouteName.GROUP,
                            params: {
                              preferredUsername: usernameWithDomain(
                                event.attributedTo
                              ),
                            },
                          }"
                          dir="ltr"
                          >{{ displayName(event.attributedTo) }}</router-link
                        >
                      </template>
                    </i18n-t>
                  </popover-actor-card>
                </span>
              </div>
              <div class="flex flex-wrap items-center mt-2 my-3" style="gap: 8px;">
                <div
                  v-if="eventLoading"
                  class="animate-pulse mb-2 h-6 space-y-6 bg-slate-200 w-64"
                />
                <p v-else-if="event?.status !== EventStatus.CONFIRMED">
                  <tag
                    variant="warning"
                    v-if="event?.status === EventStatus.TENTATIVE"
                    >{{ t("Event to be confirmed") }}</tag
                  >
                  <tag
                    variant="danger"
                    v-if="event?.status === EventStatus.CANCELLED"
                    >{{ t("Event cancelled") }}</tag
                  >
                </p>
                <template v-if="!eventLoading && !event?.draft">
                  <p
                    v-if="event?.visibility === EventVisibility.PUBLIC"
                    class="inline-flex gap-1 text-gray-600"
                    style="font-size: 15px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);"
                  >
                    <Earth />
                    {{ t("Public event") }}
                  </p>
                  <p
                    v-if="event?.visibility === EventVisibility.UNLISTED"
                    class="inline-flex gap-1 text-gray-600"
                    style="font-size: 15px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);"
                  >
                    <Link />
                    {{ t("Private event") }}
                  </p>
                </template>
                <template v-if="!event?.local && organizerDomain">
                  <a :href="event?.url">
                    <tag variant="info">{{ organizerDomain }}</tag>
                  </a>
                </template>
                <div
                  v-if="eventLoading"
                  class="animate-pulse mb-2 h-6 space-y-6 bg-slate-200 w-64"
                />
                <p v-else class="flex flex-wrap gap-1 items-center" dir="auto">
                  <tag v-if="eventCategory" class="category" capitalize>{{
                    eventCategory
                  }}</tag>
                  <router-link
                    class="rounded-md truncate text-sm text-violet-title py-1 bg-purple-3 category"
                    v-for="tag in event?.tags ?? []"
                    :key="tag.title"
                    :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                  >
                    <tag>{{ tag.title }}</tag>
                  </router-link>
                </p>
                <tag variant="warning" size="medium" v-if="event?.draft"
                  >{{ t("Draft") }}
                </tag>
              </div>
            </div>

            <div v-if="eventLoading">
              <div class="animate-pulse mb-2 h-6 bg-slate-200 w-64" />
              <div class="animate-pulse mb-2 h-6 bg-slate-200 w-64" />
            </div>
            <EventActionSection
              v-else-if="event"
              :event="event"
              :currentActor="currentActor"
              :participations="participations"
              :person="person"
            />
          </div>
        </section>
      </div>

      <div
        class="flex flex-col md:flex-row gap-4 w-full mt-1"
      >
        <aside
          class="rounded-lg bg-white shadow-sm border border-gray-200 h-min md:w-[300px] lg:w-[420px] xl:w-[515px] md:flex-shrink-0 md:order-2"
        >
          <div class="sticky" style="padding: 20px;">
            <aside
              v-if="eventLoading"
              class="animate-pulse rounded-lg bg-white h-min max-w-screen-sm"
            >
              <div class="mb-6 p-2" v-for="i in 3" :key="i">
                <div class="mb-3 h-6 bg-slate-200 w-64 rounded" />
                <div class="flex space-x-4 flex-row">
                  <div class="rounded-full bg-slate-200 h-10 w-10"></div>
                  <div class="flex flex-col flex-1 space-y-2">
                    <div class="h-3 bg-slate-200 rounded"></div>
                    <div class="h-3 bg-slate-200 rounded"></div>
                  </div>
                </div>
              </div>
            </aside>
            <event-metadata-sidebar
              v-else-if="event"
              :event="event"
              :user="loggedUser"
              @showMapModal="showMap = true"
            />
            
            <!-- Attendees Section in Sidebar -->
            <div 
              v-if="event && !eventLoading"
              class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden"
              style="margin-top: 16px;"
            >
              <div style="padding: 20px;">
                <h3 class="text-gray-700 mb-4" style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary);">
                  {{ t("Attendees") }}
                  <span v-if="eventParticipants && eventParticipants.length > 0" class="text-gray-500" style="font-weight: 500; font-size: 15px; font-family: var(--font-family-primary);">
                    ({{ eventParticipants.length }})
                  </span>
                  <span v-else-if="event.participantStats && (event.participantStats.going > 0 || event.participantStats.participant > 0)" class="text-gray-500" style="font-weight: 500; font-size: 15px; font-family: var(--font-family-primary);">
                    ({{ event.participantStats.going || event.participantStats.participant || 0 }})
                  </span>
                </h3>
                
                <!-- Participants List -->
                <div v-if="participantsLoading" class="text-gray-500 text-center py-6" style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
                  {{ t("Loading attendees...") }}
                </div>
                
                <div v-else-if="eventParticipants && eventParticipants.length > 0" style="display: flex; flex-direction: column; gap: 8px;">
                  <div 
                    v-for="participant in eventParticipants.slice(0, 5)" 
                    :key="participant.id"
                    class="flex items-center"
                    style="gap: 12px;"
                  >
                    <img
                      v-if="participant.actor.avatar"
                      :src="participant.actor.avatar.url"
                      :alt="displayName(participant.actor)"
                      class="rounded-full object-cover"
                      style="width: 32px; height: 32px;"
                    />
                    <div
                      v-else
                      class="rounded-full bg-gray-300 flex items-center justify-center"
                      style="width: 32px; height: 32px;"
                    >
                      <span class="font-semibold text-gray-600" style="font-size: 12px;">
                        {{ displayName(participant.actor).charAt(0).toUpperCase() }}
                      </span>
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="text-gray-900 truncate" style="font-size: 17px; line-height: 1.53; font-weight: 700; font-family: var(--font-family-primary);">
                        {{ displayName(participant.actor) }}
                      </div>
                      <div v-if="participant.actor.preferredUsername && participant.actor.preferredUsername !== 'anonymous'" class="text-gray-500 truncate" style="font-size: 15px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
                        @{{ participant.actor.preferredUsername }}
                      </div>
                    </div>
                    <tag
                      v-if="participant.role !== ParticipantRole.PARTICIPANT"
                      :variant="participant.role === ParticipantRole.CREATOR ? 'primary' : 'info'"
                      size="small"
                    >
                      {{ t(participant.role) }}
                    </tag>
                  </div>
                  
                  <!-- Show All Button -->
                  <div v-if="eventParticipants.length > 5" class="border-t border-gray-100" style="padding-top: 16px; margin-top: 16px;">
                    <button class="btn btn-secondary w-full" style="padding: 12px 16px; font-size: 17px; font-weight: 700; font-family: var(--font-family-primary);">
                      {{ t("Show all attendees") }}
                      <svg class="ml-2" style="width: 16px; height: 16px;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                  </div>
                </div>
                
                <!-- Fallback based on participant stats -->
                <div v-else-if="event.participantStats && (event.participantStats.going > 0 || event.participantStats.participant > 0)" class="text-gray-500 text-center py-6" style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
                  {{ t("Participant information will appear here once available.") }}
                </div>
                
                <!-- No participants yet -->
                <div v-else class="text-gray-500 text-center py-6" style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
                  {{ t("No participants yet. Be the first to join!") }}
                </div>
              </div>
            </div>
          </div>
        </aside>
        <div class="flex-1 md:order-1">
          <section
            class="event-description bg-white rounded-lg shadow-sm border border-gray-200"
            style="padding: 20px; margin-bottom: 16px;"
          >
            <h2 class="text-gray-700 mb-4" style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary);">{{ t("About this event") }}</h2>
            <div
              v-if="eventLoading"
              class="animate-pulse mb-3 h-4 bg-slate-200 w-3/4 rounded"
            />
            <div
              v-if="eventLoading"
              class="animate-pulse mb-3 h-4 bg-slate-200 w-3/4 rounded"
            />
            <div
              v-if="eventLoading"
              class="animate-pulse mb-3 h-4 bg-slate-200 w-1/4 rounded"
            />
            <p v-else-if="!event?.description" class="text-gray-500 italic text-center py-8" style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary);">
              {{ t("The event organizer didn't add any description.") }}
            </p>
            <div v-else>
              <div
                :lang="event?.language"
                dir="auto"
                class="prose md:prose-lg lg:prose-xl prose-h1:text-xl prose-h1:font-semibold prose-h2:text-lg prose-h3:text-base md:prose-h1:text-2xl md:prose-h1:font-semibold md:prose-h2:text-xl md:prose-h3:text-lg lg:prose-h1:text-2xl lg:prose-h1:font-semibold lg:prose-h2:text-xl lg:prose-h3:text-lg max-w-none"
                ref="eventDescriptionElement"
                v-html="event.description"
              />
            </div>
          </section>
          <section class="my-4">
            <component
              v-for="(metadata, integration) in integrations"
              :is="metadataToComponent[integration]"
              :key="integration"
              :metadata="metadata"
              class="my-2"
            />
          </section>
          

          
          <section
            class="bg-white rounded-lg shadow-sm border border-gray-200"
            style="padding: 20px; margin: 16px 0;"
            ref="commentsObserver"
          >
            <a href="#comments" class="no-underline">
              <h2 class="text-gray-700 mb-4" id="comments" style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary);">{{ t("Comments") }}</h2>
            </a>
            <comment-tree v-if="event && loadComments" :event="event" />
          </section>
        </div>
      </div>

      <section
        class="bg-white rounded-lg shadow-sm border border-gray-200"
        style="padding: 20px; margin: 16px 0;"
        v-if="(event?.relatedEvents ?? []).length > 0"
      >
        <h2 class="text-gray-700 mb-4" style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary);">
          {{ t("These events may interest you") }}
        </h2>
        <multi-card :events="event?.relatedEvents ?? []" />
      </section>
      <o-modal
        v-model:active="showMap"
        :close-button-aria-label="t('Close')"
        class="map-modal"
        v-if="event?.physicalAddress?.geom"
        has-modal-card
        full-screen
        :can-cancel="['escape', 'outside']"
      >
        <template #default>
          <event-map
            v-if="showMap"
            :routingType="routingType ?? RoutingType.OPENSTREETMAP"
            :address="event.physicalAddress"
            @close="showMap = false"
          />
        </template>
      </o-modal>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  EventStatus,
  ParticipantRole,
  RoutingType,
  EventVisibility,
} from "@/types/enums";
import {
  EVENT_PERSON_PARTICIPATION,
  // EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
} from "@/graphql/event";
import {
  displayName,
  IActor,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import DateCalendarIcon from "@/components/Event/DateCalendarIcon.vue";
import StartTimeIcon from "@/components/Event/StartTimeIcon.vue";
import SkeletonDateCalendarIcon from "@/components/Event/SkeletonDateCalendarIcon.vue";
import Earth from "vue-material-design-icons/Earth.vue";
import Link from "vue-material-design-icons/Link.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import MultiCard from "@/components/Event/MultiCard.vue";
import RouteName from "@/router/name";
import CommentTree from "@/components/Comment/CommentTree.vue";
import "intersection-observer";
import Tag from "@/components/TagElement.vue";
import EventMetadataSidebar from "@/components/Event/EventMetadataSidebar.vue";
import EventBanner from "@/components/Event/EventBanner.vue";
import EventActionSection from "@/components/Event/EventActionSection.vue";
import PopoverActorCard from "@/components/Account/PopoverActorCard.vue";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { eventMetaDataList } from "@/services/EventMetadata";
import { useFetchEvent } from "@/composition/apollo/event";
import {
  computed,
  onMounted,
  ref,
  watch,
  defineAsyncComponent,
  inject,
} from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useLoggedUser } from "@/composition/apollo/user";
import { useQuery } from "@vue/apollo-composable";
import {
  useEventCategories,
  useRoutingType,
} from "@/composition/apollo/config";
import { useI18n } from "vue-i18n";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import { useHead } from "@/utils/head";
import { useEventParticipants } from "@/composition/apollo/participants";

const IntegrationTwitch = defineAsyncComponent(
  () => import("@/components/Event/Integrations/TwitchIntegration.vue")
);
const IntegrationPeertube = defineAsyncComponent(
  () => import("@/components/Event/Integrations/PeerTubeIntegration.vue")
);
const IntegrationYoutube = defineAsyncComponent(
  () => import("@/components/Event/Integrations/YouTubeIntegration.vue")
);
const IntegrationJitsiMeet = defineAsyncComponent(
  () => import("@/components/Event/Integrations/JitsiMeetIntegration.vue")
);
const IntegrationEtherpad = defineAsyncComponent(
  () => import("@/components/Event/Integrations/EtherpadIntegration.vue")
);
const EventMap = defineAsyncComponent(
  () => import("@/components/Event/EventMap.vue")
);

const props = defineProps<{
  uuid: string;
}>();

const { t } = useI18n({ useScope: "global" });

const propsUUID = computed(() => props.uuid);

const {
  event,
  onError: onFetchEventError,
  loading: eventLoading,
  refetch: refetchEvent,
} = useFetchEvent(propsUUID);

watch(propsUUID, (newUUid) => {
  refetchEvent({ uuid: newUUid });
});

const eventId = computed(() => event.value?.id);
const { currentActor } = useCurrentActorClient();
const currentActorId = computed(() => currentActor.value?.id);
const { loggedUser } = useLoggedUser();
const {
  result: participationsResult,
  // subscribeToMore: subscribeToMoreParticipation,
} = useQuery<{ person: IPerson }>(
  EVENT_PERSON_PARTICIPATION,
  () => ({
    eventId: event.value?.id,
    actorId: currentActorId.value,
  }),
  () => ({
    enabled:
      currentActorId.value !== undefined &&
      currentActorId.value !== null &&
      eventId.value !== undefined,
  })
);

// subscribeToMoreParticipation(() => ({
//   document: EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
//   variables: {
//     eventId: eventId,
//     actorId: currentActorId,
//   },
// }));

const participations = computed(
  () => participationsResult.value?.person.participations?.elements ?? []
);

const groupFederatedUsername = computed(() =>
  usernameWithDomain(event.value?.attributedTo)
);

const { person } = usePersonStatusGroup(groupFederatedUsername);

const { eventCategories } = useEventCategories();

// Fetch event participants
const { participants: eventParticipants, loading: participantsLoading, refetch: refetchParticipants } = useEventParticipants(propsUUID, {
  limit: 50, // Show up to 50 attendees initially 
  roles: "participant,moderator,administrator,creator"
});

const identity = ref<IPerson | undefined | null>(null);

const oldParticipationRole = ref<string | undefined>(undefined);

const observer = ref<IntersectionObserver | null>(null);
const commentsObserver = ref<Element | null>(null);

const loadComments = ref(false);

const eventTitle = computed((): undefined | string => {
  return event.value?.title;
});

const eventDescription = computed((): undefined | string => {
  return event.value?.description;
});

const route = useRoute();
const router = useRouter();

const eventDescriptionElement = ref<HTMLElement | null>(null);

onMounted(async () => {
  identity.value = currentActor.value;
  if (route.hash.includes("#comment-")) {
    loadComments.value = true;
  }

  observer.value = new IntersectionObserver(
    (entries) => {
      // eslint-disable-next-line no-restricted-syntax
      for (const entry of entries) {
        if (entry) {
          loadComments.value = entry.isIntersecting || loadComments.value;
        }
      }
    },
    {
      rootMargin: "-50px 0px -50px",
    }
  );
  if (commentsObserver.value) {
    observer.value.observe(commentsObserver.value);
  }

  watch(eventDescription, () => {
    if (!eventDescription.value) return;
    if (!eventDescriptionElement.value) return;

    eventDescriptionElement.value.addEventListener("click", ($event) => {
      // TODO: Find the right type for target
      let { target }: { target: any } = $event;
      while (target && target.tagName !== "A") target = target.parentNode;
      // handle only links that occur inside the component and do not reference external resources
      if (target && target.matches(".hashtag") && target.href) {
        // some sanity checks taken from vue-router:
        // https://github.com/vuejs/vue-router/blob/dev/src/components/link.js#L106
        const { altKey, ctrlKey, metaKey, shiftKey, button, defaultPrevented } =
          $event;
        // don't handle with control keys
        if (metaKey || altKey || ctrlKey || shiftKey) return;
        // don't handle when preventDefault called
        if (defaultPrevented) return;
        // don't handle right clicks
        if (button !== undefined && button !== 0) return;
        // don't handle if `target="_blank"`
        if (target && target.getAttribute) {
          const linkTarget = target.getAttribute("target");
          if (/\b_blank\b/i.test(linkTarget)) return;
        }
        // don't handle same page links/anchors
        const url = new URL(target.href);
        const to = url.pathname;
        if (window.location.pathname !== to && $event.preventDefault) {
          $event.preventDefault();
          router.push(to);
        }
      }
    });
  });

  // this.$on("event-deleted", () => {
  //   return router.push({ name: RouteName.HOME });
  // });
});

const notifier = inject<Notifier>("notifier");

watch(participations, (newParticipations, oldParticipations) => {
  // Refresh participants list when participation status changes
  if (newParticipations.length !== oldParticipations?.length) {
    refetchParticipants();
  }
  
  if (newParticipations.length > 0) {
    if (
      oldParticipationRole.value &&
      newParticipations[0].role !== ParticipantRole.NOT_APPROVED &&
      oldParticipationRole.value !== newParticipations[0].role
    ) {
      switch (newParticipations[0].role) {
        case ParticipantRole.PARTICIPANT:
          participationConfirmedMessage();
          break;
        case ParticipantRole.REJECTED:
          participationRejectedMessage();
          break;
        default:
          participationChangedMessage();
          break;
      }
      // Refresh participants list when role changes
      refetchParticipants();
    }
    oldParticipationRole.value = newParticipations[0].role;
  } else if (oldParticipationRole.value !== undefined) {
    // User left the event, refresh participants list and clear the old role
    refetchParticipants();
    oldParticipationRole.value = undefined;
  }
});

const participationConfirmedMessage = () => {
  notifier?.success(t("Your participation has been confirmed"));
};

const participationRejectedMessage = () => {
  notifier?.error(t("Your participation has been rejected"));
};

const participationChangedMessage = () => {
  notifier?.info(t("Your participation status has been changed"));
};

const handleErrors = (errors: AbsintheGraphQLErrors): void => {
  if (
    errors.some((error) => error.status_code === 404) ||
    errors.some(({ message }) => message.includes("has invalid value $uuid"))
  ) {
    router.replace({ name: RouteName.PAGE_NOT_FOUND });
  }
};

onFetchEventError(({ graphQLErrors }) =>
  handleErrors(graphQLErrors as AbsintheGraphQLErrors)
);

const metadataToComponent: Record<string, any> = {
  "mz:live:twitch:url": IntegrationTwitch,
  "mz:live:peertube:url": IntegrationPeertube,
  "mz:live:youtube:url": IntegrationYoutube,
  "mz:visio:jitsi_meet": IntegrationJitsiMeet,
  "mz:notes:etherpad:url": IntegrationEtherpad,
};

const integrations = computed((): Record<string, IEventMetadataDescription> => {
  return (event.value?.metadata ?? [])
    .map((val) => {
      const def = eventMetaDataList.find((dat) => dat.key === val.key);
      return {
        ...def,
        ...val,
      };
    })
    .reduce((acc: Record<string, IEventMetadataDescription>, metadata) => {
      const component = metadataToComponent[metadata.key];
      if (component !== undefined) {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        acc[metadata.key] = metadata;
      }
      return acc;
    }, {});
});

const showMap = ref(false);

const { routingType } = useRoutingType();

const eventCategory = computed((): string | undefined => {
  if (event.value?.category === "MEETING") {
    return undefined;
  }
  return (eventCategories.value ?? []).find((eventCategoryToFind) => {
    return eventCategoryToFind.id === event.value?.category;
  })?.label as string;
});

const organizer = computed((): IActor | null => {
  if (event.value?.attributedTo?.id) {
    return event.value.attributedTo;
  }
  if (event.value?.organizerActor) {
    return event.value.organizerActor;
  }
  return null;
});

const organizerDomain = computed((): string | undefined => {
  return organizer.value?.domain ?? undefined;
});

useHead({
  title: computed(() => eventTitle.value ?? ""),
  meta: [{ name: "description", content: eventDescription.value }],
});
</script>
<style>
.event-description a {
  @apply inline-block p-1 bg-mbz-yellow-alt-200 text-black;
}

.event-description .mention.h-card {
  @apply inline-block border border-gray-300 rounded py-0.5 px-1;
}
</style>
