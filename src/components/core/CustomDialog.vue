<template>
  <div
    class="bg-white p-6 w-full"
    :class="size === 'wide' ? 'max-w-2xl' : 'max-w-lg'"
  >
    <div class="flex justify-between items-start mb-4">
      <h2 class="text-xl font-bold text-gray-900" v-if="title">{{ title }}</h2>
      <button
        @click="cancel('close')"
        class="text-gray-400 hover:text-gray-600"
        aria-label="Close"
      >
        <svg
          class="w-6 h-6"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </div>

    <section class="mb-6">
      <div class="text-gray-700">
        <template v-if="$slots.default">
          <slot />
        </template>
        <template v-else>
          <div v-html="message" class="text-sm leading-relaxed" />
        </template>

        <o-field v-if="hasInput" class="mt-4">
          <o-input
            v-model="prompt"
            expanded
            class="input w-full px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            ref="input"
            v-bind="inputAttrs"
            @keydown.enter="confirm"
            autofocus
          />
        </o-field>
      </div>
    </section>

    <footer v-if="canCancel" class="flex justify-between">
      <o-button
        ref="cancelButton"
        @click="cancel('button')"
        class="px-6 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 font-medium"
        >{{ cancelText ?? t("Cancel") }}</o-button
      >
      <o-button
        :variant="variant"
        ref="confirmButton"
        @click="confirm"
        :class="[
          'px-6 py-2 font-medium text-white',
          variant === 'danger'
            ? 'bg-red-600 hover:bg-red-700'
            : 'bg-blue-600 hover:bg-blue-700',
        ]"
        >{{ confirmText ?? t("Confirm") }}</o-button
      >
    </footer>
  </div>
</template>

<script lang="ts" setup>
import { useFocus } from "@vueuse/core";
import { computed, nextTick, ref } from "vue";
import { useI18n } from "vue-i18n";

const props = withDefaults(
  defineProps<{
    title: string;
    message: string | string[];
    icon?: string;
    hasIcon?: boolean;
    variant?: string;
    size?: string;
    canCancel?: boolean;
    confirmText?: string;
    cancelText?: string;
    onConfirm: (prompt?: string) => any;
    onCancel?: (source: string) => any;
    ariaLabel?: string;
    ariaModal?: boolean;
    ariaRole?: string;
    hasInput?: boolean;
    inputAttrs?: Record<string, any>;
  }>(),
  {
    variant: "primary",
    canCancel: true,
    hasInput: false,
    inputAttrs: () => ({}),
  }
);

const emit = defineEmits(["confirm", "cancel", "close"]);

const { t } = useI18n({ useScope: "global" });

const hasInput = computed(() => props.hasInput);
const onConfirm = computed(() => props.onConfirm);
const onCancel = computed(() => props.onCancel);
const inputAttrs = computed(() => props.inputAttrs);

// const modalOpened = ref(false);

const prompt = ref<string>(hasInput.value ? inputAttrs.value.value ?? "" : "");
const input = ref();

// https://github.com/oruga-ui/oruga/issues/339
const promptInputComp = computed(() => input.value?.$refs.input);
if (hasInput.value) {
  useFocus(promptInputComp, { initialValue: true });
}

// const dialogClass = computed(() => {
//   return [props.size];
// });
/**
 * Icon name (MDI) based on the type.
 */

/**
 * If it's a prompt Dialog, validate the input.
 * Call the onConfirm prop (function) and close the Dialog.
 */
const confirm = () => {
  console.debug("dialog confirmed", input.value?.$el);
  if (input.value !== undefined) {
    const inputElement = input.value.$el.querySelector("input");
    if (!inputElement.checkValidity()) {
      nextTick(() => inputElement.select());
      return;
    }
  }
  onConfirm.value(prompt.value);
  close();
};

/**
 * Close the Dialog.
 */
const close = () => {
  emit("close");
};

/**
 * Close the Modal if canCancel and call the onCancel prop (function).
 */
const cancel = (source: string) => {
  emit("cancel", source);
  if (onCancel.value) {
    onCancel.value(source);
  }
  close();
};
</script>
