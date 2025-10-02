<template>
  <section class="max-w-screen-xl mx-auto px-3 sm:px-4 md:px-16" v-if="event">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.MY_EVENTS, text: t('My events') },
        {
          name: RouteName.EVENT,
          params: { uuid: event.uuid },
          text: event.title,
        },
        {
          name: RouteName.PARTICIPATIONS,
          params: { uuid: event.uuid },
          text: t('Participants'),
        },
      ]"
    />
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6">
      {{ t("Participants") }}
    </h1>
    <div class="mb-4 sm:mb-6">
      <div
        class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4"
      >
        <div class="flex items-center gap-2">
          <label for="role-select" class="text-sm font-medium whitespace-nowrap"
            >{{ t("Status") }}:</label
          >
          <o-select
            v-model="role"
            id="role-select"
            class="min-w-[150px] flex-1 sm:flex-initial"
          >
            <option value="EVERYTHING">
              {{ t("Everything") }}
            </option>
            <option :value="ParticipantRole.CREATOR">
              {{ t("Organizer") }}
            </option>
            <option :value="ParticipantRole.PARTICIPANT">
              {{ t("Participant") }}
            </option>
            <option :value="ParticipantRole.NOT_APPROVED">
              {{ t("Not approved") }}
            </option>
            <option :value="ParticipantRole.REJECTED">
              {{ t("Rejected") }}
            </option>
            <option :value="ParticipantRole.WAITLIST">
              {{ t("Waitlist") }}
            </option>
          </o-select>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <o-button
            @click="acceptParticipants(checkedRows)"
            variant="primary"
            :disabled="!canAcceptParticipants() || bulkActionLoading"
            :loading="bulkActionLoading"
            icon-left="check"
            size="small"
            class="text-xs sm:text-sm"
          >
            <span class="hidden xs:inline">{{ t("Approve") }}</span>
            <span class="xs:hidden">{{ t("Approve") }}</span>
          </o-button>
          <o-button
            @click="moveToWaitlistParticipants(checkedRows)"
            variant="info"
            :disabled="!canMoveToWaitlist() || bulkActionLoading"
            :loading="bulkActionLoading"
            icon-left="clock"
            size="small"
            class="text-xs sm:text-sm"
          >
            <span class="hidden xs:inline">{{ t("Move to waitlist") }}</span>
            <span class="xs:hidden">{{ t("Waitlist") }}</span>
          </o-button>
          <o-button
            @click="refuseParticipants(checkedRows)"
            variant="danger"
            :disabled="!canRefuseParticipants() || bulkActionLoading"
            :loading="bulkActionLoading"
            icon-left="close"
            size="small"
            class="text-xs sm:text-sm"
          >
            <span class="hidden xs:inline">{{ t("Reject") }}</span>
            <span class="xs:hidden">{{ t("Reject") }}</span>
          </o-button>
          <o-dropdown aria-role="list" v-if="exportFormats.length > 0">
            <template #trigger="{ active }">
              <o-button
                :label="t('Export')"
                variant="primary"
                :icon-right="active ? 'menu-up' : 'menu-down'"
                size="small"
                class="text-xs sm:text-sm"
              />
            </template>

            <o-dropdown-item
              has-link
              v-for="format in exportFormats"
              :key="format"
              aria-role="listitem"
              @click="
                exportParticipants({
                  eventId: event.id ?? '',
                  format,
                })
              "
              @keyup.enter="
                exportParticipants({
                  eventId: event.id ?? '',
                  format,
                })
              "
            >
              <button class="dropdown-button">
                <o-icon :icon="formatToIcon(format)"></o-icon>
                {{ format }}
              </button>
            </o-dropdown-item>
          </o-dropdown>
        </div>
      </div>
    </div>
    <!-- Mobile Card Layout -->
    <div class="block md:hidden">
      <div v-if="participantsLoading" class="text-center py-8">
        <div
          class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"
        ></div>
      </div>
      <div
        v-else-if="event.participants.elements.length === 0"
        class="text-center py-8"
      >
        <EmptyContent icon="account-circle" :inline="true">
          {{ t("No participant matches the filters") }}
        </EmptyContent>
      </div>
      <div v-else class="space-y-3">
        <div
          v-for="participant in event.participants.elements"
          :key="participant.id"
          class="bg-white border border-gray-200 rounded-lg p-4 shadow-sm"
        >
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center gap-3 flex-1 min-w-0">
              <input
                v-if="participant.role !== ParticipantRole.CREATOR"
                type="checkbox"
                :value="participant"
                v-model="checkedRows"
                class="mt-1 rounded border-gray-300"
              />
              <figure v-if="participant.actor.avatar" class="flex-shrink-0">
                <img
                  class="rounded-full w-10 h-10 object-cover"
                  :src="participant.actor.avatar.url"
                  alt=""
                />
              </figure>
              <Incognito
                v-else-if="participant.actor.preferredUsername === 'anonymous'"
                :size="40"
                class="flex-shrink-0"
              />
              <AccountCircle v-else :size="40" class="flex-shrink-0" />
              <div class="min-w-0 flex-1">
                <div v-if="participant.actor.preferredUsername !== 'anonymous'">
                  <div class="font-medium text-sm truncate">
                    {{
                      participant.actor.name ||
                      usernameWithDomain(participant.actor)
                    }}
                  </div>
                  <div
                    class="text-xs text-gray-500 truncate"
                    v-if="participant.actor.name"
                  >
                    @{{ usernameWithDomain(participant.actor) }}
                  </div>
                </div>
                <span v-else class="text-sm text-gray-500">
                  {{ t("Anonymous participant") }}
                </span>
              </div>
            </div>
            <span
              class="inline-block px-2 py-1 text-xs font-medium rounded-sm flex-shrink-0"
              :class="{
                'bg-blue-500 text-white':
                  participant.role === ParticipantRole.CREATOR,
                'bg-green-100 text-green-800':
                  participant.role === ParticipantRole.PARTICIPANT,
                'bg-gray-100 text-gray-800':
                  participant.role === ParticipantRole.NOT_CONFIRMED ||
                  participant.role === ParticipantRole.NOT_APPROVED,
                'bg-red-100 text-red-800':
                  participant.role === ParticipantRole.REJECTED,
                'bg-blue-100 text-blue-800':
                  participant.role === ParticipantRole.WAITLIST,
              }"
            >
              <template v-if="participant.role === ParticipantRole.CREATOR">
                {{ t("Organizer") }}
              </template>
              <template
                v-else-if="participant.role === ParticipantRole.PARTICIPANT"
              >
                {{ t("Participant") }}
              </template>
              <template
                v-else-if="participant.role === ParticipantRole.NOT_CONFIRMED"
              >
                {{ t("Not confirmed") }}
              </template>
              <template
                v-else-if="participant.role === ParticipantRole.NOT_APPROVED"
              >
                {{ t("Not approved") }}
              </template>
              <template
                v-else-if="participant.role === ParticipantRole.REJECTED"
              >
                {{ t("Rejected") }}
              </template>
              <template
                v-else-if="participant.role === ParticipantRole.WAITLIST"
              >
                {{ t("Waitlist") }}
              </template>
            </span>
          </div>

          <div class="space-y-2 text-sm">
            <div v-if="participant.metadata && participant.metadata.message">
              <div class="font-medium text-gray-700">{{ t("Message") }}:</div>
              <div class="text-gray-600 bg-gray-50 p-2 rounded text-xs">
                {{ participant.metadata.message }}
              </div>
            </div>

            <div
              class="flex justify-between items-center text-xs text-gray-500"
            >
              <div>
                <div>
                  {{
                    participant.insertedAt
                      ? formatDateString(participant.insertedAt.toString())
                      : ""
                  }}
                </div>
                <div>
                  {{
                    participant.insertedAt
                      ? formatTimeString(participant.insertedAt.toString())
                      : ""
                  }}
                </div>
              </div>

              <div
                class="flex gap-1"
                v-if="participant.role !== ParticipantRole.CREATOR"
              >
                <o-button
                  v-if="
                    participant.role === ParticipantRole.NOT_APPROVED ||
                    participant.role === ParticipantRole.REJECTED ||
                    participant.role === ParticipantRole.WAITLIST
                  "
                  @click="
                    participant.id &&
                      updateSingleParticipant(
                        participant.id,
                        ParticipantRole.PARTICIPANT
                      )
                  "
                  size="small"
                  variant="success"
                  icon-left="check"
                  :title="t('Approve')"
                />
                <o-button
                  v-if="participant.role !== ParticipantRole.WAITLIST"
                  @click="
                    participant.id &&
                      updateSingleParticipant(
                        participant.id,
                        ParticipantRole.WAITLIST
                      )
                  "
                  size="small"
                  variant="info"
                  icon-left="clock"
                  :title="t('Move to waitlist')"
                />
                <o-button
                  v-if="participant.role !== ParticipantRole.REJECTED"
                  @click="
                    participant.id &&
                      updateSingleParticipant(
                        participant.id,
                        ParticipantRole.REJECTED
                      )
                  "
                  size="small"
                  variant="danger"
                  icon-left="close"
                  :title="t('Reject')"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Mobile Pagination -->
      <div v-if="event.participants.total > PARTICIPANTS_PER_PAGE" class="mt-6">
        <div class="flex justify-between items-center">
          <o-button
            @click="page = page - 1"
            :disabled="page <= 1"
            variant="primary"
            outlined
            size="small"
          >
            {{ t("Previous page") }}
          </o-button>
          <span class="text-sm text-gray-600">
            {{ t("Page") }} {{ page }} {{ t("of") }}
            {{ Math.ceil(event.participants.total / PARTICIPANTS_PER_PAGE) }}
          </span>
          <o-button
            @click="page = page + 1"
            :disabled="
              page >=
              Math.ceil(event.participants.total / PARTICIPANTS_PER_PAGE)
            "
            variant="primary"
            outlined
            size="small"
          >
            {{ t("Next page") }}
          </o-button>
        </div>
      </div>
    </div>

    <!-- Desktop Table Layout -->
    <div class="hidden md:block">
      <o-table
        :data="event.participants.elements"
        ref="queueTable"
        detailed
        detail-key="id"
        v-model:checked-rows="checkedRows"
        checkable
        :is-row-checkable="
          (row: IParticipant) => row.role !== ParticipantRole.CREATOR
        "
        checkbox-position="left"
        :show-detail-icon="false"
        :loading="participantsLoading"
        paginated
        :current-page="page"
        backend-pagination
        :pagination-simple="true"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="event.participants.total"
        :per-page="PARTICIPANTS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="(newPage: number) => (page = newPage)"
        @sort="(field: string, order: string) => emit('sort', field, order)"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Participant')"
          v-slot="props"
        >
          <div class="flex items-center gap-2 sm:gap-3">
            <figure v-if="props.row.actor.avatar" class="flex-shrink-0">
              <img
                class="rounded-full w-8 h-8 sm:w-10 sm:h-10 object-cover"
                :src="props.row.actor.avatar.url"
                alt=""
                :height="32"
                :width="32"
              />
            </figure>
            <Incognito
              v-else-if="props.row.actor.preferredUsername === 'anonymous'"
              :size="32"
              class="flex-shrink-0"
            />
            <AccountCircle v-else :size="32" class="flex-shrink-0" />
            <div class="min-w-0 flex-1">
              <div v-if="props.row.actor.preferredUsername !== 'anonymous'">
                <div class="font-medium text-xs sm:text-sm truncate">
                  {{
                    props.row.actor.name || usernameWithDomain(props.row.actor)
                  }}
                </div>
                <div
                  class="text-xs text-gray-500 truncate"
                  v-if="props.row.actor.name"
                >
                  @{{ usernameWithDomain(props.row.actor) }}
                </div>
              </div>
              <span v-else class="text-xs sm:text-sm text-gray-500">
                {{ t("Anonymous participant") }}
              </span>
            </div>
          </div>
        </o-table-column>
        <o-table-column field="role" :label="t('Role')" v-slot="props">
          <span
            class="inline-block px-2 sm:px-3 py-1 text-xs font-medium rounded-sm"
            :class="{
              'bg-blue-500 text-white':
                props.row.role === ParticipantRole.CREATOR,
              'bg-green-100 text-green-800':
                props.row.role === ParticipantRole.PARTICIPANT,
              'bg-gray-100 text-gray-800':
                props.row.role === ParticipantRole.NOT_CONFIRMED ||
                props.row.role === ParticipantRole.NOT_APPROVED,
              'bg-red-100 text-red-800':
                props.row.role === ParticipantRole.REJECTED,
              'bg-blue-100 text-blue-800':
                props.row.role === ParticipantRole.WAITLIST,
            }"
          >
            <template v-if="props.row.role === ParticipantRole.CREATOR">
              {{ t("Organizer") }}
            </template>
            <template
              v-else-if="props.row.role === ParticipantRole.PARTICIPANT"
            >
              {{ t("Participant") }}
            </template>
            <template
              v-else-if="props.row.role === ParticipantRole.NOT_CONFIRMED"
            >
              {{ t("Not confirmed") }}
            </template>
            <template
              v-else-if="props.row.role === ParticipantRole.NOT_APPROVED"
            >
              {{ t("Not approved") }}
            </template>
            <template v-else-if="props.row.role === ParticipantRole.REJECTED">
              {{ t("Rejected") }}
            </template>
            <template v-else-if="props.row.role === ParticipantRole.WAITLIST">
              {{ t("Waitlist") }}
            </template>
          </span>
        </o-table-column>
        <o-table-column
          field="metadata.message"
          class="column-message"
          :label="t('Message')"
          v-slot="props"
        >
          <div
            @click="toggleQueueDetails(props.row)"
            :class="{
              'ellipsed-message':
                props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH,
            }"
            v-if="props.row.metadata && props.row.metadata.message"
          >
            <p
              v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH"
            >
              {{ ellipsize(props.row.metadata.message) }}
            </p>
            <p v-else>
              {{ props.row.metadata.message }}
            </p>
            <o-button
              variant="primary"
              v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH"
              @click.stop="toggleQueueDetails(props.row)"
            >
              {{
                openDetailedRows[props.row.id] ? t("View less") : t("View more")
              }}
            </o-button>
          </div>
          <p v-else class="text-sm text-gray-500">
            {{ t("No message") }}
          </p>
        </o-table-column>
        <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
          <div class="text-xs sm:text-sm">
            <div class="truncate">
              {{ formatDateString(props.row.insertedAt) }}
            </div>
            <div class="text-gray-500 truncate">
              {{ formatTimeString(props.row.insertedAt) }}
            </div>
          </div>
        </o-table-column>
        <o-table-column :label="t('Actions')" v-slot="props">
          <div
            class="flex gap-1 justify-center sm:justify-start"
            v-if="props.row.role !== ParticipantRole.CREATOR"
          >
            <o-button
              v-if="
                props.row.role === ParticipantRole.NOT_APPROVED ||
                props.row.role === ParticipantRole.REJECTED ||
                props.row.role === ParticipantRole.WAITLIST
              "
              @click="
                updateSingleParticipant(
                  props.row.id,
                  ParticipantRole.PARTICIPANT
                )
              "
              size="small"
              variant="success"
              icon-left="check"
              :title="t('Approve')"
            />
            <o-button
              v-if="props.row.role !== ParticipantRole.WAITLIST"
              @click="
                updateSingleParticipant(props.row.id, ParticipantRole.WAITLIST)
              "
              size="small"
              variant="info"
              icon-left="clock"
              :title="t('Move to waitlist')"
            />
            <o-button
              v-if="props.row.role !== ParticipantRole.REJECTED"
              @click="
                updateSingleParticipant(props.row.id, ParticipantRole.REJECTED)
              "
              size="small"
              variant="danger"
              icon-left="close"
              :title="t('Reject')"
            />
          </div>
        </o-table-column>
        <template #detail="props">
          <p>
            {{ props.row.metadata.message }}
          </p>
        </template>
        <template #empty>
          <EmptyContent icon="account-circle" :inline="true">
            {{ t("No participant matches the filters") }}
          </EmptyContent>
        </template>
      </o-table>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "@/types/participant.model";
