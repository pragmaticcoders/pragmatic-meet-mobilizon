<template>
  <div class="max-w-5xl mx-auto px-4 py-8">
    <!-- Back navigation + title -->
    <div class="flex items-center gap-3 mb-6">
      <router-link
        :to="{ name: ActorRouteName.GROUP, params: { preferredUsername } }"
        class="text-primary-600 hover:text-primary-800 flex items-center gap-1 text-sm font-medium"
      >
        <span>←</span>
        {{ t("Back to group") }}
      </router-link>
    </div>

    <h1
      class="text-2xl font-bold text-gray-900 mb-6"
      style="font-family: var(--font-family-primary)"
    >
      {{ surveyTitle }}
    </h1>

    <!-- Filter bar -->
    <div
      class="flex flex-col sm:flex-row items-start sm:items-center gap-3 mb-6 bg-white border border-gray-200 px-4 py-3"
    >
      <o-input
        v-model="filterName"
        :placeholder="t('Filter by name')"
        icon="magnify"
        class="flex-1 w-full"
      />
      <o-input
        v-model="filterEmail"
        :placeholder="t('Filter by email')"
        icon="email-outline"
        class="flex-1 w-full"
      />
      <o-button
        variant="primary"
        icon-left="download"
        :disabled="filteredResponses.length === 0"
        @click="exportCsv"
        class="shrink-0"
      >
        {{ t("Export to CSV") }}
      </o-button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
    </div>

    <!-- Error -->
    <div
      v-else-if="error"
      class="text-error-600 text-sm bg-error-50 border border-error-200 px-4 py-3"
    >
      {{ error.message }}
    </div>

    <!-- Empty -->
    <p
      v-else-if="filteredResponses.length === 0"
      class="text-gray-500 italic text-center py-12"
      style="font-size: 17px; line-height: 1.53; font-weight: 500; font-family: var(--font-family-primary)"
    >
      {{ t("No responses yet.") }}
    </p>

    <!-- Table -->
    <div v-else class="bg-white border border-gray-200 overflow-hidden">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-700">{{ t("Respondent") }}</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-700">{{ t("Email") }}</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-700">{{ t("Submitted at") }}</th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr
            v-for="(response, idx) in filteredResponses"
            :key="idx"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3 text-gray-900 font-medium">
              {{ response.respondentName || response.respondentUsername || t("Unknown") }}
              <span
                v-if="response.respondentUsername"
                class="text-xs text-gray-500 ml-1"
              >@{{ response.respondentUsername }}</span>
            </td>
            <td class="px-4 py-3 text-gray-600">{{ response.respondentEmail || "—" }}</td>
            <td class="px-4 py-3 text-gray-600 whitespace-nowrap">
              {{ formatDate(response.submittedAt) }}
            </td>
            <td class="px-4 py-3 text-right">
              <o-button size="small" variant="info" icon-left="eye" @click="openModal(response)">
                {{ t("View") }}
              </o-button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Response detail modal -->
    <o-modal
      v-model:active="modalOpen"
      has-modal-card
      :close-button-aria-label="t('Close')"
    >
      <div class="modal-card">
        <header class="modal-card-head flex items-center bg-primary-700 px-6 py-4">
          <p class="modal-card-title text-lg font-semibold text-white">
            {{ t("Survey response") }}
            <span
              v-if="modalRespondentName"
              class="text-sm font-normal text-primary-200 ml-2"
            >— {{ modalRespondentName }}</span>
          </p>
        </header>

        <section class="modal-card-body px-6 py-6">
          <div v-if="modalFields.length === 0" class="text-center text-gray-500 text-sm py-6">
            {{ t("No survey response found for this participant.") }}
          </div>
          <dl v-else class="divide-y divide-gray-100">
            <div
              v-for="field in modalFields"
              :key="field.label"
              class="py-4 first:pt-0 last:pb-0"
            >
              <dt class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1">
                {{ field.label }}
              </dt>
              <dd class="text-gray-900 text-sm leading-relaxed">{{ field.value }}</dd>
            </div>
          </dl>
        </section>

        <footer class="modal-card-foot flex justify-end px-6 py-4 border-t border-gray-200 bg-white">
          <o-button @click="modalOpen = false">{{ t("Close") }}</o-button>
        </footer>
      </div>
    </o-modal>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed } from "vue";
