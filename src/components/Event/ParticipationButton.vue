<template>
  <div class="ml-auto w-min">
    <o-dropdown
      v-if="participation && participation.role === ParticipantRole.PARTICIPANT"
    >
      <template #trigger="{ active }">
        <o-button
          variant="success"
          size="large"
          icon-left="check"
          :icon-right="active ? 'menu-up' : 'menu-down'"
        >
          {{ t("I participate") }}
        </o-button>
      </template>

      <o-dropdown-item
        :value="false"
        aria-role="listitem"
        @click="confirmLeave"
        @keyup.enter="confirmLeave"
        class=""
        >{{ t("Cancel my participation…") }}
      </o-dropdown-item>
    </o-dropdown>

    <div
      v-else-if="
        participation && participation.role === ParticipantRole.NOT_APPROVED
      "
      class="flex flex-col"
    >
      <o-dropdown>
        <template #trigger>
          <o-button variant="success" size="large" type="button">
            <template class="flex items-center">
              <TimerSandEmpty />
              <span>{{ t("I participate") }}</span>
              <MenuDown />
            </template>
          </o-button>
        </template>

        <o-dropdown-item :value="false" aria-role="listitem">
          {{ t("Change my identity…") }}
        </o-dropdown-item>

        <o-dropdown-item
          :value="false"
          aria-role="listitem"
          @click="confirmLeave"
          @keyup.enter="confirmLeave"
          class=""
          >{{ t("Cancel my participation request…") }}</o-dropdown-item
        >
      </o-dropdown>
      <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-4">
        <div class="flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              class="text-amber-500"
            >
              <circle
                cx="12"
                cy="12"
                r="10"
                fill="currentColor"
                fill-opacity="0.1"
              />
              <path
                d="M12 6v6l4 2"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="font-medium text-amber-800 text-sm mb-1">
              {{ t("Participation requested!") }}
            </h3>
            <p class="text-amber-700 text-sm leading-relaxed">
              {{ t("Waiting for organization team approval.") }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      v-else-if="
        participation && participation.role === ParticipantRole.WAITLIST
      "
      class="flex flex-col"
    >
      <o-dropdown>
        <template #trigger>
          <o-button variant="warning" size="large" type="button">
            <template class="flex items-center">
              <TimerSandEmpty />
              <span>{{ t("On waitlist") }}</span>
              <MenuDown />
            </template>
          </o-button>
        </template>

        <o-dropdown-item
          :value="false"
          aria-role="listitem"
          @click="confirmLeave"
          @keyup.enter="confirmLeave"
          class=""
          >{{ t("Leave waitlist") }}</o-dropdown-item
        >
      </o-dropdown>
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
        <div class="flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              class="text-blue-500"
            >
              <circle
                cx="12"
                cy="12"
                r="10"
                fill="currentColor"
                fill-opacity="0.1"
              />
              <path
                d="M12 6v6l4 2"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </div>
          <div class="min-w-[200px]">
            <h3 class="font-medium text-blue-800 text-sm mb-1">
              {{ t("You're on the waitlist") }}
            </h3>
            <p class="text-blue-700 text-sm leading-relaxed">
              {{
                t(
                  "You'll be notified if a spot becomes available for this event."
                )
              }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      v-else-if="
        participation && participation.role === ParticipantRole.REJECTED
      "
      class="bg-red-50 border border-red-200 rounded-lg p-4 mb-4"
    >
      <div class="flex items-start gap-3">
        <div class="flex-shrink-0">
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            class="text-red-500"
          >
            <circle
              cx="12"
              cy="12"
              r="10"
              fill="currentColor"
              fill-opacity="0.1"
            />
            <path
              d="M15 9l-6 6M9 9l6 6"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </div>
        <div class="min-w-[200px]">
          <h3 class="font-medium text-red-800 text-sm mb-1">
            {{ t("Participation rejected") }}
          </h3>
          <p class="text-red-700 text-sm leading-relaxed">
            {{
              t(
                "Unfortunately, your participation request was rejected by the organizers."
              )
            }}
          </p>
        </div>
      </div>
    </div>

    <o-dropdown v-else-if="!participation && currentActor?.id">
      <template #trigger="{ active }">
        <o-button
          variant="primary"
          size="large"
          :icon-right="active ? 'menu-up' : 'menu-down'"
          :disabled="
            event.options.blockNewRegistrations ||
            (isEventFull && !event.options.enableWaitlist)
          "
        >
          <span v-if="event.options.blockNewRegistrations">
            {{ t("Registrations blocked") }}
          </span>
          <span v-else-if="isEventFull && event.options.enableWaitlist">
            {{ t("Join waitlist") }}
          </span>
          <span v-else-if="isEventFull">
            {{ t("Event full") }}
          </span>
          <span v-else>
            {{ t("Participate") }}
          </span>
        </o-button>
      </template>

      <o-dropdown-item
        :value="true"
        aria-role="listitem"
        @click="joinEvent(currentActor)"
        @keyup.enter="joinEvent(currentActor)"
        v-if="
          !event.options.blockNewRegistrations &&
          (!isEventFull || event.options.enableWaitlist)
        "
      >
        <div class="flex gap-2 items-center">
          <figure
            class="w-6 h-6 rounded-full overflow-hidden"
            v-if="currentActor?.avatar"
          >
            <img
              class="w-full h-full object-cover rounded-full"
              :src="currentActor.avatar.url"
              alt=""
            />
          </figure>
          <AccountCircle v-else style="border-radius: 50%" />
          <div class="">
            <span>
              {{
                t("as {identity}", {
                  identity: displayName(currentActor),
                })
              }}
            </span>
          </div>
        </div>
      </o-dropdown-item>
    </o-dropdown>
    <o-button
      rel="nofollow"
      tag="router-link"
      :to="{
        name: RouteName.EVENT_PARTICIPATE_LOGGED_OUT,
        params: { uuid: event.uuid },
      }"
      v-else-if="
        !participation &&
        hasAnonymousParticipationMethods &&
        !event.options.blockNewRegistrations &&
        (!isEventFull || event.options.enableWaitlist)
      "
      variant="primary"
      size="large"
      native-type="button"
      >{{
        isEventFull && event.options.enableWaitlist
          ? t("Join waitlist")
          : t("Participate")
      }}</o-button
    >
    <o-button
      v-else-if="
        !participation &&
        hasAnonymousParticipationMethods &&
        (event.options.blockNewRegistrations ||
          (isEventFull && !event.options.enableWaitlist))
      "
      variant="secondary"
      size="large"
      disabled
      >{{
        event.options.blockNewRegistrations
          ? t("Registrations blocked")
          : t("Event full")
      }}</o-button
    >
    <o-button
      tag="router-link"
      rel="nofollow"
      :to="{
        name: RouteName.LOGIN,
        params: { uuid: event.uuid },
      }"
      v-else-if="!currentActor?.id"
      variant="primary"
      size="large"
      native-type="button"
      >{{ t("Participate") }}</o-button
    >
  </div>
