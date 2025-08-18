<template>
  <div>
    <o-upload
      rootClass="!flex"
      v-if="!imageSrc || imagePreviewLoadingError || pictureTooBig"
      @update:modelValue="onFileChanged"
      :accept="accept"
      drag-drop
    >
      <div
        class="w-full flex flex-col items-center justify-center py-8 px-4 border border-gray-300 bg-white hover:bg-gray-50 transition-colors cursor-pointer"
      >
        <span class="flex flex-col items-center gap-2">
          <Upload class="w-6 h-6 text-gray-500" />
          <span class="text-base font-medium text-gray-700"
            >{{ $t("Click to upload") }} {{ textFallbackWithDefault }}</span
          >
        </span>
        <p v-if="pictureTooBig" class="text-red-600 mt-2 text-sm">
          {{
            $t(
              "The selected picture is too heavy. You need to select a file smaller than {size}.",
              { size: formatBytes(maxSize) }
            )
          }}
        </p>
        <span
          class="text-center text-red-600 mt-2 text-sm"
          v-if="imagePreviewLoadingError"
          >{{ $t("Error while loading the preview") }}</span
        >
      </div>
    </o-upload>
  </div>

  <div
    v-if="
      imageSrc &&
      !imagePreviewLoadingError &&
      !pictureTooBig &&
      !imagePreviewLoadingError
    "
  >
    <figure
      class="w-full relative mx-auto my-4"
      v-if="imageSrc && !imagePreviewLoadingError"
    >
      <img
        class="w-full h-48 object-cover border border-gray-300"
        :src="imageSrc"
        @error="showImageLoadingError"
      />
      <o-button
        class="!absolute right-2 bottom-2"
        variant="danger"
        size="small"
        v-if="imageSrc"
        @click="removeOrClearPicture"
        @keyup.enter="removeOrClearPicture"
      >
        {{ $t("Clear") }}
      </o-button>
    </figure>
  </div>
</template>

<script lang="ts" setup>
import { IMedia } from "@/types/media.model";
import { computed, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import Upload from "vue-material-design-icons/Upload.vue";
import { formatBytes } from "@/utils/datetime";

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    modelValue: File | null;
    defaultImage?: IMedia | null;
    accept?: string;
    textFallback?: string;
    maxSize?: number;
  }>(),
  {
    accept: "image/gif,image/png,image/jpeg,image/webp",
    maxSize: 10_485_760,
  }
);

const textFallbackWithDefault = props.textFallback ?? t("Avatar");

const emit = defineEmits(["update:modelValue"]);

const imagePreviewLoadingError = ref(false);

const pictureTooBig = computed((): boolean => {
  return props.modelValue != null && props.modelValue?.size > props.maxSize;
});

const imageSrc = computed((): string | null | undefined => {
  if (props.modelValue !== undefined) {
    if (props.modelValue === null) return null;
    try {
      return URL.createObjectURL(props.modelValue);
    } catch (e) {
      console.error(e, props.modelValue);
    }
  }
  return props.defaultImage?.url;
});

const onFileChanged = (file: File | null): void => {
  emit("update:modelValue", file);
};

const removeOrClearPicture = async (): Promise<void> => {
  onFileChanged(null);
};

watch(imageSrc, () => {
  imagePreviewLoadingError.value = false;
});

const showImageLoadingError = (): void => {
  imagePreviewLoadingError.value = true;
};
</script>
