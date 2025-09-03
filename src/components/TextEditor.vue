<template>
  <div v-if="editor !== null">
    <div
      class="editor"
      :class="{ short_mode: isShortMode, comment_mode: isCommentMode }"
      id="tiptab-editor"
      :data-actor-id="currentActor && currentActor.id"
    >
      <bubble-menu
        v-if="editor && isCommentMode"
        class="bubble-menu"
        :editor="editor"
        :tippy-options="{
          duration: 100,
          placement: 'top-start',
          offset: [20, 15],
          arrow: false,
          maxWidth: 'none',
        }"
      >
        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('bold') }"
          @click="editor?.chain().focus().toggleBold().run()"
          type="button"
          :title="t('Bold')"
        >
          <FormatBold :size="20" />
          <span class="visually-hidden">{{ t("Bold") }}</span>
        </button>

        <button
          class="menububble__button"
          :class="{ 'is-active': editor.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="t('Italic')"
        >
          <FormatItalic :size="20" />
          <span class="visually-hidden">{{ t("Italic") }}</span>
        </button>
      </bubble-menu>

      <editor-content
        class="editor__content"
        :class="{ editorErrorStatus, editorIsFocused: focused }"
        :editor="editor"
        v-if="editor"
        ref="editorContentRef"
      />

      <div
        class="input-actions mt-2"
        v-if="isDescriptionMode || isCommentMode"
        :editor="editor"
      >
        <button
          class="action-button"
          :class="{ 'is-active': editor?.isActive('bold') }"
          @click="editor?.chain().focus().toggleBold().run()"
          type="button"
          :title="t('Bold')"
        >
          <o-icon icon="format-bold" />
        </button>

        <button
          class="action-button"
          :class="{ 'is-active': editor?.isActive('italic') }"
          @click="editor?.chain().focus().toggleItalic().run()"
          type="button"
          :title="t('Italic')"
        >
          <o-icon icon="format-italic" />
        </button>

        <button
          class="action-button"
          :class="{ 'is-active': editor?.isActive('underline') }"
          @click="editor?.chain().focus().toggleUnderline().run()"
          type="button"
          :title="t('Underline')"
        >
          <o-icon icon="format-underline" />
        </button>

        <button
          class="action-button"
          @click="showImagePrompt()"
          type="button"
          :title="t('Add picture')"
        >
          <o-icon icon="image" />
        </button>
      </div>

      <p v-if="editorErrorMessage" class="text-sm text-mbz-danger">
        {{ editorErrorMessage }}
      </p>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/vue-3";