import { useI18n } from "vue-i18n";
import { useQuery } from "@vue/apollo-composable";
import { ActorRouteName } from "@/router/actor";
import { GROUP_POST_SURVEY_RESPONSES } from "@/graphql/groupPostSurveys";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  preferredUsername: string;
  surveyId: string;
}>();

// ── Data fetching ─────────────────────────────────────────────────────────────

const { result, loading, error } = useQuery(
  GROUP_POST_SURVEY_RESPONSES,
  () => ({ surveyId: props.surveyId })
);

interface ResponseItem {
  respondentId: string;
  respondentName: string | null;
  respondentUsername: string | null;
  respondentEmail: string | null;
  submittedAt: string | null;
  schema: Record<string, unknown>;
  data: Record<string, unknown>;
}

const responses = computed<ResponseItem[]>(
  () => result.value?.groupPostSurveyResponses ?? []
);

const surveyTitle = computed(() => {
  const first = responses.value[0];
  return (first?.schema as any)?.title ?? t("Survey responses");
});

// ── Filters ───────────────────────────────────────────────────────────────────

const filterName = ref("");
const filterEmail = ref("");

const filteredResponses = computed(() => {
  const name = filterName.value.toLowerCase();
  const email = filterEmail.value.toLowerCase();
  return responses.value.filter((r) => {
    const nameMatch =
      !name ||
      (r.respondentName ?? "").toLowerCase().includes(name) ||
      (r.respondentUsername ?? "").toLowerCase().includes(name);
    const emailMatch =
      !email || (r.respondentEmail ?? "").toLowerCase().includes(email);
    return nameMatch && emailMatch;
  });
});

// ── Date formatting ───────────────────────────────────────────────────────────

function formatDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return new Intl.DateTimeFormat(undefined, {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

// ── Response modal ────────────────────────────────────────────────────────────

const modalOpen = ref(false);
const modalRespondentName = ref("");
const modalFields = ref<{ label: string; value: string }[]>([]);

function schemaFieldDefs(schema: Record<string, unknown>) {
  const components: any[] =
    (schema?.components as any[]) ?? (schema?.fields as any[]) ?? [];
  return components
    .filter((f: any) => f.type !== "button" && (f.key ?? f.name))
    .map((f: any) => ({ key: f.key ?? f.name, label: f.label ?? (f.key ?? f.name) }));
}

function openModal(response: ResponseItem) {
  modalRespondentName.value =
    response.respondentName || response.respondentUsername || "";
  const fieldDefs = schemaFieldDefs(response.schema);
  modalFields.value = fieldDefs
    .filter((f) => f.key in (response.data ?? {}))
    .map((f) => ({ label: f.label, value: String(response.data?.[f.key] ?? "") }));
  modalOpen.value = true;
}

// ── CSV export ────────────────────────────────────────────────────────────────

function exportCsv() {
  const firstSchema = filteredResponses.value[0]?.schema;
  const fieldDefs = firstSchema ? schemaFieldDefs(firstSchema) : [];

  const headers = [
    t("Respondent"),
    t("Email"),
    t("Submitted at"),
    ...fieldDefs.map((f) => f.label),
  ];

  const rows = filteredResponses.value.map((r) => {
    const base = [
      r.respondentName || r.respondentUsername || "",
      r.respondentEmail || "",
      r.submittedAt || "",
    ];
    const answers = fieldDefs.map((f) => String(r.data?.[f.key] ?? ""));
    return [...base, ...answers].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",");
  });

  const csv = [headers.map((h) => `"${h}"`).join(","), ...rows].join("\n");
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `group-survey-${props.surveyId}-responses.csv`;
  a.click();
  URL.revokeObjectURL(url);
}
</script>
