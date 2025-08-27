<template>
  <div class="conversation-view" v-if="conversation">
    <div class="conversation-header">
      <router-link
        :to="{ name: RouteName.CONVERSATION_LIST }"
        class="back-link"
      >
        <o-icon icon="chevron-left" />
      </router-link>
      <h1 class="conversation-title">{{ t("Conversation") }}</h1>
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
            <div class="input-actions">
              <button
                type="button"
                class="action-button"
                :title="t('Bold')"
                @click="toggleBold"
              >
                <o-icon icon="format-bold" />
              </button>
              <button
                type="button"
                class="action-button"
                :title="t('Italic')"
                @click="toggleItalic"
              >
                <o-icon icon="format-italic" />
              </button>
              <button
                type="button"
                class="action-button"
                :title="t('Underline')"
                @click="toggleUnderline"
              >
                <o-icon icon="format-underline" />
              </button>
              <button
                type="button"
                class="action-button"
                :title="t('Add picture')"
                @click="addImage"
              >
                <o-icon icon="image" />
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
    @apply bg-white border-b border-[#cac9cb] px-4 md:px-16 py-4 md:py-8 flex items-center gap-4;

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

      .conversation-title {
        @apply text-[20px] leading-[28px];
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
import { UPLOAD_MEDIA } from "../../graphql/upload";
import { listenFileUpload } from "../../utils/upload";
import { Notifier } from "@/plugins/notifier";
import { usernameWithDomain, displayName } from "@/types/actor";
import { formatList } from "@/utils/i18n";
import throttle from "lodash/throttle";
import Calendar from "vue-material-design-icons/Calendar.vue";
import { ActorType } from "@/types/enums";
import { format, isToday, isYesterday, parseISO } from "date-fns";

const props = defineProps<{ id: string }>();

const conversationId = computed(() => props.id);

const page = ref(1);
const COMMENTS_PER_PAGE = 10;

const { currentActor } = useCurrentActorClient();

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
    hasMoreComments.value = !previousConversation.comments.elements.some(
      (comment: IComment) => comment.id === lastComment.id
    );
    if (hasMoreComments.value) {
      return {
        conversation: {
          ...previousConversation,
          lastComment: lastComment,
          comments: {
            elements: [
              ...previousConversation.comments.elements.filter(
                ({ id }: { id: string }) => id !== lastComment.id
              ),
              lastComment,
            ],
            total: previousConversation.comments.total + 1,
          },
        },
      };
    }

    return previousConversation;
  },
});

const conversation = computed(() => conversationResult.value?.conversation);
const otherParticipants = computed(
  () =>
    conversation.value?.participants.filter(
      (participant) => participant.id !== currentActor.value?.id
    ) ?? []
);

const groupParticipants = computed(() => {
  return otherParticipants.value.filter(
    (participant) => participant.type === ActorType.GROUP
  );
});

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { t } = useI18n({ useScope: "global" });

const title = computed(() =>
  t("Conversation with {participants}", {
    participants: formatList(
      otherParticipants.value.map((participant) => displayName(participant))
    ),
  })
);

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

const { mutate: replyToConversationMutation } = useMutation<
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
    console.debug("update after reply to", [conversationId.value, page.value]);
    const conversationData = store.readQuery<{
      conversation: IConversation;
    }>({
      query: GET_CONVERSATION,
      variables: {
        id: conversationId.value,
      },
    });
    console.debug("update after reply to", conversationData);
    if (!conversationData) return;
    const { conversation: conversationCached } = conversationData;

    console.debug("got cache", conversationCached);

    store.writeQuery({
      query: GET_CONVERSATION,
      variables: {
        id: conversationId.value,
      },
      data: {
        conversation: {
          ...conversationCached,
          lastComment: data?.postPrivateMessage.lastComment,
          comments: {
            elements: [
              ...conversationCached.comments.elements,
              data?.postPrivateMessage.lastComment,
            ],
            total: conversationCached.comments.total + 1,
          },
        },
      },
    });
  },
}));