import Blockquote from "@tiptap/extension-blockquote";
import BulletList from "@tiptap/extension-bullet-list";
import Heading, { Level } from "@tiptap/extension-heading";
import Document from "@tiptap/extension-document";
import Paragraph from "@tiptap/extension-paragraph";
import Bold from "@tiptap/extension-bold";
import Italic from "@tiptap/extension-italic";
import Strike from "@tiptap/extension-strike";
import Text from "@tiptap/extension-text";
import Dropcursor from "@tiptap/extension-dropcursor";
import Gapcursor from "@tiptap/extension-gapcursor";
import History from "@tiptap/extension-history";
import { IActor, IPerson, usernameWithDomain } from "../types/actor";
import CustomImage from "./Editor/Image";
import RichEditorKeyboardSubmit from "./Editor/RichEditorKeyboardSubmit";
import { UPLOAD_MEDIA } from "../graphql/upload";
import { listenFileUpload } from "../utils/upload";
import Mention from "@tiptap/extension-mention";
import MentionOptions from "./Editor/Mention";
import OrderedList from "@tiptap/extension-ordered-list";
import ListItem from "@tiptap/extension-list-item";
import Underline from "@tiptap/extension-underline";
import Link from "@tiptap/extension-link";
import { AutoDir } from "./Editor/Autodir";
// import sanitizeHtml from "sanitize-html";
import { computed, inject, onBeforeUnmount, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";
import { Notifier } from "@/plugins/notifier";

import Placeholder from "@tiptap/extension-placeholder";
import { useFocusWithin } from "@vueuse/core";

const props = withDefaults(
  defineProps<{
    modelValue: string;
    mode?: "description" | "comment" | "basic";
    maxSize?: number;
    ariaLabel?: string;
    currentActor: IPerson;
    placeholder?: string;
    headingLevel?: Level[];
    required?: boolean;
  }>(),
  {
    mode: "description",
    maxSize: 100_000_000,
    headingLevel: () => [3, 4, 5],
    required: false,
  }
);

const emit = defineEmits(["update:modelValue", "submit"]);

const isDescriptionMode = computed((): boolean => {
  return props.mode === "description" || isBasicMode.value;
});

const isCommentMode = computed((): boolean => {
  return props.mode === "comment";
});

const isShortMode = computed((): boolean => {
  return isBasicMode.value;
});

const isBasicMode = computed((): boolean => {
  return props.mode === "basic";
});

const transformPastedHTML = (html: string): string => {
  // When using comment mode, limit to acceptable tags
  if (isCommentMode.value) {
    // return sanitizeHtml(html, {
    //   allowedTags: ["b", "i", "em", "strong", "a"],
    //   allowedAttributes: {
    //     a: ["href", "rel", "target"],
    //   },
    // });
    return html;
  }
  return html;
};

const ariaLabel = computed(() => props.ariaLabel);
const headingLevel = computed(() => props.headingLevel);
const placeholder = computed(() => props.placeholder);
const value = computed(() => props.modelValue);

const { t } = useI18n({ useScope: "global" });

const editor = useEditor({
  editorProps: {
    attributes: {
      "aria-multiline": isShortMode.value.toString(),
      "aria-label": ariaLabel.value ?? "",
      role: "textbox",
      class: "bg-white !max-w-full min-h-[52px] placeholder:text-md",
    },
    transformPastedHTML: transformPastedHTML,
  },
  extensions: [
    Blockquote,
    BulletList,
    Heading.configure({
      levels: headingLevel.value,
    }),
    Document,
    Paragraph,
    Text,
    OrderedList,
    ListItem,
    Mention.configure(MentionOptions),
    CustomImage,
    AutoDir,
    Underline,
    Bold,
    Italic,
    Strike,
    Dropcursor,
    Gapcursor,
    History,
    Link.configure({
      HTMLAttributes: { target: "_blank", rel: "noopener noreferrer ugc" },
    }),
    RichEditorKeyboardSubmit.configure({
      submit: () => emit("submit"),
    }),
    Placeholder.configure({
      placeholder: placeholder.value ?? t("Write something"),
    }),
  ],
  injectCSS: false,
  content: value.value,
  onUpdate: () => {
    emit("update:modelValue", editor.value?.getHTML());
  },
  onBlur: () => {
    checkEditorEmpty();
  },
  onFocus: () => {
    editorErrorStatus.value = false;
    editorErrorMessage.value = "";
  },
});

const editorContentRef = ref(null);
const { focused } = useFocusWithin(editorContentRef);

watch(value, (val: string) => {
  if (!editor.value) return;
  if (val !== editor.value.getHTML()) {
    editor.value.commands.setContent(val, false);
  }
});

const {
  mutate: uploadMediaMutation,
  onDone: uploadMediaDone,
  onError: uploadMediaError,
} = useMutation(UPLOAD_MEDIA);

/**
 * Show a file prompt, upload picture and insert it into editor
 */
const showImagePrompt = async (): Promise<void> => {
  const image = await listenFileUpload();
  uploadMediaMutation({
    file: image,
    name: image.name,
  });
};

uploadMediaDone(({ data }) => {
  if (data.uploadMedia && data.uploadMedia.url && editor.value) {
    editor.value
      .chain()
      .focus()
      .setImage({
        src: data.uploadMedia.url,
        alt: "",
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        "data-media-id": data.uploadMedia.id,
      })
      .run();
  }
});

const notifier = inject<Notifier>("notifier");

uploadMediaError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

/**
 * We use this to programatically insert an actor mention when creating a reply to comment
 */
const replyToComment = (actor: IActor): void => {
  if (!editor.value) return;
  const username = usernameWithDomain(actor);
  // Handle cases where name might be "undefined" string or empty
  const displayName =
    actor &&
    actor.name &&
    actor.name !== "undefined" &&
    actor.name.trim() !== ""
      ? actor.name
      : username;

  // Only insert if we have valid values
  if (
    username &&
    displayName &&
    displayName !== "undefined" &&
    displayName.trim() !== "" &&
    username !== "undefined" &&
    username.trim() !== ""
  ) {
    editor.value
      .chain()
      .focus()
      .insertContent({
        type: "mention",
        attrs: {
          id: username,
          label: displayName,
        },
      })
      .insertContent(" ")
      .run();
  }
};

const focus = (): void => {
  editor.value?.chain().focus("end");
};

defineExpose({ replyToComment, focus, editor });

onBeforeUnmount(() => {
  editor.value?.destroy();
});

const editorErrorStatus = ref(false);
const editorErrorMessage = ref("");

const isEmpty = computed(
  () => props.required === true && editor.value?.isEmpty === true
);

const checkEditorEmpty = () => {
  editorErrorStatus.value = isEmpty.value;
  editorErrorMessage.value = isEmpty.value ? t("You need to enter a text") : "";
};
</script>
<style lang="scss">
@use "@/styles/_mixins" as *;
@import "./Editor/style.scss";

.input-actions {
  display: flex;
  align-items: center;
  gap: 0.375rem; /* gap-1.5 */

  .action-button {
    width: 60px;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: transparent;
    border: 0;
    transition: background-color 0.2s;
    cursor: pointer;

    &:hover {
      background-color: #f9fafb; /* hover:bg-gray-50 */
    }

    &.is-active {
      background-color: #e5e7eb; /* bg-gray-200 */
    }

    .o-icon,
    :deep(.o-icon) {
      width: 2rem !important; /* size-8 */
      height: 2rem !important; /* size-8 */
      color: #155eef !important; /* text-[#155eef] */
    }
  }
}

.editor {
  position: relative;
  overflow: visible;

  .ProseMirror {
    transition: min-height 0.2s ease-out;
    resize: none;
  }

  &.comment_mode {
    .ProseMirror {
      position: relative;
      z-index: 1;
    }
  }

  p.is-empty:first-child::before {
    content: attr(data-empty-text);
    float: left;
    color: #aaa;
    pointer-events: none;
    height: 0;
    font-style: italic;
  }

  .editor__content div.ProseMirror {
    min-height: 10rem;
    max-height: 60vh;
    overflow-y: auto;
  }

  &.short_mode {
    div.ProseMirror {
      min-height: 5rem;
      max-height: 40vh;
      overflow-y: auto;
    }
  }

  &.comment_mode {
    div.ProseMirror {
      min-height: 62px;
      max-height: 132px;
      overflow-y: auto;
    }
  }

  &__content {
    div.ProseMirror {
      min-height: 2.5rem;
      border-radius: 0;
      padding: 18px;
      line-height: 1.5;
      word-wrap: break-word;
      font-family: "Mulish", sans-serif;
    }

    h1 {
      font-size: 2em;
    }

    h2 {
      font-size: 1.5em;
    }

    h3 {
      font-size: 1.25em;
    }

    // ul,
    // ol {
    //   @include padding-left(1rem);
    // }

    ul {
      list-style-type: disc;
    }

    li > p,
    li > ol,
    li > ul {
      margin: 0;
    }

    blockquote {
      // @include padding-left(0.8rem);
      font-style: italic;

      p {
        margin: 0;
      }
    }

    img {
      max-width: 100%;
      height: auto;
      border-radius: 6px;
      margin: 8px 0;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      display: block;
    }
  }
}

.bubble-menu {
  display: flex;
  background-color: #1f2937;
  padding: 0.5rem;
  border-radius: 0.75rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  border: 1px solid #374151;
  gap: 0.25rem;
  z-index: 1000;

  button,
  .menububble__button {
    border: none;
    background: none;
    color: #f9fafb;
    font-size: 0.875rem;
    font-weight: 500;
    padding: 0.5rem 0.75rem;
    border-radius: 0.5rem;
    opacity: 0.8;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 40px;
    height: 40px;

    &:hover {
      opacity: 1;
      background-color: #374151;
    }

    &.is-active {
      opacity: 1;
      background-color: #3b82f6;
      color: #ffffff;
    }
  }
}

.suggestion-list {
  padding: 0.2rem;
  font-size: 0.8rem;
  font-weight: bold;
  &__no-results {
    padding: 0.2rem 0.5rem;
  }
  &__item {
    border-radius: 5px;
    padding: 0.2rem 0.5rem;
    margin-bottom: 0.2rem;
    cursor: pointer;
    &:last-child {
      margin-bottom: 0;
    }
    &.is-empty {
      opacity: 0.5;
    }
  }

  .media + .media {
    margin-top: 0;
    padding-top: 0;
  }
}
.tippy-box[data-theme~="dark"] {
  padding: 0;
  font-size: 1rem;
  text-align: inherit;
  border-radius: 12px;
  background: transparent;
}

/* Ensure bubble menu is properly positioned within editor bounds */
.editor.comment_mode .bubble-menu {
  position: relative;
  max-width: calc(100% - 3rem);
  margin-left: 1rem;
}

/* Bubble menu positioning improvements */
.tippy-box {
  max-width: none !important;
  transform: translateX(20px) !important;
}

.tippy-content {
  padding: 0 !important;
}

/* Better positioning for comment mode */
.editor.comment_mode {
  .ProseMirror {
    padding-left: 24px;
    padding-right: 16px;
  }
}

/* Ensure consistent padding for all editor modes */
.editor {
  .ProseMirror {
    padding-left: 20px !important;
  }
}

/* Ensure bubble menu doesn't overlap with borders */
[data-tippy-root] {
  z-index: 1000;
}

.tippy-box[data-placement^="top"] {
  margin-left: 20px;
}

.visually-hidden {
  display: none;
}

.ProseMirror p.is-editor-empty:first-child::before {
  content: attr(data-placeholder);
  float: left;
  color: #adb5bd;
  pointer-events: none;
  height: 0;
}

/* Ensure action buttons have proper styling */
.input-actions .action-button .o-icon {
  color: #155eef !important;
  width: 2rem !important;
  height: 2rem !important;
}
</style>
<style>
.mention[data-id] {
  @apply inline-block border border-zinc-600 dark:border-zinc-300 rounded py-0.5 px-1;
}

.editor__content > div {
  @apply border rounded border-[#6b7280];
}

.editorIsFocused > div {
  @apply ring-2 ring-[#2563eb] outline-2 outline outline-offset-2 outline-transparent;
}

.editorErrorStatus {
  @apply border-red-500;
}
.editor__content p.is-editor-empty:first-child::before {
  @apply text-slate-300;
}
</style>
