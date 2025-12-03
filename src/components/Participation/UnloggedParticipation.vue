<template>
  <section v-if="isUserSignedIn">
    <div class="message-box">
      <div class="spinner"></div>
      <span>Redirecting to event page...</span>
    </div>
  </section>
  <section class="container mx-auto max-w-2xl" v-else>
    <h2 class="text-2xl">
      {{ t("You wish to participate to the following event") }}
    </h2>
    <EventListViewCard v-if="event" :event="event" />
    <div class="flex flex-wrap gap-4 items-center w-full my-6">
      <div class="bg-white dark:bg-zinc-700 rounded-md p-4 flex-1">
        <router-link :to="{ name: RouteName.EVENT_PARTICIPATE_WITH_ACCOUNT }">
          <figure class="flex justify-center my-2">
            <img
              src="/img/undraw_profile.svg"
              alt="Profile illustration"
              width="128"
              height="128"
            />
          </figure>
          <o-button variant="primary">{{
            t("I have a Mobilizon account")
          }}</o-button>
        </router-link>
        <p>
          <small>
            {{
              t("Either on the {instance} instance or on another instance.", {
                instance: host,
              })
            }}
          </small>
          <o-tooltip
            variant="dark"
            :label="
              t(
                'Mobilizon is a federated network. You can interact with this event from a different server.'
              )
            "
          >
            <o-icon size="small" icon="help-circle-outline" />
          </o-tooltip>
        </p>
      </div>
      <div
        class="bg-white dark:bg-zinc-700 rounded-md p-4 flex-1"
        v-if="
          event &&
          anonymousParticipationAllowed &&
          hasAnonymousEmailParticipationMethod
        "
      >
        <router-link
          :to="{ name: RouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT }"
          v-if="event.local"
        >
          <figure class="flex justify-center my-2">
            <img
              width="128"
              height="128"
              src="/img/undraw_mail_2.svg"
              alt="Privacy illustration"
            />
          </figure>
          <o-button variant="primary">{{
            t("I don't have a Mobilizon account")
          }}</o-button>
        </router-link>
        <a :href="`${event.url}/participate/without-account`" v-else>
          <figure class="flex justify-center my-2">
            <img
              src="/img/undraw_mail_2.svg"
              width="128"
              height="128"
              alt="Privacy illustration"
            />
          </figure>
          <o-button variant="primary">{{
            t("I don't have a Mobilizon account")
          }}</o-button>
        </a>
        <p>
          <small>{{ t("Participate using your email address") }}</small>
          <br />
          <small v-if="!event.local">
            {{ t("You will be redirected to the original instance") }}
          </small>
        </p>
      </div>
    </div>
    <div class="has-text-centered">
      <o-button tag="a" variant="text" @click="router.go(-1)">{{
        t("Back to previous page")
      }}</o-button>
    </div>
  </section>
</template>
<script lang="ts" setup>
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useAnonymousParticipationConfig } from "@/composition/apollo/config";
import { useFetchEvent } from "@/composition/apollo/event";
import { useCurrentUserClient } from "@/composition/apollo/user";
import {
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
  JOIN_EVENT,
} from "@/graphql/event";
import { HOME_USER_QUERIES } from "@/graphql/home";
import { Notifier } from "@/plugins/notifier";
import { IPerson } from "@/types/actor";
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { IParticipant } from "@/types/participant.model";
import { useHead } from "@/utils/head";
import { ApolloCache } from "@apollo/client/cache";
import { FetchResult } from "@apollo/client/core";
import { useOruga } from "@oruga-ui/oruga-next";
import { useMutation } from "@vue/apollo-composable";
import { computed, inject, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import RouteName from "../../router/name";

const props = defineProps<{ uuid: string }>();

const { event } = useFetchEvent(computed(() => props.uuid));

const { anonymousParticipationConfig } = useAnonymousParticipationConfig();

const { currentUser } = useCurrentUserClient();
const { currentActor } = useCurrentActorClient();

const router = useRouter();

const notifier = inject<Notifier>("notifier");

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Unlogged participation")),
  meta: [{ name: "robots", content: "noindex" }],
});

const host = computed((): string => {
  return window.location.hostname;
});

const anonymousParticipationAllowed = computed((): boolean | undefined => {
  return event.value?.options.anonymousParticipation;
});

const hasAnonymousEmailParticipationMethod = computed(
  (): boolean | undefined => {
    return (
      anonymousParticipationConfig.value?.allowed &&
      anonymousParticipationConfig.value?.validation.email.enabled
    );
  }
);

const emit = defineEmits(["join-event-with-confirmation", "join-event"]);

