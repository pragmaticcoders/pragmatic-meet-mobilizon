<template>
  <div v-if="loading" class="flex justify-center items-center p-8">
    <o-loading :active="true" :is-full-page="false" />
    <span class="ml-2">{{ t("Loading...") }}</span>
  </div>
  <empty-content v-else-if="error || !person" icon="account">
    {{ t("This profile was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.USERS }"
        >{{ t("Back to user list") }}</o-button
      >
    </template>
  </empty-content>
</template>

<script lang="ts" setup>
/**
 * This component redirects from the old /admin/profiles/:id route to the new
 * /admin/users/:userId route. Since we're in single-profile mode, profile details
 * are now shown on the user details page.
 */
import { GET_PERSON } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import RouteName from "@/router/name";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useQuery } from "@vue/apollo-composable";
import { watch } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";

const props = defineProps<{ id: string }>();

const router = useRouter();
const { t } = useI18n({ useScope: "global" });

const {
  result: personResult,
  loading,
  error,
} = useQuery<{ person: IPerson }>(GET_PERSON, () => ({
  actorId: props.id,
  organizedEventsPage: 1,
  organizedEventsLimit: 1,
  participationsPage: 1,
  participationLimit: 1,
  membershipsPage: 1,
  membershipsLimit: 1,
}));

// When we get the person data, redirect to the user page
watch(
  () => personResult.value?.person,
  (person) => {
    if (person?.user?.id) {
      router.replace({
        name: RouteName.ADMIN_USER_PROFILE,
        params: { id: person.user.id },
      });
    }
  },
  { immediate: true }
);
</script>