import { IEvent } from "@/types/event.model";
import {
  EXPORT_EVENT_PARTICIPATIONS,
  PARTICIPANTS,
  UPDATE_PARTICIPANT,
} from "@/graphql/event";
import { usernameWithDomain } from "@/types/actor";
import { asyncForEach } from "@/utils/asyncForEach";
import RouteName from "@/router/name";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useParticipantsExportFormats } from "@/composition/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  integerTransformer,
  enumTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { computed, inject, ref } from "vue";
import { formatDateString, formatTimeString } from "@/filters/datetime";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Incognito from "vue-material-design-icons/Incognito.vue";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";

const PARTICIPANTS_PER_PAGE = 10;
const MESSAGE_ELLIPSIS_LENGTH = 130;

type exportFormat = "CSV" | "PDF" | "ODS";

const props = defineProps<{
  eventId: string;
}>();

const emit = defineEmits(["sort"]);

const { t } = useI18n({ useScope: "global" });

const { currentActor } = useCurrentActorClient();
const participantsExportFormats = useParticipantsExportFormats();

const ellipsize = (text?: string) =>
  text && text.substring(0, MESSAGE_ELLIPSIS_LENGTH).concat("…");

const eventId = computed(() => props.eventId);

const ParticipantAllRoles = { ...ParticipantRole, EVERYTHING: "EVERYTHING" };