</template>

<script lang="ts" setup>
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import { IEvent } from "../../types/event.model";
import { IPerson, displayName } from "../../types/actor";
import RouteName from "../../router/name";
import { computed, watch, onMounted } from "vue";
import MenuDown from "vue-material-design-icons/MenuDown.vue";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import TimerSandEmpty from "vue-material-design-icons/TimerSandEmpty.vue";

const props = defineProps<{
  participation: IParticipant | undefined;
  event: IEvent;
  currentActor: IPerson | undefined;
  identities: IPerson[] | undefined;
}>();

const emit = defineEmits([
  "join-event-with-confirmation",
  "join-event",
  "join-modal",
  "confirm-leave",
]);

const { t } = useI18n({ useScope: "global" });

const joinEvent = (actor: IPerson | undefined): void => {
  if (props.event.joinOptions === EventJoinOptions.RESTRICTED) {
    emit("join-event-with-confirmation", actor);
  } else {
    // For waitlist or regular participation, just emit join-event
    // The backend will handle whether to add to participants or waitlist
    emit("join-event", actor);
  }
};

const confirmLeave = (): void => {
  emit("confirm-leave");
};

const hasAnonymousParticipationMethods = computed((): boolean => {
  return props.event.options.anonymousParticipation;
});

// Logging function
const logParticipationButtonState = () => {
  console.log("🔍 ParticipationButton Debug:", {
    eventTitle: props.event.title,
    participation: props.participation,
    currentActor: props.currentActor,
    isEventFull: isEventFull.value,
    enableWaitlist: props.event.options.enableWaitlist,
    blockNewRegistrations: props.event.options.blockNewRegistrations,
    maxCapacity: props.event.options.maximumAttendeeCapacity,
    currentParticipants: props.event.participantStats.participant,
    conditions: {
      "has currentActor": !!props.currentActor?.id,
      "no participation": !props.participation,
      "event is full": isEventFull.value,
      "waitlist enabled": props.event.options.enableWaitlist,
      "registrations blocked": props.event.options.blockNewRegistrations,
      "should show dropdown": !props.participation && !!props.currentActor?.id,
      "button enabled":
        !props.event.options.blockNewRegistrations &&
        (!isEventFull.value || props.event.options.enableWaitlist),
    },
  });
};

const isEventFull = computed((): boolean => {
  const maxCapacity = props.event.options.maximumAttendeeCapacity;
  const currentParticipants = props.event.participantStats.participant;

  console.log("🔍 isEventFull calculation:", {
    maxCapacity,
    currentParticipants,
    isFull: currentParticipants >= maxCapacity,
  });

  if (!maxCapacity || maxCapacity === 0) {
    console.log("❌ No capacity limit set");
    return false;
  }

  const isFull = currentParticipants >= maxCapacity;
  console.log(
    `${isFull ? "🚫" : "✅"} Event is ${isFull ? "FULL" : "NOT FULL"}`
  );
  return isFull;
});

// Debug watchers
onMounted(() => {
  logParticipationButtonState();
});

watch(
  () => [props.event.options, props.participation, props.currentActor],
  () => {
    logParticipationButtonState();
  },
  { deep: true }
);
</script>
