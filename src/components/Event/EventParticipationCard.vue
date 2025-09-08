<template>
  <article
    class="bg-white border border-[#cac9cb] overflow-hidden flex flex-col w-full"
  >
    <router-link
      :to="{
        name: RouteName.EVENT,
        params: { uuid: participation.event.uuid },
      }"
      class="block"
    >
      <div class="relative h-[200px] overflow-hidden">
        <div v-if="participation.event.picture" class="w-full h-full">
          <lazy-image-wrapper
            :picture="participation.event.picture"
            class="w-full h-full"
          />
        </div>
        <div v-else class="w-full h-full flex items-center justify-center">
          <svg
            width="64"
            height="64"
            viewBox="0 0 48 48"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            class="text-gray-300 empty-state-icon"
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
    <div class="p-5 pb-2 flex flex-col gap-2 flex-1">
      <div class="flex flex-col h-24">
        <div class="text-[#37363a] text-xs font-medium leading-[18px] mb-1">
          {{
            participation.event.options?.showStartTime
              ? new Date(participation.event.beginsOn).toLocaleDateString(
                  undefined,
                  {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                  }
                )
              : new Date(participation.event.beginsOn).toLocaleDateString(
                  undefined,
                  {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  }
                )
          }}
        </div>
        <router-link
          :to="{
            name: RouteName.EVENT,
            params: { uuid: participation.event.uuid },
          }"
          class="h-[52px] overflow-hidden"
        >
          <h3
            class="text-[17px] font-bold text-[#1c1b1f] leading-[26px] line-clamp-2"
          >
            {{ participation.event.title }}
          </h3>
        </router-link>
      </div>
      <div class="flex flex-col gap-1">
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <figure
              v-if="actorAvatarURL"
              class="w-6 h-6 rounded-full overflow-hidden"
            >
              <img
                class="w-full h-full object-cover rounded-full"
                :src="actorAvatarURL"
                alt=""
              />
            </figure>
            <figure
              v-else
              class="w-6 h-6 bg-gray-200 flex items-center justify-center overflow-hidden shrink-0"
              style="border-radius: 50% !important"
            >
              <svg
                class="w-5 h-5 text-gray-500"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <circle cx="12" cy="8" r="3" />
                <path d="M12 14c-4 0-8 2-8 6v2h16v-2c0-4-4-6-8-6z" />
              </svg>
            </figure>
            <span
              class="text-[15px] font-bold text-[#1c1b1f] leading-[23px] flex-1"
              >{{ organizerDisplayName(participation.event) }}</span
            >
          </div>
          <div class="flex items-center gap-2">
            <div class="w-6 h-6 flex items-center justify-center">
              <MapMarker class="w-6 h-6 text-gray-500" />
            </div>
            <div
              class="text-[15px] font-medium text-[#37363a] leading-[23px] flex-1 flex items-center gap-1"
            >
              <template v-if="participation.event.physicalAddress">
                <span>{{
                  participation.event.physicalAddress?.locality ||
                  participation.event.physicalAddress?.region ||
                  participation.event.physicalAddress?.description ||
                  participation.event.physicalAddress?.street
                }}</span>
              </template>
              <template
                v-else-if="
                  participation.event.options &&
                  participation.event.options.isOnline
                "
              >
                <Video class="w-6 h-6" />
                <span>{{ t("Online") }}</span>
              </template>
            </div>
          </div>
        </div>
      </div>
      <div class="gap-2">
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
      </div>
    </div>
  </article>
</template>

<script lang="ts" setup>
import { EventStatus } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import {
  IEventCardOptions,
  organizerAvatarUrl,
  organizerDisplayName,
} from "@/types/event.model";
import RouteName from "@/router/name";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";

import MapMarker from "vue-material-design-icons/MapMarker.vue";
import Video from "vue-material-design-icons/Video.vue";
import { useOruga } from "@oruga-ui/oruga-next";
import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import { Snackbar } from "@/plugins/snackbar";
import { useDeleteEvent } from "@/composition/apollo/event";
import Tag from "@/components/TagElement.vue";

const props = defineProps<{
  participation: IParticipant;
  options?: IEventCardOptions;
}>();

const emit = defineEmits(["eventDeleted"]);

const { t } = useI18n({ useScope: "global" });

const { notification } = useOruga();
const snackbar = inject<Snackbar>("snackbar");

const { onDone: onDeleteEventDone, onError: onDeleteEventError } =
  useDeleteEvent();

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

const actorAvatarURL = computed<string | null>(() =>
  organizerAvatarUrl(props.participation.event)
);
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

article.box {
  .list-card {
    .content-and-actions {
      grid-template-areas: "preview" "body" "actions";

      .event-preview {
        grid-area: preview;

        & > div {
          height: 128px;
        }
      }

      .actions {
        grid-area: actions;
      }

      div.list-card-content {
        grid-area: body;
      }
    }
  }
}
</style>