const {
  mutate: joinEventMutation,
  onDone: onJoinEventMutationDone,
  onError: onJoinEventMutationError,
} = useMutation<{
  joinEvent: IParticipant;
}>(JOIN_EVENT, () => ({
  update: (
    store: ApolloCache<{
      joinEvent: IParticipant;
    }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;

    const participationCachedData = store.readQuery<{ person: IPerson }>({
      query: EVENT_PERSON_PARTICIPATION,
      variables: { eventId: event.value?.id, actorId: currentActor.value?.id },
    });

    if (participationCachedData?.person == undefined) {
      console.error(
        "Cannot update participation cache, because of null value."
      );
      return;
    }
    store.writeQuery({
      query: EVENT_PERSON_PARTICIPATION,
      variables: { eventId: event.value?.id, actorId: currentActor.value?.id },
      data: {
        person: {
          ...participationCachedData?.person,
          participations: {
            elements: [data.joinEvent],
            total: 1,
          },
        },
      },
    });

    const cachedData = store.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT,
      variables: { uuid: event.value?.uuid },
    });
    if (cachedData == null) return;
    const { event: cachedEvent } = cachedData;
    if (cachedEvent === null) {
      console.error(
        "Cannot update event participant cache, because of null value."
      );
      return;
    }
    const participantStats = { ...cachedEvent.participantStats };

    if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
      participantStats.notApproved += 1;
    } else if (data.joinEvent.role === ParticipantRole.WAITLIST) {
      // Waitlist participants don't count toward the participant count
      // They will be moved to participants when spots become available
    } else {
      participantStats.going += 1;
      participantStats.participant += 1;
    }

    store.writeQuery({
      query: FETCH_EVENT,
      variables: { uuid: event.value?.uuid },
      data: {
        event: {
          ...cachedEvent,
          participantStats,
        },
      },
    });

    // Update HOME_USER_QUERIES cache to immediately show the event on home page
    try {
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const afterDateTime = todayStart.toISOString();

      let homeData;
      try {
        homeData = store.readQuery({
          query: HOME_USER_QUERIES,
          variables: { afterDateTime },
        });
      } catch (readError) {
        console.debug("HOME_USER_QUERIES not in cache, will evict to force refetch");
        homeData = null;
      }

      if (homeData?.loggedUser?.participations?.elements) {
        const updatedHomeData = {
          ...homeData,
          loggedUser: {
            ...homeData.loggedUser,
            participations: {
              ...homeData.loggedUser.participations,
              total: homeData.loggedUser.participations.total + 1,
              elements: [
                data.joinEvent,
                ...homeData.loggedUser.participations.elements,
              ],
            },
          },
        };

        store.writeQuery({
          query: HOME_USER_QUERIES,
          variables: { afterDateTime },
          data: updatedHomeData,
        });
        console.debug("Successfully updated HOME_USER_QUERIES cache with new participation");
      } else {
        console.debug("HOME_USER_QUERIES cache miss, evicting to force refetch");
        store.evict({ fieldName: "loggedUser" });
        store.gc();
      }
    } catch (error) {
      console.warn("Failed to update HOME_USER_QUERIES cache:", error);
      store.evict({ fieldName: "loggedUser" });
      store.gc();
    }
  },
}));

const participationRequestedMessage = () => {
  notifier?.success(t("Your participation has been requested"));
};

const participationConfirmedMessage = () => {
  notifier?.success(t("Your participation has been confirmed"));
};

const participationWaitlistMessage = () => {
  notifier?.info(t("You have been added to the waitlist"));
};

onJoinEventMutationDone(async ({ data }) => {
  await router.replace({
    name: RouteName.EVENT,
    params: { uuid: props.uuid },
  });

  if (data) {
    if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
      participationRequestedMessage();
    } else if (data.joinEvent.role === ParticipantRole.WAITLIST) {
      participationWaitlistMessage();
    } else {
      participationConfirmedMessage();
    }
  }
});

const { notification } = useOruga();

onJoinEventMutationError(async (error) => {
  await router.replace({
    name: RouteName.EVENT,
    params: { uuid: props.uuid },
  });

  if (error.message) {
    notification.open({
      message: error.message,
      variant: "danger",
      position: "bottom-right",
      duration: 5000,
    });
  }
  console.error(error);
});

const joinEvent = (actor: IPerson | undefined): void => {
  if (event.value?.joinOptions === EventJoinOptions.RESTRICTED) {
    /**
     * 
     *         @join-event="(actor) => $emit('join-event', actor)"
        @join-modal="$emit('join-modal')"
        @join-event-with-confirmation="
          (actor) => $emit('join-event-with-confirmation', actor)
        "
     */
    emit("join-event-with-confirmation", actor);
  } else {
    // For waitlist or regular participation, just emit join-event
    // The backend will handle whether to add to participants or waitlist
    joinEventMutation({
      eventId: event.value?.id,
      actorId: currentActor.value?.id,
    });
  }
};

const isUserSignedIn = computed((): boolean => {
  return currentUser.value?.isLoggedIn ?? false;
});
watch(isUserSignedIn, async (isSignedIn) => {
  if (isSignedIn && currentActor.value) {
    joinEvent(currentActor.value);
  }
});
</script>
<style lang="scss" scoped>
.column > a {
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>
<style lang="scss" scoped>
.message-box {
  background-color: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 0.25rem;
  color: #92400e;
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner {
  width: 1rem;
  height: 1rem;
  border: 2px solid #92400e;
  border-top: 2px solid transparent;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 0.5rem;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