const page = useRouteQuery("page", 1, integerTransformer);
const role = useRouteQuery(
  "role",
  "EVERYTHING",
  enumTransformer(ParticipantAllRoles)
);

const checkedRows = ref<IParticipant[]>([]);
const bulkActionLoading = ref(false);

const queueTable = ref();

const {
  result: participantsResult,
  loading: participantsLoading,
  refetch: refetchParticipants,
} = useQuery<{
  event: IEvent;
}>(
  PARTICIPANTS,
  () => ({
    uuid: eventId.value,
    page: page.value,
    limit: PARTICIPANTS_PER_PAGE,
    roles: role.value === "EVERYTHING" ? undefined : role.value,
  }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined &&
      page.value !== undefined &&
      role.value !== undefined,
  })
);

const event = computed(() => participantsResult.value?.event);

// const participantStats = computed((): IEventParticipantStats | null => {
//   if (!event.value) return null;
//   return event.value.participantStats;
// });

const { mutate: updateParticipant, onError: onUpdateParticipantError } =
  useMutation(UPDATE_PARTICIPANT);

onUpdateParticipantError((e) => console.error(e));

const acceptParticipants = async (
  participants: IParticipant[]
): Promise<void> => {
  if (bulkActionLoading.value) return;

  bulkActionLoading.value = true;
  let successCount = 0;
  let errorCount = 0;

  try {
    await asyncForEach(participants, async (participant: IParticipant) => {
      try {
        await updateParticipant({
          id: participant.id,
          role: ParticipantRole.PARTICIPANT,
        });
        successCount++;
      } catch (error) {
        console.error(
          `Failed to approve participant ${participant.id}:`,
          error
        );
        errorCount++;
      }
    });

    // Refetch data to ensure UI is up to date
    await refetchParticipants();
    checkedRows.value = [];

    // Show success/error notifications
    if (successCount > 0) {
      notifier?.success(
        t("Successfully approved {count} participant(s)", {
          count: successCount,
        })
      );
    }
    if (errorCount > 0) {
      notifier?.error(
        t("Failed to approve {count} participant(s)", { count: errorCount })
      );
    }
  } catch (error) {
    console.error("Bulk approve operation failed:", error);
    notifier?.error(t("An error occurred while approving participants"));
  } finally {
    bulkActionLoading.value = false;
  }
};

