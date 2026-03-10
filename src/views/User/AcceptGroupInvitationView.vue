<template>
  <section class="max-w-screen-xl mx-auto px-4 md:px-16 py-8">
    <o-loading v-if="loading" :active="true" class="o-loading--enhanced" />
    <template v-else>
      <template v-if="error">
        <h1 class="text-2xl font-bold mb-4">
          {{ t("Group invitation") }}
        </h1>
        <o-notification variant="danger" :closable="false">
          {{ error }}
        </o-notification>
      </template>
      <div v-else-if="invitation" class="space-y-4">
        <h1 class="text-2xl font-bold">
          {{ t("You are invited to join") }} {{ invitation.group?.name }}
        </h1>
        <p v-if="processing" class="text-gray-600">
          {{ t("Processing invitation...") }}
        </p>
      </div>
    </template>
  </section>
</template>

<script lang="ts" setup>
import {
  GROUP_INVITATION_BY_TOKEN,
  ACCEPT_GROUP_INVITATION,
} from "@/graphql/member";
import RouteName from "@/router/name";
import { useRoute, useRouter } from "vue-router";
import { ref, computed, onMounted } from "vue";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });
const route = useRoute();
const router = useRouter();
const token = computed(() => route.params.token as string);

const loading = ref(true);
const error = ref("");
const processing = ref(false);
const acceptDone = ref(false);

const {
  result: invitationResult,
  onResult: onInvitationResult,
  onError: onInvitationError,
} = useQuery(
  GROUP_INVITATION_BY_TOKEN,
  () => ({ token: token.value }),
  () => ({
    enabled: !!token.value,
  })
);

const invitation = computed(
  () => invitationResult.value?.groupInvitationByToken ?? null
);

const { mutate: acceptGroupInvitation } = useMutation(ACCEPT_GROUP_INVITATION);

async function handleAccept() {
  if (!token.value || acceptDone.value) return;
  processing.value = true;
  error.value = "";
  try {
    const { data } = await acceptGroupInvitation({ token: token.value });
    acceptDone.value = true;
    const result = data?.acceptGroupInvitation;
    if (!result) {
      error.value = t("Invalid response.");
      return;
    }
    if (result.requiresRegistration && result.invitationToken) {
      const email = invitation.value?.email;
      await router.push({
        name: RouteName.REGISTER,
        query: {
          invitation: result.invitationToken,
          ...(email ? { email } : {}),
        },
      });
      return;
    }
    if (result.member?.parent) {
      const g = result.member.parent;
      const preferredUsername = g.domain
        ? `${g.preferredUsername}@${g.domain}`
        : g.preferredUsername;
      await router.push({
        name: RouteName.GROUP,
        params: { preferredUsername },
      });
      return;
    }
    await router.push({ name: RouteName.MY_GROUPS });
  } catch (err: any) {
    const apiMessage = err?.graphQLErrors?.[0]?.message;
    error.value = apiMessage
      ? invitationErrorMessage(apiMessage)
      : t("Failed to accept invitation.");
  } finally {
    processing.value = false;
  }
}

/** Map API error message to a clear, translatable message for the user. */
function invitationErrorMessage(apiMessage: string | undefined): string {
  if (!apiMessage) return t("Failed to load invitation.");
  const msg = apiMessage.toLowerCase();
  if (msg.includes("expired")) return t("Invitation has expired.");
  if (msg.includes("already been used"))
    return t("Invitation has already been used.");
  if (msg.includes("no longer exists"))
    return t("The group you were invited to no longer exists.");
  return apiMessage;
}

onInvitationResult((res) => {
  loading.value = false;
  if (res.data?.groupInvitationByToken) {
    handleAccept();
  } else if (res.data && res.data.groupInvitationByToken === null) {
    error.value = t("Invitation not found or invalid.");
  }
  if (res.error) {
    const apiMessage = res.error.graphQLErrors?.[0]?.message;
    error.value = invitationErrorMessage(apiMessage);
  }
});

onInvitationError((err) => {
  loading.value = false;
  const apiMessage = err?.graphQLErrors?.[0]?.message;
  error.value = invitationErrorMessage(apiMessage);
});

onMounted(() => {
  if (!token.value) {
    loading.value = false;
    error.value = t("Invalid invitation link.");
  }
});
</script>
