<template>
  <section
    class="bg-white rounded-lg shadow-sm border border-gray-200"
    style="padding: 20px; margin-bottom: 16px"
  >
    <!-- Section heading -->
    <div class="flex items-center justify-between mb-4">
      <h2
        class="text-gray-700"
        style="font-size: 20px; line-height: 1.5; font-weight: 700; font-family: var(--font-family-primary)"
      >
        {{ t("Surveys") }}
      </h2>
      <o-button
        v-if="isAdmin"
        variant="primary"
        size="small"
        icon-left="plus"
        @click="openBuilderModal(null)"
      >
        {{ t("Add") }}
      </o-button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-6">
      <div class="inline-block animate-spin rounded-full h-7 w-7 border-b-2 border-primary-500" />
    </div>

    <!-- Empty state -->
    <p
      v-else-if="visibleSurveys.length === 0"
      class="text-gray-500 italic text-center py-8"
      style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary)"
    >
      {{ isAdmin ? t("No surveys yet.") : t("No published surveys.") }}
    </p>

    <!-- Survey list -->
    <ul v-else class="space-y-3">
      <li
        v-for="survey in visibleSurveys"
        :key="survey.id"
        class="border border-gray-200 px-4 py-3 flex items-center justify-between gap-3"
      >
        <div class="flex items-center gap-3 min-w-0">
          <!-- Status badge: shown to admins only -->
          <span
            v-if="isAdmin"
            class="text-xs font-semibold px-2 py-0.5 shrink-0"
            :class="statusBadgeClass(survey.status)"
          >
            {{ statusLabel(survey.status) }}
          </span>
          <!-- Larger title for participants -->
          <span
            class="font-medium text-gray-900 truncate"
            :class="isAdmin ? 'text-sm' : 'text-base'"
          >
            {{ survey.title || t("(no title)") }}
          </span>
        </div>

        <!-- Admin actions -->
        <div v-if="isAdmin" class="flex items-center gap-2 shrink-0">
          <o-button
            v-if="survey.status === 'draft'"
            size="small"
            @click="openBuilderModal(survey)"
          >
            {{ t("Edit survey") }}
          </o-button>
          <o-button
            v-if="survey.status === 'draft'"
            size="small"
            variant="primary"
            @click="publishSurvey(survey)"
          >
            {{ t("Publish") }}
          </o-button>
          <router-link
            v-if="survey.status === 'published' || survey.status === 'closed'"
            :to="{ name: EventRouteName.EVENT_POST_SURVEY_RESPONSES, params: { eventId: event.id, surveyId: survey.id } }"
          >
            <o-button size="small" variant="info" icon-left="eye">
              {{ t("Details") }}
            </o-button>
          </router-link>
          <o-button
            v-if="survey.status === 'published'"
            size="small"
            variant="danger"
            @click="closeSurvey(survey)"
          >
            {{ t("End") }}
          </o-button>
        </div>

        <!-- Participant action -->
        <o-button
          v-else-if="isParticipant && survey.status === 'published'"
          size="small"
          variant="primary"
          @click="openFillModal(survey)"
        >
          {{ t("Fill") }}
        </o-button>
      </li>
    </ul>

    <!-- ── Builder modal (admin) ── -->
    <o-modal
      v-model:active="builderModalOpen"
      :width="960"
      has-modal-card
      :trap-focus="false"
      :close-button-aria-label="t('Close')"
    >
      <div
        class="modal-card"
        style="width: min(960px, 95vw); height: 85vh; display: flex; flex-direction: column"
      >
        <header class="modal-card-head flex items-center bg-primary-700 px-6 py-4">
          <p class="modal-card-title text-lg font-semibold text-white">
            {{ editingSurvey ? t("Edit survey") : t("Add survey") }}
          </p>
        </header>

        <!-- Title + description inputs -->
        <div class="px-6 pt-5 pb-4 border-b border-gray-100 space-y-3">
          <o-field :label="t('Survey title')" class="w-full">
            <o-input
              v-model="editingTitle"
              :placeholder="t('Survey title')"
              expanded
              class="w-full"
            />
          </o-field>
          <o-field :label="t('Survey description')" class="w-full">
            <o-input
              v-model="editingDescription"
              :placeholder="t('Survey description placeholder')"
              type="textarea"
              :rows="2"
              expanded
              class="w-full"
            />
          </o-field>
        </div>

        <section class="modal-card-body" style="flex: 1; padding: 0; overflow: hidden">
          <SurveyBuilderWrapper
            v-if="builderModalOpen && event"
            :context-id="builderContextId"
            :initial-schema="editingSchema ?? undefined"
            @schema-change="(s: object) => (editingSchema = s)"
            @error="(e: Error) => console.error('SurveyBuilder error:', e)"
          />
        </section>

        <footer class="modal-card-foot flex justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-white">
          <o-button variant="danger" @click="cancelBuilderModal">
            {{ t("Cancel") }}
          </o-button>
          <o-button variant="primary" :disabled="builderSaving" @click="saveBuilderModal">
            {{ t("Save") }}
          </o-button>
        </footer>
      </div>
    </o-modal>

    <!-- ── Fill modal (participant) ── -->
    <o-modal
      v-model:active="fillModalOpen"
      has-modal-card
      :close-button-aria-label="t('Close')"
    >
      <div class="modal-card">
        <header class="modal-card-head flex items-center bg-primary-700 px-6 py-4">
          <p class="modal-card-title text-lg font-semibold text-white">
            {{ fillingSurvey?.title || t("Survey") }}
          </p>
        </header>
        <section class="modal-card-body py-8 px-6">
          <p
            v-if="fillingSurvey?.description"
            class="text-gray-600 text-sm leading-relaxed mb-6"
          >
            {{ fillingSurvey.description }}
          </p>
          <div style="max-width: 560px; margin: 0 auto">
            <SurveyFormWrapper
              v-if="fillModalOpen && fillingSurvey"
              :context-id="fillingSurvey.contextId"
              :survey-schema="fillingSurvey.schema"
              @completed="onFillCompleted"
              @error="(e: Error) => console.error('Survey fill error:', e)"
            />
          </div>
        </section>
      </div>
    </o-modal>
  </section>
