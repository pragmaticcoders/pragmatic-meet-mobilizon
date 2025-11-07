<template>
  <redirect-with-account
    v-if="uri && isFederating"
    :uri="uri"
    :pathAfterLogin="`/events/${uuid}`"
    :sentence="sentence"
  />
</template>
<script lang="ts" setup>
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { useFetchEvent } from "@/composition/apollo/event";
import { useHead } from "@/utils/head";
import { computed, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useQuery } from "@vue/apollo-composable";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useRouter } from "vue-router";
import RouteName from "@/router/name";
import { LoginErrorCode } from "@/types/enums";

const props = defineProps<{
  uuid: string;
}>();

const { event } = useFetchEvent(computed(() => props.uuid));

const { t } = useI18n({ useScope: "global" });
const router = useRouter();

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);
const config = computed(() => configResult.value?.config);
const isFederating = computed(() => config.value?.federating ?? true);

// If federation is disabled, redirect to login immediately
watch(
  [isFederating, () => props.uuid],
  ([federating, uuid]) => {
    if (federating === false && uuid) {
      router.replace({
        name: RouteName.LOGIN,
        query: {
          code: LoginErrorCode.NEED_TO_LOGIN,
          redirect: `/events/${uuid}`,
        },
      });
    }
  },
  { immediate: true }
);

useHead({
  title: computed(() => t("Participation with account")),
  meta: [{ name: "robots", content: "noindex" }],
});

const uri = computed((): string | undefined => {
  return event.value?.url;
});

const sentence = t(
  "We will redirect you to your instance in order to interact with this event"
);
</script>
