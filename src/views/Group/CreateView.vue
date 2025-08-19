<template>
  <section
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
  >
    <h1 class="text-3xl font-bold mb-8">{{ t("Create a new group") }}</h1>

    <o-notification
      variant="danger"
      v-for="(value, index) in errors"
      :key="index"
    >
      {{ value }}
    </o-notification>

    <form @submit.prevent="createGroup" class="space-y-6">
      <div class="space-y-2">
        <label
          for="group-display-name"
          class="block text-sm font-medium text-gray-700"
        >
          {{ t("Group display name") }}
        </label>
        <o-input
          aria-required="true"
          required
          expanded
          v-model="group.name"
          id="group-display-name"
          class="w-full"
        />
      </div>

      <div class="space-y-2">
        <label
          class="block text-sm font-medium text-gray-700"
          for="group-preferred-username"
          >{{ t("Federated Group Name") }}</label
        >
        <div class="flex gap-2">
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
              class="flex items-center px-3 bg-gray-100 text-gray-600 font-medium"
            >
              @{{ host }}
            </div>
          </o-field>
        </div>
        <p class="text-sm text-gray-600 mt-2" v-if="currentActor">
          <i18n-t
            keypath="This is like your federated username ({username}) for groups. It will allow the group to be found on the federation, and is guaranteed to be unique."
          >
            <template #username>
              <code class="bg-gray-100 px-1 py-0.5 text-sm">
                {{ usernameWithDomain(currentActor, true) }}
              </code>
            </template>
          </i18n-t>
        </p>
      </div>

      <div class="space-y-2">
        <label
          for="group-summary"
          class="block text-sm font-medium text-gray-700"
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
            class="w-full"
          />
        </o-field>
      </div>

      <div class="space-y-2">
        <full-address-auto-complete
          :label="$t('Group address')"
          v-model="group.physicalAddress"
        />
      </div>

      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700">
          {{ t("Avatar") }}
        </label>
        <picture-upload
          :textFallback="t('Avatar')"
          v-model="avatarFile"
          :maxSize="avatarMaxSize"
        />
      </div>

      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700">
          {{ t("Banner") }}
        </label>
        <picture-upload
          :textFallback="t('Banner')"
          v-model="bannerFile"
          :maxSize="bannerMaxSize"
        />
      </div>

      <fieldset class="space-y-3">
        <legend class="text-sm font-medium text-gray-700 mb-3">
          {{ t("Group visibility") }}
        </legend>
        <div class="bg-gray-50 p-4 space-y-3">
          <o-radio
            v-model="group.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.PUBLIC"
            class="flex items-start"
          >
            <div>
              <span class="font-medium">{{
                $t("Visible everywhere on the web")
              }}</span>
              <p class="text-sm text-gray-600 mt-1">
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
            class="flex items-start"
          >
            <div>
              <span class="font-medium">{{
                $t("Only accessible through link")
              }}</span>
              <p class="text-sm text-gray-600 mt-1">
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
      <fieldset class="space-y-3">
        <legend>
          <span class="text-sm font-medium text-gray-700 block mb-1">{{
            t("New members")
          }}</span>
          <span class="text-sm text-gray-600">
            {{
              t(
                "Members will also access private sections like discussions, resources and restricted posts."
              )
            }}
          </span>
        </legend>
        <div class="bg-gray-50 p-4 space-y-3">
          <o-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.OPEN"
            class="flex items-start"
          >
            <div>
              <span class="font-medium">{{
                $t("Anyone can join freely")
              }}</span>
              <p class="text-sm text-gray-600 mt-1">
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
            class="flex items-start"
          >
            <div>
              <span class="font-medium">{{ $t("Moderate new members") }}</span>
              <p class="text-sm text-gray-600 mt-1">
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
            class="flex items-start"
          >
            <div>
              <span class="font-medium">{{
                $t("Manually invite new members")
              }}</span>
              <p class="text-sm text-gray-600 mt-1">
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
      <fieldset class="space-y-3">
        <legend>
          <span class="text-sm font-medium text-gray-700 block mb-1">
            {{ t("Followers") }}
          </span>
          <span class="text-sm text-gray-600">
            {{ t("Followers will receive new public events and posts.") }}
          </span>
        </legend>
        <div class="bg-gray-50 p-4">
          <o-checkbox
            v-model="group.manuallyApprovesFollowers"
            class="flex items-center"
          >
            <span class="ml-2">{{ t("Manually approve new followers") }}</span>
          </o-checkbox>
        </div>
      </fieldset>

      <div class="pt-6">
        <o-button
          variant="primary"
          :disabled="loading"
          :loading="loading"
          native-type="submit"
          class="px-6 py-3 bg-primary text-white font-medium hover:bg-primary-600 transition-colors"
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

watch(
  () => group.value.name,
  (newGroupName) => {
    group.value.preferredUsername = convertToUsername(newGroupName);
  }
);

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
