<template>
  <section
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
  >
    <h1 class="text-[36px] font-bold leading-[48px] mb-4">
      {{ t("Create a new group") }}
    </h1>

    <o-notification
      variant="danger"
      v-for="(value, index) in errors"
      :key="index"
    >
      {{ value }}
    </o-notification>

    <form @submit.prevent="createGroup" class="space-y-8 max-w-[592px]">
      <div class="space-y-1.5">
        <label
          for="group-display-name"
          class="block text-xs font-bold text-[#1c1b1f]"
        >
          {{ t("Group display name") }}
        </label>
        <o-input
          aria-required="true"
          required
          expanded
          v-model="group.name"
          id="group-display-name"
          class="w-full [&_.o-input__wrapper]:border-[#cac9cb] [&_.o-input__wrapper]:p-[18px]"
        />
      </div>

      <div class="space-y-2">
        <div class="space-y-1.5">
          <label
            class="block text-xs font-bold text-[#1c1b1f]"
            for="group-preferred-username"
            >{{ t("Federated Group Name") }}</label
          >
          <div class="flex">
            <o-field
              :message="preferredUsernameErrors[0]"
              :type="preferredUsernameErrors[1]"
            >
              <o-input
                ref="preferredUsernameInput"
                aria-required="true"
                required
                expanded
                v-model="group.preferredUsername"
                pattern="[a-z0-9_]+"
                id="group-preferred-username"
                :useHtml5Validation="true"
                :validation-message="
                  group.preferredUsername
                    ? t(
                        'Only alphanumeric lowercased characters and underscores are supported.'
                      )
                    : null
                "
              />
              <div
                class="flex items-center px-[18px] py-[18px] bg-white border border-l-0 border-[#cac9cb] text-[#37363a] text-[17px]"
              >
                @{{ host }}
              </div>
            </o-field>
          </div>
        </div>
        <p
          class="text-[15px] text-[#37363a] leading-[23px]"
          v-if="currentActor"
        >
          <i18n-t
            keypath="This is like your federated username ({username}) for groups. It will allow the group to be found on the federation, and is guaranteed to be unique."
          >
            <template #username>
              <span>
                {{ usernameWithDomain(currentActor, true) }}
              </span>
            </template>
          </i18n-t>
        </p>
      </div>

      <div class="space-y-1.5">
        <label
          for="group-summary"
          class="block text-xs font-bold text-[#1c1b1f]"
        >
          {{ t("Description") }}
        </label>
        <o-field :message="summaryErrors[0]" :type="summaryErrors[1]">
          <editor
            v-if="currentActor"
            id="group-summary"
            mode="basic"
            v-model="group.summary"
            :maxSize="500"
            :aria-label="$t('Group description body')"
            :current-actor="currentActor"
            class="w-full [&_.editor-wrapper]:min-h-[128px] [&_.editor-wrapper]:border-[#cac9cb] [&_.editor-wrapper]:p-[18px]"
          />
        </o-field>
      </div>

      <div class="space-y-1.5">
        <label
          for="group-marketing-url"
          class="block text-xs font-bold text-[#1c1b1f]"
        >
          {{ t("Marketing URL") }}
        </label>
        <o-input
          expanded
          v-model="group.customUrl"
          id="group-marketing-url"
          type="url"
          :placeholder="t('https://example.com')"
          class="w-full [&_.o-input__wrapper]:border-[#cac9cb] [&_.o-input__wrapper]:p-[18px]"
        />
        <p class="text-[13px] text-[#666666] leading-[20px]">
          {{ t("Optional: Add a marketing URL for your group (e.g., your website or social media)") }}
        </p>
      </div>

      <div class="space-y-1.5">
        <label class="block text-xs font-bold text-[#1c1b1f]">
          {{ t("Group address") }}
        </label>
        <full-address-auto-complete
          v-model="group.physicalAddress"
          class="[&_input]:p-[18px] [&_.o-input__wrapper]:border-[#cac9cb]"
        />
      </div>

      <div class="space-y-1.5">
        <label class="block text-xs font-bold text-[#1c1b1f]">
          {{ t("Avatar") }}
        </label>
        <picture-upload
          :textFallback="t('Avatar')"
          v-model="avatarFile"
          :maxSize="avatarMaxSize"
          class="[&_.media-upload]:border-[#cac9cb] [&_.media-upload]:p-5"
        />
      </div>

      <div class="space-y-1.5">
        <label class="block text-xs font-bold text-[#1c1b1f]">
          {{ t("Banner") }}
        </label>
        <picture-upload
          :textFallback="t('Banner')"
          v-model="bannerFile"
          :maxSize="bannerMaxSize"
          class="[&_.media-upload]:border-[#cac9cb] [&_.media-upload]:p-5"
        />
      </div>

      <div class="space-y-1.5">
        <label class="block text-xs font-bold text-[#1c1b1f]">
          {{ t("Iframe Banner Code") }}
        </label>
        <div class="space-y-3">
          <p class="text-[15px] text-[#37363a] leading-[23px]">
            {{
              t(
                "Copy this code to embed the Pragmatic Meet banner in any website:"
              )
            }}
          </p>

          <!-- Light Theme Option -->
          <div class="space-y-2">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-[#1c1b1f]"
                >☀️ {{ t("Light Theme") }}</span
              >
              <span class="text-xs text-[#37363a]"
                >({{ t("for light backgrounds") }})</span
              >
            </div>
            <div class="relative">
              <textarea
                readonly
                :value="iframeCodeLight"
                class="w-full p-[18px] border border-[#cac9cb] rounded bg-gray-50 text-sm font-mono resize-none"
                rows="6"
              ></textarea>
              <div class="absolute top-2 right-2">
                <o-tooltip
                  v-if="canShowCopyButton"
                  :label="t('Code copied to clipboard')"
                  :active="showCopiedTooltipLight"
                  variant="success"
                  position="left"
                />
                <o-button
                  variant="primary"
                  icon-right="content-paste"
                  native-type="button"
                  @click="copyIframeCodeLight"
                  @keyup.enter="copyIframeCodeLight"
                  size="small"
                />
              </div>
            </div>
          </div>

          <!-- Dark Theme Option -->
          <div class="space-y-2">
            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-[#1c1b1f]"
                >🌙 {{ t("Dark Theme") }}</span
              >
              <span class="text-xs text-[#37363a]"
                >({{ t("for dark backgrounds") }})</span
              >
            </div>
            <div class="relative">
              <textarea
                readonly
                :value="iframeCodeDark"
                class="w-full p-[18px] border border-[#cac9cb] rounded bg-gray-50 text-sm font-mono resize-none"
                rows="6"
              ></textarea>
              <div class="absolute top-2 right-2">
                <o-tooltip
                  v-if="canShowCopyButton"
                  :label="t('Code copied to clipboard')"
                  :active="showCopiedTooltipDark"
                  variant="success"
                  position="left"
                />
                <o-button
                  variant="primary"
                  icon-right="content-paste"
                  native-type="button"
                  @click="copyIframeCodeDark"
                  @keyup.enter="copyIframeCodeDark"
                  size="small"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <fieldset class="space-y-4">
        <legend class="text-xl font-bold text-[#1c1b1f] leading-[30px]">
          {{ t("Group visibility") }}
        </legend>
        <div class="space-y-2">
          <o-radio
            v-model="group.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.PUBLIC"
            class="flex items-start gap-3 [&_.o-radio__check]:rounded-full [&_.o-radio__check]:border-[#cac9cb]"
          >
            <div>
              <span class="font-bold text-[17px] leading-[26px]">{{
                $t("Visible everywhere on the web")
              }}</span>
              <p class="text-[15px] text-[#1c1b1f] leading-[23px] mt-1 pl-8">
                {{
                  $t(
                    "The group will be publicly listed in search results and may be suggested in the explore section. Only public informations will be shown on it's page."
                  )
                }}
              </p>
            </div>
          </o-radio>
          <o-radio
            v-model="group.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.UNLISTED"
            class="flex items-start gap-3 [&_.o-radio__check]:rounded-full [&_.o-radio__check]:border-[#cac9cb]"
          >
            <div>
              <span class="font-bold text-[17px] leading-[26px]">{{
                $t("Only accessible through link")
              }}</span>
              <p class="text-[15px] text-[#1c1b1f] leading-[23px] mt-1 pl-8">
                {{
                  $t(
                    "You'll need to transmit the group URL so people may access the group's profile. The group won't be findable in Mobilizon's search or regular search engines."
                  )
                }}
              </p>
            </div>
          </o-radio>
        </div>
      </fieldset>
      <div class="h-8 border-t border-[#e0e0e0]"></div>
      <fieldset class="space-y-4">
        <legend>
          <span class="text-xl font-bold text-[#1c1b1f] block">{{
            t("New members")
          }}</span>
          <span class="text-[17px] text-[#1c1b1f] leading-[26px] block mt-2">
            {{
              t(
                "Members will also access private sections like discussions, resources and restricted posts."
              )
            }}
          </span>
        </legend>
        <div class="space-y-2">
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.OPEN"
            class="flex items-start gap-3 [&_.o-radio__check]:rounded-full [&_.o-radio__check]:border-[#cac9cb]"
          >
            <div>
              <span class="font-bold text-[17px] leading-[26px]">{{
                $t("Anyone can join freely")
              }}</span>
              <p class="text-[15px] text-[#1c1b1f] leading-[23px] mt-1 pl-8">
                {{
                  $t(
                    "Anyone wanting to be a member from your group will be able to from your group page."
                  )
                }}
              </p>
            </div>
          </o-radio>
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.MODERATED"
            class="flex items-start gap-3 [&_.o-radio__check]:rounded-full [&_.o-radio__check]:border-[#cac9cb]"
          >
            <div>
              <span class="font-bold text-[17px] leading-[26px]">{{
                $t("Moderate new members")
              }}</span>
              <p class="text-[15px] text-[#1c1b1f] leading-[23px] mt-1 pl-8">
                {{
                  $t(
                    "Anyone can request being a member, but an administrator needs to approve the membership."
                  )
                }}
              </p>
            </div>
          </o-radio>
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.INVITE_ONLY"
            class="flex items-start gap-3 [&_.o-radio__check]:rounded-full [&_.o-radio__check]:border-[#cac9cb]"
          >
            <div>
              <span class="font-bold text-[17px] leading-[26px]">{{
                $t("Manually invite new members")
              }}</span>
              <p class="text-[15px] text-[#1c1b1f] leading-[23px] mt-1 pl-8">
                {{
                  $t(
                    "The only way for your group to get new members is if an admininistrator invites them."
                  )
                }}
              </p>
            </div>
          </o-radio>
        </div>
      </fieldset>
      <div class="h-8 border-t border-[#e0e0e0]"></div>
      <fieldset class="space-y-4">
        <legend>
          <span class="text-xl font-bold text-[#1c1b1f] block">
            {{ t("Followers") }}
          </span>
          <span class="text-[17px] text-[#1c1b1f] leading-[26px] block mt-2">
            {{ t("Followers will receive new public events and posts.") }}
          </span>
        </legend>
        <div>
          <o-checkbox
            v-model="group.manuallyApprovesFollowers"
            class="flex items-center gap-3 [&_.o-checkbox__check]:border-[#cac9cb]"
          >
            <span class="text-[17px] leading-[26px]">{{
              t("Manually approve new followers")
            }}</span>
          </o-checkbox>
        </div>
      </fieldset>

      <div class="pt-4">
        <o-button
          variant="primary"
          :disabled="loading"
          :loading="loading"
          native-type="submit"
          class="px-8 py-[18px] bg-[#155eef] text-white font-bold text-[17px] hover:bg-[#0d4fd7] transition-colors"
        >
          {{ t("Create my group") }}
        </o-button>
      </div>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { Group, usernameWithDomain, displayName } from "@/types/actor";
import RouteName from "../../router/name";
import { convertToUsername } from "../../utils/username";
import PictureUpload from "../../components/PictureUpload.vue";
import { ErrorResponse } from "@/types/errors.model";
import { ServerParseError } from "@apollo/client/link/http";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import {
  computed,
  defineAsyncComponent,
  inject,
  reactive,
  ref,
  watch,
} from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { useCreateGroup } from "@/composition/apollo/group";
import {
  useAvatarMaxSize,
  useBannerMaxSize,
  useHost,
} from "@/composition/config";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";
import { Openness, GroupVisibility } from "@/types/enums";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const { currentActor } = useCurrentActorClient();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Create a new group")),
});

