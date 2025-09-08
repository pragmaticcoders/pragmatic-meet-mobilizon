<template>
  <div class="conversation-view" v-if="conversation">
    <div class="conversation-header">
      <div class="header-top">
        <router-link
          :to="{ name: RouteName.CONVERSATION_LIST }"
          class="back-link"
        >
          <o-icon icon="chevron-left" />
        </router-link>
        <h1 class="conversation-title">{{ t("Conversation") }}</h1>
      </div>
      <div class="participants-section">
        <span class="participants-label">{{ t("with:") }}</span>
        <div class="conversation-participants">
          <div
            v-for="participant in otherParticipants"
            :key="participant.id"
            class="participant-item"
          >
            <div class="participant-avatar">
              <img
                v-if="participant.avatar?.url"
                :src="participant.avatar.url"
                :alt="participant.name"
                class="size-full object-cover rounded-full"
              />
              <o-icon
                v-else
                icon="account-circle"
                class="size-full text-gray-400"
              />
            </div>
            <span class="participant-name">{{ displayName(participant) }}</span>
          </div>
        </div>
      </div>
    </div>
    <div
      v-if="
        conversation.event &&
        !isCurrentActorAuthor &&
        isOriginCommentAuthorEventOrganizer
      "
      class="bg-mbz-yellow p-6 mb-3 rounded flex gap-2 items-center"
    >
      <Calendar :size="36" />
      <i18n-t
        tag="p"
        keypath="This is a announcement from the organizers of event {event}. You can't reply to it, but you can send a private message to event organizers."
      >
        <template #event>
          <b>
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: conversation.event.uuid },
              }"
              >{{ conversation.event.title }}</router-link
            >
          </b>
        </template>
      </i18n-t>
    </div>
    <o-notification v-if="isCurrentActorAuthor" variant="info" closable>
      <i18n-t
        keypath="You have access to this conversation as a member of the {group} group"
        tag="p"
      >
        <template #group>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(conversation.actor),
              },
            }"
            ><b>{{ displayName(conversation.actor) }}</b></router-link
          >
        </template>
      </i18n-t>
    </o-notification>
    <o-notification
      v-else-if="groupParticipants.length > 0 && !conversation.event"
      variant="info"
      closable
    >
      <p>
        {{
          t(
            "The following participants are groups, which means group members are able to reply to this conversation:"
          )
        }}
      </p>
      <ul class="list-disc">
        <li
          v-for="groupParticipant in groupParticipants"
          :key="groupParticipant.id"
        >
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(groupParticipant),
              },
            }"
            ><b>{{ displayName(groupParticipant) }}</b></router-link
          >
        </li>
      </ul>
    </o-notification>
    <o-notification v-if="error" variant="danger">
      {{ error }}
    </o-notification>
    <section v-if="currentActor" class="conversation-content">
      <div class="messages-container">
        <!-- Date separator -->
        <div
          class="date-separator"
          v-if="
            conversation.comments.elements.length > 0 &&
            conversation.comments.elements[0].insertedAt
          "
        >
          <span class="date-text">{{
            formatMessageDate(conversation.comments.elements[0].insertedAt!)
          }}</span>
        </div>

        <!-- Messages -->
        <div
          v-for="comment in conversation.comments.elements"
          :key="comment.id"
          class="message-bubble"
          :class="{ 'own-message': comment.actor?.id === currentActor.id }"
        >
          <div class="message-avatar" v-if="comment.actor">
            <img
              v-if="comment.actor.avatar?.url"
              :src="comment.actor.avatar.url"
              :alt="comment.actor.name"
              class="size-full object-cover rounded-full"
            />
            <o-icon v-else icon="account-circle" class="size-full" />
          </div>
          <div class="message-content">
            <div class="message-header" v-if="comment.actor">
              <span class="message-author">{{
                displayName(comment.actor)
              }}</span>
              <span class="message-time" v-if="comment.insertedAt">{{
                formatTime(comment.insertedAt)
              }}</span>
            </div>
            <div class="message-body" v-html="comment.text"></div>
          </div>
        </div>
        <div
          v-if="
            conversation.comments.elements.length < conversation.comments.total
          "
          class="text-center py-4"
        >
          <o-button @click="loadMoreComments" variant="text" size="small">{{
            t("Fetch more")
          }}</o-button>
        </div>
      </div>
      <div class="message-input-container" v-if="!error && !conversation.event">
        <form @submit.prevent="reply" class="message-form">
          <div class="input-wrapper">
            <div class="input-row">
              <Editor
                v-model="newComment"
                :aria-label="t('Message body')"
                v-if="currentActor"
                :currentActor="currentActor"
                :placeholder="t('Write a new message')"
                class="message-editor"
                mode="comment"
                ref="editorRef"
              />
              <button
                type="submit"
                :disabled="['<p></p>', ''].includes(newComment)"
                class="send-button"
              >
                <span class="send-text">{{ t("Send") }}</span>
                <o-icon icon="send" />
              </button>
            </div>
          </div>
        </form>
      </div>
      <div
        v-else-if="
          conversation.event &&
          !isCurrentActorAuthor &&
          isOriginCommentAuthorEventOrganizer
        "
        class="bg-mbz-yellow p-6 rounded flex gap-2 items-center mt-3"
      >
        <Calendar :size="36" />
        <i18n-t
          tag="p"
          keypath="This is a announcement from the organizers of event {event}. You can't reply to it, but you can send a private message to event organizers."
        >
          <template #event>
            <b>
              <router-link
                :to="{
                  name: RouteName.EVENT,
                  params: { uuid: conversation.event.uuid },
                }"
                >{{ conversation.event.title }}</router-link
              >
            </b>
          </template>
        </i18n-t>
      </div>
    </section>
  </div>
