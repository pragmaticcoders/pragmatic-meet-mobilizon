<template>
  <article
    class="bg-white dark:bg-zinc-800 shadow-sm border border-gray-200 dark:border-zinc-700 overflow-hidden mb-4"
  >
    <router-link
      :to="{
        name: RouteName.EVENT,
        params: { uuid: participation.event.uuid },
      }"
      class="block"
    >
      <div class="relative h-48 bg-gray-100 dark:bg-zinc-900">
        <lazy-image-wrapper
          v-if="participation.event.picture"
          :picture="participation.event.picture"
          class="w-full h-full object-cover"
        />
        <div v-else class="w-full h-full flex items-center justify-center">
          <svg
            width="64"
            height="64"
            viewBox="0 0 48 48"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            class="text-gray-300"
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
          </svg>
        </div>
      </div>
    </router-link>
    <div class="p-4">
      <div class="flex justify-between items-start mb-2">
        <router-link
          :to="{
            name: RouteName.EVENT,
            params: { uuid: participation.event.uuid },
          }"
          class="flex-1"
        >
          <h3
            class="text-lg font-semibold text-gray-900 dark:text-white line-clamp-2"
          >
            {{ participation.event.title }}
          </h3>
        </router-link>
        <div
          class="ml-2 flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400"
        >
          <span class="bg-gray-100 dark:bg-zinc-700 px-2 py-1">
            {{
              new Date(participation.event.beginsOn).toLocaleDateString(
                "pl-PL",
                { day: "numeric", month: "short" }
              )
            }}
          </span>
        </div>
      </div>
      <div
        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-3"
      >
        <div class="flex items-center gap-1">
          <figure v-if="actorAvatarURL" class="w-5 h-5">
            <img
              class="w-full h-full object-cover"
              :src="actorAvatarURL"
              alt=""
            />
          </figure>
          <AccountCircle v-else class="w-5 h-5" />
          <span>{{ organizerDisplayName(participation.event) }}</span>
        </div>
        <span class="text-gray-400">•</span>
        <div class="flex items-center gap-3">
          <AccountGroup class="w-4 h-4" />
          <span
            >{{ participation.event.participantStats.participant }}
            {{
              t(
                "uczestnik(-czka)",
                participation.event.participantStats.participant
              )
            }}</span
          >
        </div>
      </div>
      <div class="flex gap-2">
        <Tag
          variant="info"
          size="small"
          v-if="participation.event.status === EventStatus.TENTATIVE"
        >
          {{ t("Tentative") }}
        </Tag>
        <Tag
          variant="danger"
          size="small"
          v-if="participation.event.status === EventStatus.CANCELLED"
        >
          {{ t("Cancelled") }}
        </Tag>
        <o-dropdown aria-role="list" class="ml-auto">
          <template #trigger>
            <o-button variant="text" icon-right="dots-vertical" size="small" />
          </template>
          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
            @click="
              gotToWithCheck(participation, {
                name: RouteName.EDIT_EVENT,
                params: { eventId: participation.event.uuid },
              })
            "
          >
            <div class="flex gap-1">
              <Pencil />
              {{ t("Edit") }}
            </div>
          </o-dropdown-item>
          <o-dropdown-item
            aria-role="listitem"
            v-if="participation.role === ParticipantRole.CREATOR"
            @click="
              gotToWithCheck(participation, {
                name: RouteName.DUPLICATE_EVENT,
                params: { eventId: participation.event.uuid },
              })
            "
          >
            <div class="flex gap-1">
              <ContentDuplicate />
              {{ t("Duplicate") }}
            </div>
          </o-dropdown-item>
          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
            @click="openDeleteEventModalWrapper"
          >
            <div class="flex gap-1">
              <Delete />
              {{ t("Delete") }}
            </div>
          </o-dropdown-item>
          <o-dropdown-item
            aria-role="listitem"
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
            @click="
              gotToWithCheck(participation, {
                name: RouteName.PARTICIPATIONS,
                params: { eventId: participation.event.uuid },
              })
            "
          >
            <div class="flex gap-1">
              <AccountMultiplePlus />
              {{ t("Manage participations") }}
            </div>
          </o-dropdown-item>
          <o-dropdown-item
            aria-role="listitem"
            has-link
            v-if="
              ![
                ParticipantRole.PARTICIPANT,
                ParticipantRole.NOT_APPROVED,
              ].includes(participation.role)
            "
            @click="
              router.push({
                name: RouteName.ANNOUNCEMENTS,
                params: { eventId: participation.event?.uuid },
              })
            "
          >
            <Bullhorn />
            {{ t("Announcements") }}
          </o-dropdown-item>
          <o-dropdown-item
            aria-role="listitem"
            @click="
              router.push({
                name: RouteName.EVENT,
                params: { eventId: participation.event.uuid },
              })
            "
          >
            <ViewCompact />
            {{ t("View event page") }}
          </o-dropdown-item>
        </o-dropdown>
      </div>
    </div>
  </article>