const group = ref(new Group());

const avatarFile = ref<File | null>(null);
const bannerFile = ref<File | null>(null);

const errors = ref<string[]>([]);

const fieldErrors = reactive<Record<string, string | undefined>>({
  preferred_username: undefined,
  summary: undefined,
});

const router = useRouter();

const host = useHost();
const avatarMaxSize = useAvatarMaxSize();
const bannerMaxSize = useBannerMaxSize();

const notifier = inject<Notifier>("notifier");

const showCopiedTooltipLight = ref(false);
const showCopiedTooltipDark = ref(false);

watch(
  () => group.value.name,
  (newGroupName) => {
    group.value.preferredUsername = convertToUsername(newGroupName);
  }
);

const baseUrl = computed(() => {
  const protocol = window.location.protocol;
  const hostname = host;
  const port = window.location.port ? `:${window.location.port}` : "";
  return `${protocol}//${hostname}${port}`;
});

const iframeCodeLight = computed(() => {
  const groupParam = group.value.preferredUsername
    ? `&group=${encodeURIComponent(group.value.preferredUsername)}`
    : "";
  return `<iframe
    src="${baseUrl.value}/banner/iframe?theme=light${groupParam}"
    width="100%"
    height="150"
    frameborder="0"
    title="Pragmatic Meet Banner">
</iframe>`;
});