const refuseParticipants = async (
  participants: IParticipant[]
): Promise<void> => {
  if (bulkActionLoading.value) return;

  bulkActionLoading.value = true;
  let successCount = 0;
  let errorCount = 0;

  try {
    await asyncForEach(participants, async (participant: IParticipant) => {
      try {
        await updateParticipant({
          id: participant.id,
          role: ParticipantRole.REJECTED,
        });
        successCount++;
      } catch (error) {
        console.error(`Failed to reject participant ${participant.id}:`, error);
        errorCount++;
      }
    });

    // Refetch data to ensure UI is up to date
    await refetchParticipants();
    checkedRows.value = [];

    // Show success/error notifications
    if (successCount > 0) {
      notifier?.success(
        t("Successfully rejected {count} participant(s)", {
          count: successCount,
        })
      );
    }
    if (errorCount > 0) {
      notifier?.error(
        t("Failed to reject {count} participant(s)", { count: errorCount })
      );
    }
  } catch (error) {
    console.error("Bulk reject operation failed:", error);
    notifier?.error(t("An error occurred while rejecting participants"));
  } finally {
    bulkActionLoading.value = false;
  }
};

const moveToWaitlistParticipants = async (
  participants: IParticipant[]
): Promise<void> => {
  if (bulkActionLoading.value) return;

  bulkActionLoading.value = true;
  let successCount = 0;
  let errorCount = 0;

  try {
    await asyncForEach(participants, async (participant: IParticipant) => {
      try {
        await updateParticipant({
          id: participant.id,
          role: ParticipantRole.WAITLIST,
        });
        successCount++;
      } catch (error) {
        console.error(
          `Failed to move participant ${participant.id} to waitlist:`,
          error
        );
        errorCount++;
      }
    });

    // Refetch data to ensure UI is up to date
    await refetchParticipants();
    checkedRows.value = [];

    // Show success/error notifications
    if (successCount > 0) {
      notifier?.success(
        t("Successfully moved {count} participant(s) to waitlist", {
          count: successCount,
        })
      );
    }
    if (errorCount > 0) {
      notifier?.error(
        t("Failed to move {count} participant(s) to waitlist", {
          count: errorCount,
        })
      );
    }
  } catch (error) {
    console.error("Bulk move to waitlist operation failed:", error);
    notifier?.error(t("An error occurred while moving participants to waitlist"));
  } finally {
    bulkActionLoading.value = false;
  }
};