const reply = () => {
  if (
    newComment.value === "" ||
    !conversation.value?.id ||
    !currentActor.value?.id
  )
    return;

  replyToConversationMutation({
    conversationId: conversation.value?.id,
    text: newComment.value,
    actorId: currentActor.value?.id,
    mentions: otherParticipants.value.map((participant) =>
      usernameWithDomain(participant)
    ),
    attributedToId:
      conversation.value?.actor?.type === ActorType.GROUP
        ? conversation.value?.actor.id
        : undefined,
  });

  newComment.value = "";
};

const loadMoreComments = async (): Promise<void> => {
  if (!hasMoreComments.value) return;
  console.debug("Loading more comments");
  page.value++;
  try {
    await fetchMore({
      // New variables
      variables: () => ({
        id: conversationId.value,
        page: page.value,
        limit: COMMENTS_PER_PAGE,
      }),
    });
    hasMoreComments.value = !conversation.value?.comments.elements
      .map(({ id }) => id)
      .includes(conversation.value?.lastComment?.id);
  } catch (e) {
    console.error(e);
  }
};

// const dialog = inject<Dialog>("dialog");

// const openDeleteDiscussionConfirmation = (): void => {
//   dialog?.confirm({
//     variant: "danger",
//     title: t("Delete this conversation"),
//     message: t("Are you sure you want to delete this entire conversation?"),
//     confirmText: t("Delete conversation"),
//     cancelText: t("Cancel"),
//     onConfirm: () =>
//       deleteConversation({
//         discussionId: conversation.value?.id,
//       }),
//   });
// };

const router = useRouter();

// const { mutate: deleteConversation, onDone: deleteConversationDone } =
//   useMutation(DELETE_DISCUSSION);

// deleteConversationDone(() => {
//   if (conversation.value?.actor) {
//     router.push({
//       name: RouteName.DISCUSSION_LIST,
//       params: {
//         preferredUsername: usernameWithDomain(conversation.value.actor),
//       },
//     });
//   }
// });

onConversationError((discussionError) =>
  handleErrors(discussionError.graphQLErrors as AbsintheGraphQLError[])
);

onConversationResult(({ data }) => {
  if (
    page.value === 1 &&
    data?.conversation?.comments?.total &&
    data?.conversation?.comments?.total < COMMENTS_PER_PAGE
  ) {
    markConversationAsRead();
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
  console.log("Throttled");
  await loadMoreComments();
  if (!hasMoreComments.value && conversation.value?.unread) {
    console.debug("marking as read");
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

// Text formatting functions
const toggleBold = () => {
  editorRef.value?.editor?.chain().focus().toggleBold().run();
};

const toggleItalic = () => {
  editorRef.value?.editor?.chain().focus().toggleItalic().run();
};

const toggleUnderline = () => {
  editorRef.value?.editor?.chain().focus().toggleUnderline().run();
};

const notifier = inject<Notifier>("notifier");

const {
  mutate: uploadMediaMutation,
  onDone: uploadMediaDone,
  onError: uploadMediaError,
} = useMutation(UPLOAD_MEDIA);

const addImage = async () => {
  try {
    const image = await listenFileUpload();
    uploadMediaMutation({
      file: image,
      name: image.name,
    });
  } catch (uploadError) {
    console.error("Error selecting image:", uploadError);
  }
};

uploadMediaDone(({ data }) => {
  if (data.uploadMedia && data.uploadMedia.url && editorRef.value?.editor) {
    editorRef.value?.editor
      .chain()
      .focus()
      .setImage({
        src: data.uploadMedia.url,
        alt: "",
        "data-media-id": data.uploadMedia.id,
      })
      .run();
  }
});

uploadMediaError((uploadError) => {
  console.error(uploadError);
  if (uploadError.graphQLErrors && uploadError.graphQLErrors.length > 0) {
    notifier?.error(uploadError.graphQLErrors[0].message);
  }
});
</script>