const iframeCodeDark = computed(() => {
  const groupParam = group.value.preferredUsername
    ? `&group=${encodeURIComponent(group.value.preferredUsername)}`
    : "";
  return `<iframe
    src="${baseUrl.value}/banner/iframe?theme=dark${groupParam}"
    width="100%"
    height="150"
    frameborder="0"
    title="Pragmatic Meet Banner">
</iframe>`;
});

const canShowCopyButton = computed((): boolean => {
  return window.isSecureContext;
});

const copyIframeCodeLight = async (): Promise<void> => {
  await window.navigator.clipboard.writeText(iframeCodeLight.value);
  showCopiedTooltipLight.value = true;
  setTimeout(() => {
    showCopiedTooltipLight.value = false;
  }, 2000);
};

const copyIframeCodeDark = async (): Promise<void> => {
  await window.navigator.clipboard.writeText(iframeCodeDark.value);
  showCopiedTooltipDark.value = true;
  setTimeout(() => {
    showCopiedTooltipDark.value = false;
  }, 2000);
};

const buildVariables = computed(() => {
  let avatarObj = {};
  let bannerObj = {};

  const cloneGroup = group.value;
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  delete cloneGroup.physicalAddress.__typename;
  delete cloneGroup.physicalAddress.pictureInfo;

  const groupBasic = {
    preferredUsername: group.value.preferredUsername,
    name: group.value.name,
    summary: group.value.summary,
    customUrl: group.value.customUrl,
    visibility: group.value.visibility,
    openness: group.value.openness,
    manuallyApprovesFollowers: group.value.manuallyApprovesFollowers,
  };

  if (cloneGroup.physicalAddress?.id || cloneGroup.physicalAddress?.geom) {
    // @ts-expect-error No type for this variable
    groupBasic.physicalAddress = cloneGroup.physicalAddress;
  }

  if (avatarFile.value) {
    avatarObj = {
      avatar: {
        media: {
          name: avatarFile.value?.name,
          alt: `${group.value.preferredUsername}'s avatar`,
          file: avatarFile.value,
        },
      },
    };
  }

  if (bannerFile.value) {
    bannerObj = {
      banner: {
        media: {
          name: bannerFile.value?.name,
          alt: `${group.value.preferredUsername}'s banner`,
          file: bannerFile.value,
        },
      },
    };
  }

  return {
    ...groupBasic,
    ...avatarObj,
    ...bannerObj,
  };
});