</template>

<script lang="ts" setup>
import { ref, computed } from "vue";
import { useI18n } from "vue-i18n";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { ParticipantRole } from "@/types/enums";
import type { IEvent } from "@/types/event.model";
import type { IParticipant } from "@/types/participant.model";
import type { IPerson } from "@/types/actor";
import type { IEventPostSurvey } from "@/types/event-post-survey";
import { EventRouteName } from "@/router/event";
import SurveyBuilderWrapper from "@/components/Survey/SurveyBuilderWrapper.vue";
import SurveyFormWrapper from "@/components/Survey/SurveyFormWrapper.vue";
import {
  EVENT_POST_SURVEYS,
  CREATE_EVENT_POST_SURVEY,
  UPDATE_EVENT_POST_SURVEY,
  PUBLISH_EVENT_POST_SURVEY,
  CLOSE_EVENT_POST_SURVEY,
} from "@/graphql/eventPostSurveys";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  event: IEvent;
  currentActor: IPerson | undefined;
  participations: IParticipant[];
}>();

// ── Data fetching ────────────────────────────────────────────────────────────

const { result, loading, refetch } = useQuery(
  EVENT_POST_SURVEYS,
  () => ({ eventId: props.event.id }),
  { enabled: !!props.event?.id }
);

const surveys = computed<IEventPostSurvey[]>(
  () => result.value?.eventPostSurveys ?? []
);

// ── Authorization ────────────────────────────────────────────────────────────

const currentRole = computed(
  () => props.participations[0]?.role ?? null
);

const isAdmin = computed(() => {
  if (!props.currentActor) return false;
  const role = currentRole.value;
  return (
    role === ParticipantRole.CREATOR ||
    role === ParticipantRole.ADMINISTRATOR ||
    String(props.event.organizerActor?.id) === String(props.currentActor.id)
  );
});

