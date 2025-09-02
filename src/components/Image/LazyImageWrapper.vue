<template>
  <lazy-image
    v-if="pictureOrDefault.url !== undefined"
    :src="pictureOrDefault.url"
    :blurhash="pictureOrDefault.metadata?.blurhash"
    :rounded="rounded"
  />
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { IMedia } from "@/types/media.model";
import { useDefaultPicture } from "@/composition/apollo/config";
import LazyImage from "../Image/LazyImage.vue";

const { defaultPicture } = useDefaultPicture();

const DEFAULT_CARD_URL = "/img/pragmatic_social_media.svg";
const DEFAULT_BLURHASH = "MCHKI4El-P-U}+={R-WWoes,Iu-P=?R,xD";
const DEFAULT_PICTURE = {
  url: DEFAULT_CARD_URL,
  metadata: {
    blurhash: DEFAULT_BLURHASH,
  },
};

const props = withDefaults(
  defineProps<{
    picture?: IMedia | null;
    rounded?: boolean;
  }>(),
  {
    rounded: false,
  }
);

const pictureOrDefault = computed(() => {
  if (props.picture === null) {
    if (defaultPicture?.value?.url) {
      return {
        url: defaultPicture.value.url,
        metadata: {
          blurhash: (defaultPicture.value as any).metadata?.blurhash || DEFAULT_BLURHASH,
        },
      };
    }
    return DEFAULT_PICTURE;
  }
  return {
    url: props?.picture?.url,
    metadata: {
      blurhash: props?.picture?.metadata?.blurhash,
    },
  };
});
</script>