const handleError = (err: ErrorResponse) => {
  if (err?.networkError?.name === "ServerParseError") {
    const error = err?.networkError as ServerParseError;

    if (error?.response?.status === 413) {
      errors.value.push(
        t(
          "Unable to create the group. One of the pictures may be too heavy."
        ) as string
      );
    }
  }
  err.graphQLErrors?.forEach((error) => {
    if (error.field) {
      if (Array.isArray(error.message)) {
        fieldErrors[error.field] = error.message[0];
      } else {
        fieldErrors[error.field] = error.message;
      }
    } else {
      errors.value.push(error.message);
    }
  });
};

const summaryErrors = computed(() => {
  const message = fieldErrors.summary ? fieldErrors.summary : undefined;
  const type = fieldErrors.summary ? "danger" : undefined;
  return [message, type];
});

const preferredUsernameErrors = computed(() => {
  const message = fieldErrors.preferred_username
    ? fieldErrors.preferred_username
    : t(
        "Only alphanumeric lowercased characters and underscores are supported."
      );
  const type = fieldErrors.preferred_username ? "danger" : undefined;
  return [message, type];
});

const { onDone, onError, mutate, loading } = useCreateGroup();

onDone(() => {
  notifier?.success(
    t("Group {displayName} created", {
      displayName: displayName(group.value),
    })
  );

  router.push({
    name: RouteName.GROUP,
    params: { preferredUsername: usernameWithDomain(group.value) },
  });
});

onError((err) => handleError(err as unknown as ErrorResponse));

const createGroup = async (): Promise<void> => {
  errors.value = [];
  fieldErrors.preferred_username = undefined;
  fieldErrors.summary = undefined;
  mutate(buildVariables.value);
};
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
