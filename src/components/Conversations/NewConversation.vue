<template>
  <div class="bg-white h-full flex flex-col">
    <!-- Header -->
    <div
      class="conversation-header bg-white border-b border-[#cac9cb] px-4 md:px-16 py-4 md:py-8 flex items-center gap-4"
    >
      <h1
        class="text-[30px] leading-[40px] font-bold text-[#1c1b1f]"
        style="font-family: Mulish, sans-serif"
      >
        {{ t("New conversation") }}
      </h1>
    </div>

    <!-- Form Content -->
    <form @submit="sendForm" class="flex-1 flex flex-col">
      <div
        class="conversation-content flex-1 overflow-y-auto px-4 md:px-16 py-4 md:py-6 bg-white space-y-6"
      >
        <!-- Recipients Field -->
        <div>
          <div class="flex items-center gap-4">
            <label
              class="text-[17px] leading-[26px] font-bold text-[#1c1b1f] min-w-fit"
              style="font-family: Mulish, sans-serif"
            >
              {{ t("To:") }}
            </label>
            <div class="flex-1">
              <div
                v-if="isLoadingMentions"
                class="flex items-center gap-2 p-2 text-gray-600"
              >
                <svg
                  class="animate-spin h-4 w-4"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                <span class="text-sm">{{ t("Loading mentions...") }}</span>
              </div>
              <ActorAutoComplete
                v-model="actorMentions"
                :disabled="isLoadingMentions"
              />
            </div>
          </div>
        </div>

        <!-- Message Field -->
        <div class="flex-1 flex flex-col">
          <div class="flex-1 min-h-[150px]">
            <Editor
              v-model="text"
              mode="basic"
              :aria-label="'Message body'"
              v-if="currentActor"
              :currentActor="currentActor"
              :placeholder="t('Write your message...')"
              class="h-full"
            />
          </div>
        </div>

        <!-- Error Messages -->
        <o-notification
          class="my-2"
          variant="danger"
          :closable="false"
          v-for="error in errors"
          :key="error"
        >
          {{ error }}
        </o-notification>
      </div>

      <!-- Footer with Cancel and Send Buttons -->
      <div
        class="conversation-footer bg-white border-t border-[#cac9cb] px-4 md:px-16 py-6 md:py-8"
      >
        <div class="flex justify-between items-center gap-4">
          <button
            type="button"
            @click="handleClose"
            class="size-[60px] md:size-auto md:px-4 md:py-3 flex items-center justify-center gap-2 bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors text-[17px] leading-[26px] font-bold"
            style="font-family: Mulish, sans-serif"
          >
            <span class="hidden md:inline">{{ t("Cancel") }}</span>
            <o-icon icon="close" class="md:hidden" />
          </button>
          <button
            type="submit"
            :disabled="!canSend || isLoading || isLoadingMentions"
            class="bg-[#155eef] text-white size-[60px] md:size-auto md:px-4 md:py-3 flex items-center justify-center gap-2 hover:bg-[#0d4dd8] transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-[17px] leading-[26px] font-bold"
            style="font-family: Mulish, sans-serif"
          >
            <span v-if="isLoading" class="flex items-center gap-2">
              <svg
                class="animate-spin h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                ></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              <span class="hidden md:inline">{{ t("Sending...") }}</span>
            </span>
            <span v-else-if="isLoadingMentions" class="flex items-center gap-2">
              <svg
                class="animate-spin h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                ></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              <span class="hidden md:inline">{{ t("Loading...") }}</span>
            </span>
            <span v-else class="flex items-center gap-2">
              <span class="hidden md:inline">{{ t("Send") }}</span>
              <o-icon icon="send" />
            </span>
          </button>
        </div>
      </div>
    </form>
  </div>
</template>

<style scoped>
/* Mobile specific styles */
@media (max-width: 768px) {
  .conversation-header {
    padding-left: 1.5rem;
    padding-right: 1.5rem;
    padding-top: 1rem;
    padding-bottom: 1rem;
  }

  .conversation-header h1 {
    font-size: 20px;
    line-height: 28px;
  }

  .conversation-content {
    padding-left: 1.5rem;
    padding-right: 1.5rem;
  }

  .conversation-footer {
    padding-left: 1.5rem;
    padding-right: 1.5rem;
    padding-top: 1.5rem;
    padding-bottom: 1.5rem;
  }
}
</style>

<script lang="ts" setup>
import { IActor, IGroup, IPerson, usernameWithDomain } from "@/types/actor";
import { computed, defineAsyncComponent, provide, ref } from "vue";
import { useI18n } from "vue-i18n";
import ActorAutoComplete from "../../components/Account/ActorAutoComplete.vue";
import {
  DefaultApolloClient,
  provideApolloClient,
  useLazyQuery,
  useMutation,
} from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";
import { PROFILE_CONVERSATIONS } from "@/graphql/event";
import { POST_PRIVATE_MESSAGE_MUTATION } from "@/graphql/conversations";
import { IConversation } from "@/types/conversation";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useRouter } from "vue-router";
import RouteName from "@/router/name";
import { FETCH_PERSON } from "@/graphql/actor";
import { FETCH_GROUP_PUBLIC } from "@/graphql/group";
import { inject } from "vue";
import type { Notifier } from "@/plugins/notifier";

const props = withDefaults(
  defineProps<{
    personMentions?: string[];
    groupMentions?: string[];
  }>(),
  { personMentions: () => [], groupMentions: () => [] }
);

provide(DefaultApolloClient, apolloClient);

const router = useRouter();
const { t } = useI18n();
const notifier = inject<Notifier>("notifier");

const emit = defineEmits(["close"]);

const errors = ref<string[]>([]);
const isLoading = ref(false);
const isLoadingMentions = ref(false);