</template>
<style lang="scss" scoped>
.conversation-view {
  @apply h-screen flex flex-col bg-white max-w-screen-xl mx-auto;

  .conversation-header {
    @apply bg-white border-b border-[#cac9cb] px-4 md:px-16 py-4 md:py-8 flex flex-col gap-4;

    .header-top {
      @apply flex items-center gap-4;

      .back-link {
        @apply inline-flex items-center justify-center size-[50px] min-w-[42px] min-h-[42px] hover:bg-gray-50;
        text-decoration: none;

        :deep(.o-icon) {
          @apply text-[#737275] size-6;
        }
      }

      .conversation-title {
        @apply text-[30px] leading-[40px] font-bold text-[#1c1b1f];
        font-family: "Mulish", sans-serif;
      }
    }

    .participants-section {
      @apply flex items-center gap-3 flex-wrap;

      .participants-label {
        @apply text-[18px] leading-[26px] font-medium text-[#6b7280];
        font-family: "Mulish", sans-serif;
      }

      .conversation-participants {
        @apply flex items-center gap-3 flex-wrap;

        .participant-item {
          @apply flex items-center gap-2 bg-gray-50 hover:bg-gray-100 transition-colors rounded-full px-3 py-2;

          .participant-avatar {
            @apply size-8 rounded-full overflow-hidden flex items-center justify-center;

            :deep(.o-icon) {
              @apply size-6;
            }
          }

          .participant-name {
            @apply text-[16px] leading-[24px] font-medium text-[#1c1b1f];
            font-family: "Mulish", sans-serif;
          }
        }
      }
    }
  }

  .conversation-content {
    @apply flex-1 flex flex-col overflow-hidden bg-white;

    .messages-container {
      @apply flex-1 overflow-y-auto px-4 md:px-16 py-4 md:py-6 bg-white;

      .message-bubble {
        @apply flex gap-2 mb-4;

        &.own-message {
          @apply flex-row-reverse;

          .message-content {
            @apply items-end;
          }
        }

        .message-avatar {
          @apply size-8 md:size-10 rounded-full flex-shrink-0;
        }

        .message-content {
          @apply flex flex-col gap-1 max-w-full md:max-w-[480px];

          .message-header {
            @apply flex gap-10 items-start justify-between;

            .message-author {
              @apply text-[17px] leading-[26px] font-bold text-[#1c1b1f];
              font-family: "Mulish", sans-serif;
            }

            .message-time {
              @apply text-[12px] leading-[18px] font-medium text-[#37363a];
              font-family: "Mulish", sans-serif;
            }
          }

          .message-body {
            @apply bg-[#f5f5f6] p-[20px] text-[15px] leading-[23px] text-[#37363a] font-medium;
            font-family: "Mulish", sans-serif;
          }
        }
      }

      .date-separator {
        @apply flex justify-center items-center py-2 my-2;

        .date-text {
          @apply text-[12px] leading-[18px] font-medium text-[#37363a] text-center;
          font-family: "Mulish", sans-serif;
        }
      }

      :deep(.discussion-comment) {
        @apply mb-4;

        &:last-child {
          @apply mb-0;
        }
      }
    }

    .message-input-container {
      @apply bg-white border-t border-[#cac9cb] px-4 md:px-16 py-6 md:py-8;

      .message-form {
        .input-wrapper {
          @apply flex flex-col gap-2;

          .input-row {
            @apply flex gap-2 md:gap-4 items-start;

            .message-editor {
              @apply flex-1;

              :deep(.editor__content) {
                .ProseMirror {
                  @apply bg-white border border-[#cac9cb] px-[18px] py-[18px] min-h-[62px] md:min-h-[132px];
                  @apply text-[17px] leading-[26px] text-[#37363a] font-medium;
                  font-family: "Mulish", sans-serif;
                }
              }
            }

            .send-button {
              @apply bg-[#155eef] text-white size-[60px] md:size-auto md:px-4 md:py-3 flex items-center justify-center gap-2;
              @apply hover:bg-[#0d4dd8] transition-colors;

              .send-text {
                @apply hidden md:inline text-[17px] leading-[26px] font-bold;
                font-family: "Mulish", sans-serif;
              }
            }
          }

          .input-actions {
            @apply flex items-center gap-1.5;

            .action-button {
              @apply size-[60px] flex items-center justify-center hover:bg-gray-50 transition-colors;

              :deep(.o-icon) {
                @apply size-8 text-[#155eef];
              }
            }
          }
        }
      }
    }
  }

  .o-notification {
    @apply mx-4 my-2;
  }

  .bg-mbz-yellow {
    @apply bg-yellow-100 border border-yellow-300;
  }

  /* Mobile specific styles */
  @media (max-width: 768px) {
    .conversation-header {
      @apply px-6 py-4;

      .header-top {
        .conversation-title {
          @apply text-[20px] leading-[28px];
        }
      }

      .participants-section {
        .participants-label {
          @apply text-[16px] leading-[22px];
        }

        .conversation-participants {
          .participant-item {
            .participant-name {
              @apply text-[14px] leading-[20px];
            }
          }
        }
      }
    }

    .conversation-content {
      .messages-container {
        @apply px-6;

        .message-bubble {
          .message-content {
            @apply w-full;

            .message-body {
              @apply p-4;
            }
          }
        }
      }

      .message-input-container {
        @apply px-6 py-6;
      }
    }
  }
}
</style>
<script lang="ts" setup>
import {
  CONVERSATION_COMMENT_CHANGED,
  GET_CONVERSATION,
  MARK_CONVERSATION_AS_READ,
  REPLY_TO_PRIVATE_MESSAGE_MUTATION,
} from "../../graphql/conversations";
import RouteName from "../../router/name";
import { IComment } from "../../types/comment.model";
import { ApolloCache, InMemoryCache } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  defineAsyncComponent,
  ref,
  computed,
  onMounted,
  onUnmounted,
  inject,
} from "vue";
import { useHead } from "@/utils/head";
import { useRouter } from "vue-router";
import { useCurrentActorClient } from "../../composition/apollo/actor";
import { AbsintheGraphQLError } from "../../types/errors.model";
import { useI18n } from "vue-i18n";
import { IConversation } from "@/types/conversation";
import { usernameWithDomain, displayName } from "@/types/actor";
import { formatList } from "@/utils/i18n";
import throttle from "lodash/throttle";
import Calendar from "vue-material-design-icons/Calendar.vue";
import { ActorType } from "@/types/enums";
import { format, isToday, isYesterday, parseISO } from "date-fns";
import type { Notifier } from "@/plugins/notifier";

const props = defineProps<{ id: string }>();

const conversationId = computed(() => props.id);

const page = ref(1);
const COMMENTS_PER_PAGE = 10;

const { currentActor } = useCurrentActorClient();
const notifier = inject<Notifier>("notifier");

const {
  result: conversationResult,
  onResult: onConversationResult,
  onError: onConversationError,
  subscribeToMore,
  fetchMore,
} = useQuery<{ conversation: IConversation }>(
  GET_CONVERSATION,
  () => ({
    id: conversationId.value,
    page: page.value,
    limit: COMMENTS_PER_PAGE,
  }),
  () => ({
    enabled: conversationId.value !== undefined,
    fetchPolicy: "no-cache",
    notifyOnNetworkStatusChange: false,
  })
);

subscribeToMore({
  document: CONVERSATION_COMMENT_CHANGED,
  variables: {
    id: conversationId.value,
  },
  updateQuery(
    previousResult: any,
    { subscriptionData }: { subscriptionData: any }
  ) {
    const previousConversation = previousResult.conversation;
    const lastComment =
      subscriptionData.data.conversationCommentChanged.lastComment;

    // Check if this comment is already in our current elements
    const commentExists = previousConversation.comments.elements.some(
      (comment: IComment) => comment.id === lastComment.id
    );

    // Only add the comment if it's not already there
    if (!commentExists) {
      // Update hasMoreComments based on whether we have the latest comment
      // Only set to true if we're missing comments (current elements don't include the latest)
      hasMoreComments.value = !previousConversation.comments.elements.some(
        (comment: IComment) =>
          comment.id === previousConversation.lastComment?.id
      );

      return {
        conversation: {
          ...previousConversation,
          lastComment: lastComment,
          comments: {
            elements: [...previousConversation.comments.elements, lastComment],
            total: previousConversation.comments.total + 1,
          },
        },
      };
    }

    // Comment already exists, just update the lastComment reference but don't change elements
    return {
      ...previousResult,
      conversation: {
        ...previousConversation,
        lastComment: lastComment,
      },
    };
  },
});

const conversation = computed(() => conversationResult.value?.conversation);
const otherParticipants = computed(() => {
  console.log("[ConversationView otherParticipants] Computing participants");
  console.log(
    "[ConversationView otherParticipants] Conversation:",
    conversation.value
  );
  console.log(
    "[ConversationView otherParticipants] All participants:",
    conversation.value?.participants
  );
  console.log(
    "[ConversationView otherParticipants] Current actor ID:",
    currentActor.value?.id
  );

  const filtered =
    conversation.value?.participants.filter((participant) => {
      console.log(
        "[ConversationView otherParticipants] Checking participant:",
        participant
      );
      console.log(
        "[ConversationView otherParticipants] Participant ID:",
        participant.id
      );
      console.log(
        "[ConversationView otherParticipants] Is other participant:",
        participant.id !== currentActor.value?.id
      );
      return participant.id !== currentActor.value?.id;
    }) ?? [];

  console.log(
    "[ConversationView otherParticipants] Filtered result:",
    filtered
  );
  return filtered;
});

const groupParticipants = computed(() => {
  return otherParticipants.value.filter(
    (participant) => participant.type === ActorType.GROUP
  );
});

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { t } = useI18n({ useScope: "global" });

const title = computed(() => {
  console.log("[ConversationView title] Computing title");
  console.log(
    "[ConversationView title] Other participants:",
    otherParticipants.value
  );

  const participantNames = otherParticipants.value.map((participant, index) => {
    console.log(
      `[ConversationView title] Processing participant ${index}:`,
      participant
    );
    const name = displayName(participant);
    console.log(
      `[ConversationView title] Display name for participant ${index}:`,
      name
    );
    return name;
  });

  console.log(
    "[ConversationView title] All participant names:",
    participantNames
  );

  const formattedList = formatList(participantNames);
  console.log("[ConversationView title] Formatted list:", formattedList);

  const result = t("Conversation with {participants}", {
    participants: formattedList,
  });

  console.log("[ConversationView title] Final title:", result);
  return result;
});

const isCurrentActorAuthor = computed(
  () =>
    currentActor.value &&
    conversation.value &&
    currentActor.value.id !== conversation.value?.actor?.id
);

const isOriginCommentAuthorEventOrganizer = computed(
  () =>
    conversation.value?.originComment?.actor &&
    conversation.value?.event &&
    [
      conversation.value?.event?.organizerActor?.id,
      conversation.value?.event?.attributedTo?.id,
    ].includes(conversation.value?.originComment?.actor.id)
);

useHead({
  title: () => title.value,
});

const newComment = ref("");
// const newTitle = ref("");
// const editTitleMode = ref(false);
const hasMoreComments = ref(true);
const error = ref<string | null>(null);

const { mutate: replyToConversationMutation, onDone: onReplyDone } =
  useMutation<
    {
      postPrivateMessage: IConversation;
    },
    {
      text: string;
      actorId: string;
      language?: string;
      conversationId: string;
      mentions?: string[];
      attributedToId?: string;
    }
  >(REPLY_TO_PRIVATE_MESSAGE_MUTATION, () => ({
    update: (store: ApolloCache<InMemoryCache>, { data }) => {
      console.debug("update after reply to", [
        conversationId.value,
        page.value,
      ]);
      console.debug("mutation response data:", data);

      const conversationData = store.readQuery<{
        conversation: IConversation;
      }>({
        query: GET_CONVERSATION,
        variables: {
          id: conversationId.value,
          page: page.value,
          limit: COMMENTS_PER_PAGE,
        },
      });
      console.debug("cached conversation data:", conversationData);

      if (!conversationData || !data?.postPrivateMessage) {
        console.warn("Missing conversation data or reply data");
        return;
      }

      const { conversation: conversationCached } = conversationData;
      const newConversation = data.postPrivateMessage;

      // The lastComment from the mutation is the new comment we just sent
      const newCommentFromMutation = newConversation.lastComment;

      if (!newCommentFromMutation) {
        console.warn("No lastComment in mutation response");
        return;
      }

      console.debug("Adding new comment to cache:", newCommentFromMutation);

      // Check if the comment already exists to avoid duplicates
      const commentExists = conversationCached.comments.elements.some(
        (comment) => comment.id === newCommentFromMutation.id
      );

      if (commentExists) {
        console.debug("Comment already exists in cache, skipping update");
        return;
      }

      store.writeQuery({
        query: GET_CONVERSATION,
        variables: {
          id: conversationId.value,
          page: page.value,
          limit: COMMENTS_PER_PAGE,
        },
        data: {
          conversation: {
            ...conversationCached,
            lastComment: newCommentFromMutation,
            comments: {
              elements: [
                ...conversationCached.comments.elements,
                newCommentFromMutation,
              ],
              total: conversationCached.comments.total + 1,
            },
          },
        },
      });

      console.debug("Cache updated successfully with new comment");
    },
  }));

// Add success notification for replies
onReplyDone(({ data }) => {
  console.debug("Reply completed successfully", data);
  notifier?.success(t("Reply sent successfully"));

  // Clear the input field
  newComment.value = "";

  // If we added a new comment, check if we now have the latest comment
  if (data?.postPrivateMessage?.lastComment) {
    const isLatestComment =
      conversation.value?.lastComment?.id ===
      data.postPrivateMessage.lastComment.id;
    if (isLatestComment) {
      hasMoreComments.value = false;
      console.debug(
        "Updated hasMoreComments to false - we have the latest comment"
      );
    }
  }
});

const reply = () => {
  console.log(
    "[ConversationView reply] Called with newComment:",
    newComment.value
  );
  console.log(
    "[ConversationView reply] Conversation ID:",
    conversation.value?.id
  );
  console.log(
    "[ConversationView reply] Current actor ID:",
    currentActor.value?.id
  );

  if (
    newComment.value === "" ||
    !conversation.value?.id ||
    !currentActor.value?.id
  ) {
    console.log(
      "[ConversationView reply] Early return - missing required data"
    );
    return;
  }

  console.log(
    "[ConversationView reply] Other participants:",
    otherParticipants.value
  );

  // Log mention generation process
  const mentions = otherParticipants.value.map((participant, index) => {
    console.log(
      `[ConversationView reply] Processing participant ${index}:`,
      participant
    );
    const username = usernameWithDomain(participant);
    console.log(
      `[ConversationView reply] Generated username for participant ${index}:`,
      username
    );
    return username;
  });

  console.log("[ConversationView reply] Final mentions array:", mentions);

  replyToConversationMutation({
    conversationId: conversation.value?.id,
    text: newComment.value,
    actorId: currentActor.value?.id,
    mentions: mentions,
    attributedToId:
      conversation.value?.actor?.type === ActorType.GROUP
        ? conversation.value?.actor.id
        : undefined,
  });
};

const loadMoreComments = async (): Promise<void> => {
  if (!hasMoreComments.value) {
    console.debug("No more comments to load, skipping");
    return;
  }

  console.debug("Loading more comments");
  page.value++;

  try {
    const result = await fetchMore({
      // New variables
      variables: () => ({
        id: conversationId.value,
        page: page.value,
        limit: COMMENTS_PER_PAGE,
      }),
    });

    // Update hasMoreComments based on the fetched result
    const currentConversation = result?.data?.conversation;
    if (currentConversation) {
      // Check if we have the last comment loaded
      const hasLatestComment = currentConversation.comments.elements.some(
        (comment: IComment) =>
          comment.id === currentConversation.lastComment?.id
      );

      // Also check if we loaded fewer comments than requested (indicates no more pages)
      const loadedCommentsCount =
        currentConversation.comments.elements.length -
        (conversation.value?.comments.elements.length || 0);
      const isLastPage = loadedCommentsCount < COMMENTS_PER_PAGE;

      hasMoreComments.value = !hasLatestComment && !isLastPage;

      console.debug("Load more comments result:", {
        hasLatestComment,
        isLastPage,
        loadedCommentsCount,
        hasMoreComments: hasMoreComments.value,
      });
    }
  } catch (e) {
    console.error("Error loading more comments:", e);
  }
};

const router = useRouter();

onConversationError((discussionError) =>
  handleErrors(discussionError.graphQLErrors as AbsintheGraphQLError[])
);

onConversationResult(({ data }) => {
  if (data?.conversation && page.value === 1) {
    const conversationData = data.conversation;

    // Initialize hasMoreComments correctly based on initial load
    const hasLatestComment = conversationData.comments.elements.some(
      (comment: IComment) => comment.id === conversationData.lastComment?.id
    );
    const isInitialPageFull =
      conversationData.comments.elements.length >= COMMENTS_PER_PAGE;

    // We have more comments if we don't have the latest comment AND we have a full page
    hasMoreComments.value = !hasLatestComment && isInitialPageFull;

    console.debug("Initial conversation load:", {
      hasLatestComment,
      isInitialPageFull,
      commentsCount: conversationData.comments.elements.length,
      hasMoreComments: hasMoreComments.value,
    });

    // Mark as read if we have a small conversation that fits on first page
    if (
      conversationData.comments.total &&
      conversationData.comments.total < COMMENTS_PER_PAGE
    ) {
      markConversationAsRead();
    }
  }
});

const handleErrors = async (errors: AbsintheGraphQLError[]): Promise<void> => {
  if (errors[0].code === "not_found") {
    await router.push({ name: RouteName.PAGE_NOT_FOUND });
  }
  if (errors[0].code === "unauthorized") {
    error.value = errors[0].message;
  }
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

const { mutate: markConversationAsRead } = useMutation<
  {
    updateConversation: IConversation;
  },
  {
    id: string;
    read: boolean;
  }
>(MARK_CONVERSATION_AS_READ, {
  variables: {
    id: conversationId.value,
    read: true,
  },
});

const loadMoreCommentsThrottled = throttle(async () => {
  if (!hasMoreComments.value) {
    console.debug("Throttled: No more comments to load, skipping");
    // Mark as read if conversation is unread and we have all comments
    if (conversation.value?.unread) {
      console.debug("marking as read");
      markConversationAsRead();
    }
    return;
  }

  console.debug("Throttled: Loading more comments");
  await loadMoreComments();

  // Mark as read after loading if we now have all comments and conversation is unread
  if (!hasMoreComments.value && conversation.value?.unread) {
    console.debug("marking as read after loading");
    markConversationAsRead();
  }
}, 1000);

const handleScroll = (): void => {
  const scrollTop =
    (document.documentElement && document.documentElement.scrollTop) ||
    document.body.scrollTop;
  const scrollHeight =
    (document.documentElement && document.documentElement.scrollHeight) ||
    document.body.scrollHeight;
  const clientHeight =
    document.documentElement.clientHeight || window.innerHeight;
  const scrolledToBottom =
    Math.ceil(scrollTop + clientHeight + 800) >= scrollHeight;
  if (scrolledToBottom) {
    console.debug("Scrolled to bottom");
    loadMoreCommentsThrottled();
  }
};

// Format date for messages
const formatMessageDate = (date: string | Date): string => {
  const dateObj = typeof date === "string" ? parseISO(date) : date;
  if (isToday(dateObj)) {
    return t("Today");
  } else if (isYesterday(dateObj)) {
    return t("Yesterday");
  } else {
    return format(dateObj, "EEEE, d MMMM");
  }
};

// Format time for messages
const formatTime = (date: string | Date): string => {
  const dateObj = typeof date === "string" ? parseISO(date) : date;
  return format(dateObj, "HH:mm");
};

// Editor reference
const editorRef = ref<any>(null);
</script>