const isParticipant = computed(() => {
  const role = currentRole.value;
  return (
    role === ParticipantRole.PARTICIPANT ||
    role === ParticipantRole.CREATOR ||
    role === ParticipantRole.ADMINISTRATOR
  );
});

// Admins see all; participants see published + closed
const visibleSurveys = computed<IEventPostSurvey[]>(() => {
  if (isAdmin.value) return surveys.value;
  return surveys.value.filter((s) => s.status === "published" || s.status === "closed");
});

// ── Status display ───────────────────────────────────────────────────────────

function statusLabel(status: string): string {
  switch (status) {
    case "draft":
      return t("Draft");
    case "published":
      return t("Published");
    case "closed":
      return t("Closed");
    default:
      return status;
  }
}

function statusBadgeClass(status: string): string {
  switch (status) {
    case "draft":
      return "bg-gray-100 text-gray-600";
    case "published":
      return "bg-primary-50 text-primary-700";
    case "closed":
      return "bg-gray-200 text-gray-500";
    default:
      return "bg-gray-100 text-gray-600";
  }
}

// ── Builder modal (admin: create / edit) ─────────────────────────────────────

const builderModalOpen = ref(false);
const builderSaving = ref(false);
const editingSurvey = ref<IEventPostSurvey | null>(null);
const editingTitle = ref("");
const editingDescription = ref("");
const editingSchema = ref<object | null>(null);

// A stable but unique context_id for the builder iframe session.
// For new surveys we use a temporary id; the real one is set on save.
const builderContextId = computed(() =>
  editingSurvey.value
    ? editingSurvey.value.contextId
    : `mobilizon_event_survey_new:${props.event.id}`
);

function openBuilderModal(survey: IEventPostSurvey | null) {
  editingSurvey.value = survey;
  editingTitle.value = survey?.title ?? "";
  editingDescription.value = survey?.description ?? "";
  editingSchema.value = survey?.schema ?? null;
  builderModalOpen.value = true;
}

function cancelBuilderModal() {
  builderModalOpen.value = false;
  editingSurvey.value = null;
  editingTitle.value = "";
  editingDescription.value = "";
  editingSchema.value = null;
}

const { mutate: createSurvey } = useMutation(CREATE_EVENT_POST_SURVEY);
const { mutate: updateSurvey } = useMutation(UPDATE_EVENT_POST_SURVEY);

async function saveBuilderModal() {
  builderSaving.value = true;
  try {
    const schema = JSON.stringify(editingSchema.value ?? { display: "form", components: [] });
    const description = editingDescription.value.trim() || null;
    if (editingSurvey.value) {
      await updateSurvey({
        surveyId: editingSurvey.value.id,
        title: editingTitle.value,
        description,
        schema,
      });
    } else {
      await createSurvey({
        eventId: props.event.id,
        title: editingTitle.value,
        description,
        schema,
      });
    }
    await refetch();
    builderModalOpen.value = false;
    editingSurvey.value = null;
  } finally {
    builderSaving.value = false;
  }
}

// ── Publish / Close ──────────────────────────────────────────────────────────

const { mutate: doPublish } = useMutation(PUBLISH_EVENT_POST_SURVEY);
const { mutate: doClose } = useMutation(CLOSE_EVENT_POST_SURVEY);

async function publishSurvey(survey: IEventPostSurvey) {
  await doPublish({ surveyId: survey.id });
  await refetch();
}

async function closeSurvey(survey: IEventPostSurvey) {
  await doClose({ surveyId: survey.id });
  await refetch();
}

// ── Fill modal (participant) ─────────────────────────────────────────────────

const fillModalOpen = ref(false);
const fillingSurvey = ref<IEventPostSurvey | null>(null);

function openFillModal(survey: IEventPostSurvey) {
  fillingSurvey.value = survey;
  fillModalOpen.value = true;
}

function onFillCompleted() {
  fillModalOpen.value = false;
  fillingSurvey.value = null;
}
</script>