const updateSingleParticipant = async (
  participantId: string,
  newRole: ParticipantRole
): Promise<void> => {
  try {
    await updateParticipant({
      id: participantId,
      role: newRole,
    });

    // Refetch data to ensure UI is up to date
    await refetchParticipants();

    const actionName =
      newRole === ParticipantRole.PARTICIPANT
        ? t("approved")
        : newRole === ParticipantRole.WAITLIST
        ? t("moved to waitlist")
        : t("rejected");
    notifier?.success(
      t("Participant {action} successfully", { action: actionName })
    );
  } catch (error) {
    console.error(`Failed to update participant ${participantId}:`, error);
    const actionName =
      newRole === ParticipantRole.PARTICIPANT
        ? t("approve")
        : newRole === ParticipantRole.WAITLIST
        ? t("move to waitlist")
        : t("reject");
    notifier?.error(
      t("Failed to {action} participant", { action: actionName })
    );
  }
};

const {
  mutate: exportParticipants,
  onDone: onExportParticipantsMutationDone,
  onError: onExportParticipantsMutationError,
} = useMutation<
  { exportEventParticipants: { path: string; format: string } },
  { eventId: string; format?: exportFormat; roles?: string[] }
>(EXPORT_EVENT_PARTICIPATIONS);

onExportParticipantsMutationDone(({ data }) => {
  const path = data?.exportEventParticipants?.path;
  const format = data?.exportEventParticipants?.format;
  const link = window.origin + "/exports/" + format?.toLowerCase() + "/" + path;
  console.debug(link);
  const a = document.createElement("a");
  a.style.display = "none";
  document.body.appendChild(a);
  a.href = link;
  a.setAttribute("download", "true");
  a.click();
  window.URL.revokeObjectURL(a.href);
  document.body.removeChild(a);
});