</template>

<script lang="ts" setup>
import { EventStatus, ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import {
  IEvent,
  IEventCardOptions,
  organizerAvatarUrl,
  organizerDisplayName,
} from "@/types/event.model";
import { IPerson } from "@/types/actor";
import RouteName from "@/router/name";
import { changeIdentity } from "@/utils/identity";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import { RouteLocationRaw, useRouter } from "vue-router";
import Pencil from "vue-material-design-icons/Pencil.vue";
import ContentDuplicate from "vue-material-design-icons/ContentDuplicate.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import AccountMultiplePlus from "vue-material-design-icons/AccountMultiplePlus.vue";
import ViewCompact from "vue-material-design-icons/ViewCompact.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import { useOruga } from "@oruga-ui/oruga-next";
import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import { Dialog } from "@/plugins/dialog";
import { Snackbar } from "@/plugins/snackbar";
import { useDeleteEvent } from "@/composition/apollo/event";
import Tag from "@/components/TagElement.vue";
import { escapeHtml } from "@/utils/html";
import Bullhorn from "vue-material-design-icons/Bullhorn.vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";

const props = defineProps<{
  participation: IParticipant;
  options?: IEventCardOptions;
}>();

const emit = defineEmits(["eventDeleted"]);

const { currentActor } = useCurrentActorClient();
const { t } = useI18n({ useScope: "global" });

const dialog = inject<Dialog>("dialog");

const openDeleteEventModal = (
  event: IEvent,
  callback: (anEvent: IEvent) => any
): void => {
  function escapeRegExp(string: string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); // $& means the whole matched string
  }
  const participantsLength = event.participantStats.participant;
  const prefix = participantsLength
    ? t(
        "There are {participants} participants.",
        {
          participants: participantsLength,
        },
        participantsLength
      )
    : "";

  dialog?.prompt({
    variant: "danger",
    title: t("Delete event"),
    message: `${prefix}
      ${t(
        "Are you sure you want to delete this event? This action cannot be reverted."
      )}
      <br><br>
      ${t('To confirm, type your event title "{eventTitle}"', {
        eventTitle: escapeHtml(event.title),
      })}`,
    confirmText: t("Delete {eventTitle}", {
      eventTitle: event.title,
    }),
    inputAttrs: {
      placeholder: event.title,
      pattern: escapeRegExp(event.title),
    },
    hasInput: true,
    onConfirm: () => callback(event),
  });
};

const { notification } = useOruga();
const snackbar = inject<Snackbar>("snackbar");

const {
  mutate: deleteEvent,
  onDone: onDeleteEventDone,
  onError: onDeleteEventError,
} = useDeleteEvent();

