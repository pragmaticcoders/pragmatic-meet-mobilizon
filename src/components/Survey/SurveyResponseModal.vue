<template>
  <o-modal
    :active="active"
    @update:active="$emit('update:active', $event)"
    has-modal-card
    :close-button-aria-label="t('Close')"
  >
    <div class="modal-card" style="min-width: 480px; max-width: 680px">
      <header class="modal-card-head flex items-center bg-primary-700 px-6 py-4">
        <p class="modal-card-title text-lg font-semibold text-white">
          {{ title || t("Survey response") }}
          <span
            v-if="actorName"
            class="text-sm font-normal text-primary-200 ml-2"
          >— {{ actorName }}</span>
        </p>
      </header>

      <section class="modal-card-body px-6 py-6">
        <div v-if="loading" class="flex justify-center py-8">
          <div
            class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"
          ></div>
        </div>

        <div
          v-else-if="error"
          class="flex items-start gap-2 text-error-600 text-sm bg-error-50 border border-error-200 px-4 py-3"
        >
          <span class="font-medium">{{ error }}</span>
        </div>

        <div
          v-else-if="fields.length === 0"
          class="text-center text-gray-500 text-sm py-6"
        >
          {{ t("No survey response found.") }}
        </div>

        <dl v-else class="divide-y divide-gray-100">
          <div
            v-for="field in fields"
            :key="field.label"
            class="py-4 first:pt-0 last:pb-0"
          >
            <dt
              class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1"
            >
              {{ field.label }}
            </dt>
            <dd class="text-gray-900 text-sm leading-relaxed">
              {{ field.value }}
            </dd>
          </div>
        </dl>
      </section>

      <footer
        class="modal-card-foot flex justify-end px-6 py-4 border-t border-gray-200 bg-white"
      >
        <o-button @click="$emit('update:active', false)">{{
          t("Close")
        }}</o-button>
      </footer>
    </div>
  </o-modal>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

interface SurveyField {
  label: string;
  value: string;
}

interface SurveyResponseData {
  schema?: {
    components?: Array<{ key?: string; name?: string; label?: string; type?: string }>;
    fields?: Array<{ key?: string; name?: string; label?: string; type?: string }>;
  };
  data?: Record<string, unknown>;
}

const props = defineProps<{
  active: boolean;
  loading?: boolean;
  error?: string | null;
  responseData?: SurveyResponseData | null;
  title?: string;
  actorName?: string;
}>();

defineEmits<{ "update:active": [value: boolean] }>();

const fields = computed((): SurveyField[] => {
  if (!props.responseData) return [];
  const { schema, data } = props.responseData;
  if (!data) return [];

  const rawFields: any[] =
    (schema as any)?.components ?? (schema as any)?.fields ?? [];

  return rawFields
    .filter((f: any) => {
      const key = f.key ?? f.name;
      return key && key in data && f.type !== "button";
    })
    .map((f: any) => {
      const key = f.key ?? f.name;
      return {
        label: f.label ?? key,
        value: String(data[key as string] ?? ""),
      };
    });
});
</script>