const notifier = inject<Notifier>("notifier");

onExportParticipantsMutationError((e) => {
  console.error(e);
  if (e.graphQLErrors && e.graphQLErrors.length > 0) {
    notifier?.error(e.graphQLErrors[0].message);
  }
});

const exportFormats = computed((): exportFormat[] => {
  return (participantsExportFormats ?? []).map(
    (key) => key.toUpperCase() as exportFormat
  );
});

const formatToIcon = (format: exportFormat): string => {
  switch (format) {
    case "CSV":
      return "file-delimited";
    case "PDF":
      return "file-pdf-box";
    case "ODS":
      return "google-spreadsheet";
  }
};

/**
 * We can accept participants if at least one of them is not approved
 */
const canAcceptParticipants = (): boolean => {
  return checkedRows.value.some((participant: IParticipant) =>
    [
      ParticipantRole.NOT_APPROVED,
      ParticipantRole.REJECTED,
      ParticipantRole.WAITLIST,
    ].includes(participant.role)
  );
};

/**
 * We can refuse participants if at least one of them is something different than rejected
 */
const canRefuseParticipants = (): boolean => {
  return checkedRows.value.some(
    (participant: IParticipant) => participant.role !== ParticipantRole.REJECTED
  );
};

/**
 * We can move participants to waitlist if at least one of them is not already on the waitlist
 */
const canMoveToWaitlist = (): boolean => {
  return checkedRows.value.some(
    (participant: IParticipant) => participant.role !== ParticipantRole.WAITLIST
  );
};

const toggleQueueDetails = (row: IParticipant): void => {
  if (
    row.metadata.message &&
    row.metadata.message.length < MESSAGE_ELLIPSIS_LENGTH
  )
    return;
  queueTable.value.toggleDetails(row);
  if (row.id) {
    openDetailedRows.value[row.id] = !openDetailedRows.value[row.id];
  }
};

const openDetailedRows = ref<Record<string, boolean>>({});

useHead({
  title: computed(() =>
    t("Participants to {eventTitle}", { eventTitle: event.value?.title })
  ),
});
</script>

<style lang="scss" scoped>
.ellipsed-message {
  cursor: pointer;

  p {
    margin-bottom: 0.5rem;
  }
}

:deep(.o-table) {
  th {
    @apply font-medium text-sm text-gray-700 dark:text-gray-300;
  }

  td {
    @apply py-3;
  }
}
</style>
