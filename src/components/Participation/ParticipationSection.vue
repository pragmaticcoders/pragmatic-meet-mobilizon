<template>
  <div>
    <div class="event-participation" v-if="isEventNotAlreadyPassed">
      <participation-button
        v-if="shouldShowParticipationButton"
        :participation="participation"
        :event="event"
        :current-actor="currentActor"
        @join-event="(actor) => $emit('join-event', actor)"
        @join-modal="$emit('join-modal')"
        @join-event-with-confirmation="
          (actor) => $emit('join-event-with-confirmation', actor)
        "
        @confirm-leave="$emit('confirm-leave')"
      />
      <o-button
        variant="text"
        v-if="!actorIsParticipant && anonymousParticipation !== null"
        @click="$emit('cancel-anonymous-participation')"
        >{{ t("Cancel anonymous participation") }}</o-button
      >
      <small v-if="!actorIsParticipant && anonymousParticipation">
        {{ t("You are participating in this event anonymously") }}
        <VTooltip>
          <template #popper>
            {{ t("Click for more information") }}
          </template>
          <span @click="isAnonymousParticipationModalOpen = true">
            <InformationOutline :size="16" />
          </span>
        </VTooltip>
      </small>
      <small
        v-else-if="!actorIsParticipant && anonymousParticipation === false"
      >
        {{
          t(
            "You are participating in this event anonymously but didn't confirm participation"
          )
        }}
        <VTooltip>
          <template #popper>
            {{
              t(
                "This information is saved only on your computer. Click for details"
              )
            }}
          </template>
          <router-link :to="{ name: RouteName.TERMS }">
            <HelpCircleOutline :size="16" />
          </router-link>
        </VTooltip>
      </small>
    </div>
    <div v-else>
      <o-button variant="primary" disabled icon-left="menu-down">
        {{ t("Event already passed") }}
      </o-button>
    </div>
    <o-modal
      v-model:active="isAnonymousParticipationModalOpen"
      has-modal-card
      :close-button-aria-label="t('Close')"
      ref="anonymous-participation-modal"
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">
            {{ t("About anonymous participation") }}
          </p>
        </header>

        <section class="modal-card-body">
          <o-notification
            variant="primary"
            :closable="false"
            v-if="event.joinOptions === EventJoinOptions.RESTRICTED"
          >
            {{
              t(
                "As the event organizer has chosen to manually validate participation requests, your participation will be really confirmed only once you receive an email stating it's being accepted."
              )
            }}
          </o-notification>
          <p>
            {{
              t(
                "Your participation status is saved only on this device and will be deleted one month after the event's passed."
              )
            }}
          </p>
          <p v-if="isSecureContext()">
            {{
              t(
                "You may clear all participation information for this device with the buttons below."
              )
            }}
          </p>
          <div class="buttons" v-if="isSecureContext()">
            <o-button
              variant="danger"
              outlined
              @click="clearEventParticipationData"
            >
              {{ t("Clear participation data for this event") }}
            </o-button>
            <o-button variant="danger" @click="clearAllParticipationData">
              {{ t("Clear participation data for all events") }}
            </o-button>
          </div>
        </section>
      </div>
    </o-modal>
  </div>
</template>
<script lang="ts" setup>
import { EventJoinOptions, EventStatus, ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import RouteName from "@/router/name";
import { IEvent } from "@/types/event.model";
import {
  removeAllAnonymousParticipations,
  removeAnonymousParticipation,
} from "@/services/AnonymousParticipationStorage";
import ParticipationButton from "../Event/ParticipationButton.vue";
import { computed, ref, watch, onMounted } from "vue";
import InformationOutline from "vue-material-design-icons/InformationOutline.vue";
import HelpCircleOutline from "vue-material-design-icons/HelpCircleOutline.vue";
import { useI18n } from "vue-i18n";
import { IPerson } from "@/types/actor";
import { IAnonymousParticipationConfig } from "@/types/config.model";

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    participation: IParticipant | undefined;
    event: IEvent;
    anonymousParticipation?: boolean | null;
    currentActor: IPerson | undefined;
    anonymousParticipationConfig?: IAnonymousParticipationConfig | null;
  }>(),
  {
    anonymousParticipation: null,
  }
);

