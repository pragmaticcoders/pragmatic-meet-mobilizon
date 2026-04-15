<template>
  <div class="survey-builder-wrapper" style="height: 100%; overflow: hidden">
    <!-- Loading skeleton while formio initialises inside the iframe -->
    <div v-if="!builderReady && iframeSrc" class="p-4 space-y-3">
      <o-skeleton height="48px" />
      <o-skeleton height="200px" />
      <o-skeleton height="48px" />
    </div>

    <!--
      The builder is a fully isolated iframe: no CSS conflicts with Tailwind.
      It is always rendered in a modal, so height is controlled by the modal container.
    -->
    <iframe
      v-if="iframeSrc"
      ref="iframeRef"
      :src="iframeSrc"
      style="width: 100%; height: 100%; border: none; display: block"
      :style="{ visibility: builderReady ? 'visible' : 'hidden' }"
      sandbox="allow-scripts allow-same-origin"
      scrolling="no"
    />

    <div v-if="!iframeSrc" class="p-4 text-center text-gray-500">
      {{ t("Survey module is not available") }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { useI18n } from "vue-i18n";
import { usePlugins } from "@/composition/apollo/plugins";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  contextId: string;
  initialSchema?: object;
}>();

const emit = defineEmits<{
  "schema-change": [schema: object];
  error: [error: Error];
}>();

const { surveysAdapterStaticUrl } = usePlugins();
const iframeRef = ref<HTMLIFrameElement | null>(null);
const builderReady = ref(false);

// Last schema content sent to the iframe (as JSON string).
// Used to break the feedback loop:
//   survey-builder-ready  → send initialSchema → formio change → schema-change emit
//   → surveySchema in EditView updates → watch fires → would send back same schema
//   → formio change again → infinite loop (1000 events crash)
// If the incoming schema content equals what we last sent, we skip re-sending.
let lastSentSchemaJson = "";

const iframeSrc = computed(() => {
  if (!surveysAdapterStaticUrl.value) return null;
  const url = new URL(`${surveysAdapterStaticUrl.value}/builder.html`);
  url.searchParams.set("contextId", props.contextId);
  return url.toString();
});

function sendSchemaToIframe(schema: object) {
  if (!iframeRef.value?.contentWindow) return;
  const json = JSON.stringify(schema);
  if (json === lastSentSchemaJson) return; // same content — skip to break the loop
  lastSentSchemaJson = json;
  iframeRef.value.contentWindow.postMessage(
    { type: "survey-set-schema", schema: JSON.parse(json) },
    "*"
  );
}

function handleMessage(event: MessageEvent) {
  try {
    if (!event.data) return;
    switch (event.data.type) {
      case "survey-builder-ready":
        builderReady.value = true;
        if (props.initialSchema) {
          sendSchemaToIframe(props.initialSchema);
        }
        break;

      case "survey-builder-change": {
        // JSON round-trip strips formio internal objects / Vue Proxy wrappers.
        const schema = JSON.parse(JSON.stringify(event.data.schema));
        // Record this as the last sent content so the watch below won't re-send it.
        lastSentSchemaJson = JSON.stringify(schema);
        emit("schema-change", schema);
        break;
      }
    }
  } catch (err) {
    console.error("SurveyBuilderWrapper handleMessage error:", err);
  }
}

// Only send schema if content actually changed from an external source.
// This watch handles async loads (e.g. schema fetched from API after mount).
watch(
  () => props.initialSchema,
  (newSchema) => {
    if (newSchema && builderReady.value) {
      sendSchemaToIframe(newSchema);
    }
  }
);

onMounted(() => window.addEventListener("message", handleMessage));
onUnmounted(() => window.removeEventListener("message", handleMessage));
</script>