onDeleteEventDone(() => {
  /**
   * When the event corresponding has been deleted (by the organizer).
   * A notification is already triggered.
   *
   * @type {string}
   */
  emit("eventDeleted", props.participation.event.id);

  notification.open({
    message: t("Event {eventTitle} deleted", {
      eventTitle: props.participation.event.title,
    }),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
});

onDeleteEventError((error) => {
  snackbar?.open({
    message: error.message,
    variant: "danger",
    position: "bottom",
  });

  console.error(error);
});

/**
 * Delete the event
 */
const openDeleteEventModalWrapper = () => {
  openDeleteEventModal(props.participation.event, (event: IEvent) =>
    deleteEvent({ eventId: event.id ?? "" })
  );
};

const router = useRouter();

const gotToWithCheck = async (
  participation: IParticipant,
  route: RouteLocationRaw
): Promise<any> => {
  if (
    participation.actor.id !== currentActor.value?.id &&
    participation.event.organizerActor
  ) {
    const organizerActor = participation.event.organizerActor as IPerson;
    await changeIdentity(organizerActor);
    notification.open({
      message: t(
        "Current identity has been changed to {identityName} in order to manage this event.",
        {
          identityName: organizerActor.preferredUsername,
        }
      ),
      variant: "info",
      position: "bottom-right",
      duration: 5000,
    });
  }
  return router.push(route);
};

// const organizerActor = computed<IActor | undefined>(() => {
//   if (
//     props.participation.event.attributedTo &&
//     props.participation.event.attributedTo.id
//   ) {
//     return props.participation.event.attributedTo;
//   }
//   return props.participation.event.organizerActor;
// });

const actorAvatarURL = computed<string | null>(() =>
  organizerAvatarUrl(props.participation.event)
);
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

article.box {
  // div.tag-container {
  //   position: absolute;
  //   top: 10px;
  //   right: 0;
  //   @include margin-left(-5px);
  //   z-index: 10;
  //   max-width: 40%;

  //   span.tag {
  //     margin: 5px auto;
  //     box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
  //     /*word-break: break-all;*/
  //     text-overflow: ellipsis;
  //     overflow: hidden;
  //     display: block;
  //     /*text-align: right;*/
  //     font-size: 1em;
  //     /*padding: 0 1px;*/
  //     line-height: 1.75em;
  //   }
  // }

  .list-card {
    // display: flex;
    // padding: 0 6px 0 0;
    // position: relative;
    // flex-direction: column;

    .content-and-actions {
      // display: grid;
      // grid-gap: 5px 10px;
      grid-template-areas: "preview" "body" "actions";

      // @include tablet {
      //   grid-template-columns: 1fr 3fr;
      //   grid-template-areas: "preview body" "actions actions";
      // }

      // @include desktop {
      //   grid-template-columns: 1fr 3fr 1fr;
      //   grid-template-areas: "preview body actions";
      // }

      .event-preview {
        grid-area: preview;

        & > div {
          height: 128px;
          // width: 100%;
          // position: relative;

          // div.date-component {
          //   display: flex;
          //   position: absolute;
          //   bottom: 5px;
          //   left: 5px;
          //   z-index: 1;
          // }

          // img {
          //   width: 100%;
          //   object-position: center;
          //   object-fit: cover;
          //   height: 100%;
          // }
        }
      }

      .actions {
        //   padding: 7px;
        //   cursor: pointer;
        //   align-self: center;
        //   justify-self: center;
        grid-area: actions;
      }

      div.list-card-content {
        // flex: 1;
        // padding: 5px;
        grid-area: body;

        // .participant-stats {
        //   display: flex;
        //   align-items: center;
        //   padding: 0 5px;
        // }

        // div.title-wrapper {
        //   display: flex;
        //   align-items: center;
        //   padding-top: 5px;

        //   a {
        //     text-decoration: none;
        //     padding-bottom: 5px;
        //   }

        //   .title {
        //     display: -webkit-box;
        //     -webkit-line-clamp: 3;
        //     -webkit-box-orient: vertical;
        //     overflow: hidden;
        //     font-size: 18px;
        //     line-height: 24px;
        //     margin: auto 0;
        //     font-weight: bold;
        //   }
        // }
      }
    }
  }

  // .identity-header {
  //   display: flex;
  //   padding: 5px;

  //   figure,
  //   span.icon {
  //     @include padding-right(3px);
  //   }
  // }

  // & > .columns {
  //   padding: 1.25rem;
  // }
  // padding: 0;
}
</style>