const isAnonymousParticipationModalOpen = ref(false);

// Logging function
const logParticipationSectionState = () => {
  console.log("🔍 ParticipationSection Debug:", {
    eventTitle: props.event.title,
    participation: props.participation,
    currentActor: props.currentActor,
    anonymousParticipation: props.anonymousParticipation,
    anonymousParticipationConfig: props.anonymousParticipationConfig,
    actorIsParticipant: actorIsParticipant.value,
    actorIsOrganizer: actorIsOrganizer.value,
    shouldShowParticipationButton: shouldShowParticipationButton.value,
    eventCapacityOK: eventCapacityOK.value,
    isEventNotAlreadyPassed: isEventNotAlreadyPassed.value,
    eventStatus: props.event.status,
    eventDraft: props.event.draft,
    maxCapacity: props.event.options.maximumAttendeeCapacity,
    currentParticipants: props.event.participantStats.participant,
  });
};

const actorIsParticipant = computed((): boolean => {
  if (actorIsOrganizer.value) return true;

  return props.participation?.role === ParticipantRole.PARTICIPANT;
});

const actorIsOrganizer = computed((): boolean => {
  return props.participation?.role === ParticipantRole.CREATOR;
});

const shouldShowParticipationButton = computed((): boolean => {
  console.log("🔍 shouldShowParticipationButton logic:", {
    anonymousConfigAllowed: props.anonymousParticipationConfig?.allowed,
    anonymousParticipation: props.anonymousParticipation,
    actorIsParticipant: actorIsParticipant.value,
    eventDraft: props.event.draft,
    eventStatus: props.event.status,
    eventCapacityOK: eventCapacityOK.value,
    enableWaitlist: props.event.options.enableWaitlist,
    isEventFull: !eventCapacityOK.value,
  });

  // If we have an anonymous participation, don't show the participation button
  if (
    props.anonymousParticipationConfig?.allowed &&
    props.anonymousParticipation
  ) {
    console.log("❌ Hidden: Anonymous participation active");
    return false;
  }

  // So that people can cancel their participation (including waitlist)
  if (
    actorIsParticipant.value ||
    props.participation?.role === ParticipantRole.WAITLIST
  ) {
    console.log("✅ Shown: User is participant or on waitlist");
    return true;
  }

  // You can't participate to draft or cancelled events
  if (props.event.draft || props.event.status === EventStatus.CANCELLED) {
    console.log("❌ Hidden: Event is draft or cancelled");
    return false;
  }

  // If capacity is OK, show button
  if (eventCapacityOK.value) {
    console.log("✅ Shown: Event has capacity");
    return true;
  }

  // If event is full but waitlist is enabled, show button
  if (!eventCapacityOK.value && props.event.options.enableWaitlist) {
    console.log("✅ Shown: Event full but waitlist enabled");
    return true;
  }

  // Event is full and no waitlist
  console.log("❌ Hidden: Event full and no waitlist");
  return false;
});

const eventCapacityOK = computed((): boolean => {
  if (props.event.draft) return true;
  if (!props.event.options.maximumAttendeeCapacity) return true;
  return (
    props.event.options.maximumAttendeeCapacity >
    props.event.participantStats.participant
  );
});

const isEventNotAlreadyPassed = computed((): boolean => {
  return new Date(endDate.value) > new Date();
});

const endDate = computed((): string => {
  return props.event.endsOn !== null &&
    props.event.endsOn > props.event.beginsOn
    ? props.event.endsOn
    : props.event.beginsOn;
});

const isSecureContext = (): boolean => {
  return window.isSecureContext;
};

const clearEventParticipationData = async (): Promise<void> => {
  await removeAnonymousParticipation(props.event.uuid);
  window.location.reload();
};

const clearAllParticipationData = (): void => {
  removeAllAnonymousParticipations();
  window.location.reload();
};

// Debug watchers
onMounted(() => {
  logParticipationSectionState();
});

watch(
  () => [props.event.options, props.participation, props.currentActor],
  () => {
    logParticipationSectionState();
  },
  { deep: true }
);
</script>