const textPersonMentions = computed(() => props.personMentions);
const textGroupMentions = computed(() => props.groupMentions);
const actorMentions = ref<IActor[]>([]);

const { load: fetchPerson } = provideApolloClient(apolloClient)(() =>
  useLazyQuery<{ fetchPerson: IPerson }, { username: string }>(FETCH_PERSON)
);
const { load: fetchGroup } = provideApolloClient(apolloClient)(() =>
  useLazyQuery<{ group: IGroup }, { name: string }>(FETCH_GROUP_PUBLIC)
);

// Load initial mentions asynchronously with proper error handling
const loadInitialMentions = async () => {
  if (
    textPersonMentions.value.length === 0 &&
    textGroupMentions.value.length === 0
  ) {
    return;
  }

  isLoadingMentions.value = true;

  try {
    // Fetch person mentions
    const personPromises = textPersonMentions.value.map(
      async (textPersonMention) => {
        try {
          const result = (await Promise.race([
            fetchPerson(FETCH_PERSON, { username: textPersonMention }),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error("Timeout")), 10000)
            ),
          ])) as any;

          if (result?.fetchPerson) {
            return result.fetchPerson;
          }
        } catch (error) {
          console.warn(`Failed to fetch person ${textPersonMention}:`, error);
          // Don't add to errors array as this might be expected for invalid mentions
        }
        return null;
      }
    );

    // Fetch group mentions
    const groupPromises = textGroupMentions.value.map(
      async (textGroupMention) => {
        try {
          const result = (await Promise.race([
            fetchGroup(FETCH_GROUP_PUBLIC, { name: textGroupMention }),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error("Timeout")), 10000)
            ),
          ])) as any;

          if (result?.group) {
            return result.group;
          }
        } catch (error) {
          console.warn(`Failed to fetch group ${textGroupMention}:`, error);
          // Add a user-friendly error for group mentions that fail
          errors.value.push(
            `Group "${textGroupMention}" not found or not accessible`
          );
        }
        return null;
      }
    );

    // Wait for all promises to resolve
    const [personResults, groupResults] = await Promise.all([
      Promise.all(personPromises),
      Promise.all(groupPromises),
    ]);

    // Add successful results to actor mentions
    [...personResults, ...groupResults].forEach((actor) => {
      if (actor) {
        actorMentions.value.push(actor);
      }
    });
  } catch (error) {
    console.error("Error loading initial mentions:", error);
    errors.value.push("Failed to load some mentions");
  } finally {
    isLoadingMentions.value = false;
  }
};

// Load mentions when component is created
loadInitialMentions();

// const { t } = useI18n({ useScope: "global" });

const text = ref("");

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { currentActor } = provideApolloClient(apolloClient)(() => {
  return useCurrentActorClient();
});

const canSend = computed(() => {
  return actorMentions.value.length > 0 || /@.+/.test(text.value);
});

const handleClose = () => {
  emit("close");
};

const { mutate: postPrivateMessageMutate, onError: onPrivateMessageError } =
  provideApolloClient(apolloClient)(() =>
    useMutation<
      {
        postPrivateMessage: IConversation;
      },
      {
        text: string;
        actorId: string;
        language?: string;
        mentions?: string[];
        attributedToId?: string;
      }
    >(POST_PRIVATE_MESSAGE_MUTATION, {
      update(cache, result) {
        if (!result.data?.postPrivateMessage) return;
        const cachedData = cache.readQuery<{
          loggedPerson: Pick<IPerson, "conversations" | "id">;
        }>({
          query: PROFILE_CONVERSATIONS,
          variables: {
            page: 1,
          },
        });
        if (!cachedData) return;
        cache.writeQuery({
          query: PROFILE_CONVERSATIONS,
          variables: {
            page: 1,
          },
          data: {
            loggedPerson: {
              ...cachedData?.loggedPerson,
              conversations: {
                ...cachedData.loggedPerson.conversations,
                total: (cachedData.loggedPerson.conversations?.total ?? 0) + 1,
                elements: [
                  ...(cachedData.loggedPerson.conversations?.elements ?? []),
                  result.data.postPrivateMessage,
                ],
              },
            },
          },
        });
      },
    })
  );

onPrivateMessageError((err) => {
  err.graphQLErrors.forEach((error) => {
    errors.value.push(error.message);
  });
});

const sendForm = async (e: Event) => {
  e.preventDefault();

  if (!currentActor.value?.id) {
    errors.value.push("User not authenticated");
    return;
  }

  if (!canSend.value) {
    errors.value.push("Please add recipients and write a message");
    return;
  }

  // Check if user is trying to message themselves
  const isSelfMessage = actorMentions.value.some(
    (actor) => actor.id === currentActor.value?.id
  );
  if (isSelfMessage) {
    errors.value.push("You cannot send a message to yourself");
    return;
  }

  isLoading.value = true;
  // Note: We clear errors after all validation passes, but we already cleared them at the start of the function

  try {
    console.debug("Sending new private message");
    const result = await postPrivateMessageMutate({
      actorId: currentActor.value.id,
      text: text.value,
      mentions: actorMentions.value.map((actor) => usernameWithDomain(actor)),
    });

    if (!result?.data?.postPrivateMessage.conversationParticipantId) {
      errors.value.push("Failed to create conversation");
      return;
    }

    // Success - show notification and navigate to the conversation
    notifier?.success(t("Message sent successfully"));

    router.push({
      name: RouteName.CONVERSATION,
      params: { id: result.data.postPrivateMessage.conversationParticipantId },
    });
    handleClose();
  } catch (error) {
    console.error("Failed to send message:", error);
    errors.value.push("Failed to send message. Please try again.");
  } finally {
    isLoading.value = false;
  }
};
</script>
