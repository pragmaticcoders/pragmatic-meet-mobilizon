<template>
  <redirect-with-account
    v-if="uri && isFederating"
    :uri="uri"
    :pathAfterLogin="`/@${preferredUsername}`"
    :sentence="
      t(
        `We will redirect you to your instance in order to interact with this group`
      )
    "
  />
</template>
<script lang="ts" setup>
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { useGroup } from "@/composition/apollo/group";
import { displayName } from "@/types/actor";
import { computed, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { useQuery } from "@vue/apollo-composable";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useRouter } from "vue-router";
import RouteName from "@/router/name";
import { LoginErrorCode } from "@/types/enums";

const props = defineProps<{
  preferredUsername: string;
}>();

const { group } = useGroup(computed(() => props.preferredUsername));

const { t } = useI18n({ useScope: "global" });
const router = useRouter();

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);
const config = computed(() => configResult.value?.config);
const isFederating = computed(() => config.value?.federating ?? true);

// If federation is disabled, redirect to login immediately
watch(
  isFederating,
  (federating) => {
    if (federating === false) {
      router.replace({
        name: RouteName.LOGIN,
        query: {
          code: LoginErrorCode.NEED_TO_LOGIN,
          redirect: `/@${props.preferredUsername}`,
        },
      });
    }
  },
  { immediate: true }
);

const groupTitle = computed((): undefined | string => {
  return group && displayName(group.value);
});

const uri = computed((): string | undefined => {
  return group.value?.url;
});

useHead({
  title: computed(() =>
    t("Join group {group}", {
      group: groupTitle.value,
    })
  ),
});
</script>
