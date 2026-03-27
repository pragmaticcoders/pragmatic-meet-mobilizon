<template>
  <div class="survey-builder-wrapper" style="height: 100%; min-height: 500px">
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
      style="width: 100%; height: 100%; min-height: 500px; border: none"
      :style="{ display: builderReady ? 'block' : 'none' }"
      sandbox="allow-scripts allow-same-origin"
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

const iframeSrc = computed(() => {
  if (!surveysAdapterStaticUrl.value) return null;
  const url = new URL(`${surveysAdapterStaticUrl.value}/builder.html`);
  url.searchParams.set("contextId", props.contextId);
  return url.toString();
});

function handleMessage(event: MessageEvent) {
  if (!event.data) return;
  switch (event.data.type) {
    case "survey-builder-ready":
      builderReady.value = true;
      if (props.initialSchema && iframeRef.value?.contentWindow) {
        iframeRef.value.contentWindow.postMessage(
          { type: "survey-set-schema", schema: props.initialSchema },
          "*"
        );
      }
      break;
    case "survey-builder-change":
      emit("schema-change", event.data.schema);
      break;
  }
}

watch(
  () => props.initialSchema,
  (newSchema) => {
    if (newSchema && builderReady.value && iframeRef.value?.contentWindow) {
      iframeRef.value.contentWindow.postMessage(
        { type: "survey-set-schema", schema: newSchema },
        "*"
      );
    }
  }
);

onMounted(() => window.addEventListener("message", handleMessage));
onUnmounted(() => window.removeEventListener("message", handleMessage));
</script>
