<template>
  <section class="flex flex-col items-center justify-start w-full">
    <div
      class="bg-white flex flex-col gap-4 items-center justify-start pb-4 pt-8 px-16 w-full text-center"
    >
      <h1
        class="text-[36px] font-bold leading-[48px] text-[#1c1b1f] max-w-[720px]"
      >
        {{ t("Forgot your password?") }}
      </h1>
      <p
        class="text-[17px] font-medium leading-[26px] text-[#1c1b1f] max-w-[592px]"
      >
        {{
          t(
            "Enter your email address below, and we'll email you instructions on how to change your password."
          )
        }}
      </p>
    </div>
    <div
      class="bg-white flex flex-col gap-8 items-center justify-start pb-16 pt-4 px-16 w-full"
    >
      <o-notification
        title="Error"
        variant="danger"
        v-for="error in errors"
        :key="error"
        @close="removeError(error)"
        class="max-w-[592px] w-full"
      >
        {{ error }}
      </o-notification>
      <form
        @submit="sendResetPasswordTokenAction"
        v-if="!validationSent"
        class="flex flex-col gap-8 w-full max-w-[592px]"
      >
        <div class="flex flex-col gap-1.5 w-full">
          <label class="block text-xs font-bold text-[#1c1b1f]">
            {{ t("Email address") }}
          </label>
          <o-input
            aria-required="true"
            required
            type="email"
            v-model="emailValue"
            expanded
            class="[&_.o-input__wrapper]:border-[#cac9cb] [&_.o-input__wrapper]:p-[18px]"
          />
        </div>
        <div class="flex gap-4">
          <o-button
            variant="primary"
            native-type="submit"
            class="px-8 py-[18px] bg-[#155eef] text-white font-bold text-[17px] hover:bg-[#0d4fd7] transition-colors"
          >
            {{ t("Submit") }}
          </o-button>
          <o-button
            tag="router-link"
            :to="{ name: RouteName.LOGIN }"
            class="px-8 py-[18px] !bg-white !text-[#155eef] !font-bold !text-[17px] hover:!bg-gray-50 transition-colors"
            style="border: 1px solid #155eef; box-shadow: none"
          >
            {{ t("Cancel") }}
          </o-button>
        </div>
      </form>
      <div v-else class="flex flex-col gap-4 w-full max-w-[592px]">
        <o-notification variant="success" :closable="false" title="Success">
          {{
            t("We just sent an email to {email}", {
              email: emailValue,
            })
          }}
        </o-notification>
        <o-notification variant="info">
          {{
            t("Please check your spam folder if you didn't receive the email.")
          }}
        </o-notification>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { SEND_RESET_PASSWORD } from "../../graphql/auth";
import RouteName from "../../router/name";
import { computed, ref } from "vue";
import { useMutation } from "@vue/apollo-composable";
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";

const { t, locale } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Reset password")),
});

const props = withDefaults(
  defineProps<{
    email?: string;
  }>(),
  { email: "" }
);

const defaultEmail = computed(() => props.email);
const emailValue = ref<string>(defaultEmail.value);

const validationSent = ref(false);

const errors = ref<string[]>([]);

const removeError = (message: string): void => {
  errors.value.splice(errors.value.indexOf(message));
};

const {
  mutate: sendResetPasswordMutation,
  onDone: sendResetPasswordDone,
  onError: sendResetPasswordError,
} = useMutation(SEND_RESET_PASSWORD);

sendResetPasswordDone(() => {
  validationSent.value = true;
});
sendResetPasswordError((err) => {
  console.error(err);
  if (err.graphQLErrors) {
    err.graphQLErrors.forEach(({ message }: { message: string }) => {
      if (errors.value.indexOf(message) < 0) {
        errors.value.push(message);
      }
    });
  }
});

const sendResetPasswordTokenAction = async (e: Event): Promise<void> => {
  e.preventDefault();

  sendResetPasswordMutation({
    email: emailValue.value,
    locale: locale.value,
  });
};
</script>
