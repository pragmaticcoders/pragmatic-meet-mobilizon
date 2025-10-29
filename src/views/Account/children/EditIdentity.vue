<template>
  <div class="bg-white min-h-screen">
    <breadcrumbs-nav :links="breadcrumbsLinks" />
    <div v-if="identity" class="py-4">
      <h1 class="font-bold text-[28px] leading-[36px] text-[#1c1b1f] mb-8">
        <span class="line-clamp-2">{{
          displayName(identity)
        }}</span>
      </h1>

      <!-- LinkedIn prefill notification -->
      <div
        v-if="isFromLinkedIn"
        class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 text-sm mb-6 rounded-md"
      >
        <div class="flex items-start">
          <o-icon
            icon="linkedin"
            size="small"
            class="mr-2 mt-0.5"
          />
          <div>
            <p class="font-medium">{{ t("Profile data from LinkedIn") }}</p>
            <p class="text-blue-600 text-xs mt-1">
              {{ t("Your profile has been prefilled with information from your LinkedIn account. Please review and modify as needed.") }}
            </p>
          </div>
        </div>
      </div>

      <!-- Avatar Section -->
      <div class="mb-8">
        <label
          class="block font-semibold text-[14px] leading-[20px] text-[#1c1b1f] mb-3"
        >
          {{ t("Avatar") }}
        </label>
        <div class="max-w-xs">
          <picture-upload
            v-model="avatarFile"
            :defaultImage="identity.avatar"
            :maxSize="avatarMaxSize"
          />
        </div>
      </div>

      <!-- Display Name Field -->
      <div class="mb-6">
        <label
          for="identity-display-name"
          class="block font-semibold text-[14px] leading-[20px] text-[#1c1b1f] mb-2"
        >
          {{ t("Display name") }} <span class="text-red-500">*</span>
        </label>
        <o-input
          aria-required="true"
          required
          v-model="identity.name"
          @update:modelValue="(value: string) => updateUsername(value)"
          id="identity-display-name"
          dir="auto"
          expanded
          class="w-full"
        />
      </div>

      <!-- Username Field -->
      <div class="mb-6">
        <label
          for="identity-username"
          class="block font-semibold text-[14px] leading-[20px] text-[#1c1b1f] mb-2"
        >
          {{ t("Username") }} <span class="text-red-500">*</span>
        </label>
        <div class="flex">
          <o-input
            expanded
            aria-required="true"
            required
            v-model="identity.preferredUsername"
            :disabled="isUpdate"
            dir="auto"
            :use-html5-validation="!isUpdate"
            pattern="[a-z0-9_]+"
            id="identity-username"
            class="flex-1"
          />
          <span
            class="inline-flex items-center px-3 bg-gray-100 text-gray-600 border border-l-0 border-gray-300 text-[14px]"
          >
            @{{ getInstanceHost }}
          </span>
        </div>
        <p v-if="message" class="text-[13px] text-gray-500 mt-2">
          {{ message }}
        </p>
      </div>

      <p
        class="text-[14px] leading-[20px] text-gray-600 mb-6 flex items-start gap-2"
      >
        <o-icon
          icon="information-outline"
          size="small"
          class="mt-0.5 text-gray-500"
        />
        <span>{{
          t(
            "This identifier is unique to your profile. It allows others to find you."
          )
        }}</span>
      </p>

      <!-- Description Field -->
      <div class="mb-8">
        <label
          for="identity-summary"
          class="block font-semibold text-[14px] leading-[20px] text-[#1c1b1f] mb-2"
        >
          {{ t("Description") }}
        </label>
        <o-input
          type="textarea"
          dir="auto"
          aria-required="false"
          v-model="identity.summary"
          id="identity-summary"
          expanded
          class="w-full"
          :rows="6"
        />
      </div>

      <!-- Error Notifications -->
      <o-notification
        variant="danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in errors"
        class="mb-4"
        >{{ error }}</o-notification
      >

      <!-- Action Buttons -->
      <div class="flex gap-4 mb-12">
        <button
          type="button"
          @click="submit()"
          class="px-6 py-3 bg-[#155eef] text-white font-bold text-[16px] leading-[24px] hover:bg-blue-600 transition-colors"
        >
          {{ t("Save") }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
@use "@/styles/_mixins" as *;
// h1 {
//   display: flex;
//   justify-content: center;
// }

// .username-field + .field {
//   margin-bottom: 0;
// }

:deep(.buttons > *:not(:last-child) .button) {
  @include margin-right(0.5rem);
}
</style>

<script lang="ts" setup>
import {
  FETCH_PERSON_OWNED,
  IDENTITIES,
  PERSON_FRAGMENT,
  PERSON_FRAGMENT_FEED_TOKENS,
  UPDATE_PERSON,
  UPDATE_CURRENT_ACTOR_CLIENT,
} from "@/graphql/actor";
import { IPerson, displayName } from "@/types/actor";
import PictureUpload from "@/components/PictureUpload.vue";
import { MOBILIZON_INSTANCE_HOST } from "@/api/_entrypoint";
import RouteName from "@/router/name";
import { buildFileFromIMedia, buildFileVariable } from "@/utils/image";
import {
  CREATE_FEED_TOKEN_ACTOR,
  DELETE_FEED_TOKEN,
} from "@/graphql/feed_tokens";
import { IFeedToken } from "@/types/feedtoken.model";
import { ServerParseError } from "@apollo/client/link/http";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import pick from "lodash/pick";
import { ActorType } from "@/types/enums";
import { useRouter, useRoute } from "vue-router";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
} from "@/composition/apollo/actor";
import { useMutation, useQuery, useApolloClient } from "@vue/apollo-composable";
import { useAvatarMaxSize } from "@/composition/config";
import { computed, inject, reactive, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { convertToUsername } from "@/utils/username";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";
import { ICurrentUser } from "@/types/current-user.model";
import { useHead } from "@/utils/head";

const { t } = useI18n({ useScope: "global" });
const router = useRouter();
const route = useRoute();

// Detect if user came from LinkedIn registration
const isFromLinkedIn = computed(() => route.query.source === "linkedin");

const props = defineProps<{ isUpdate: boolean; identityName?: string }>();

const { currentActor } = useCurrentActorClient();

const { identities } = useCurrentUserIdentities();

const { mutate: updateCurrentActorClient } = useMutation(UPDATE_CURRENT_ACTOR_CLIENT);

const {
  result: personResult,
  onError: onPersonError,
  onResult: onPersonResult,
} = useQuery<{
  fetchPerson: IPerson;
}>(
  FETCH_PERSON_OWNED,
  () => ({
    username: props.identityName,
  }),
  () => ({
    enabled: props.identityName !== undefined,
  })
);

onPersonResult(async ({ data }) => {
  if (data?.fetchPerson) {
    avatarFile.value = await buildFileFromIMedia(data.fetchPerson.avatar);
    // Ensure identity is updated with the fresh data
    identity.value = { ...data.fetchPerson };
  }
});

onPersonError((err) => handleErrors(err as unknown as AbsintheGraphQLErrors));

const person = computed(() => personResult.value?.fetchPerson);

const baseIdentity: IPerson = {
  id: undefined,
  avatar: null,
  name: "",
  preferredUsername: "",
  summary: "",
  feedTokens: [],
  url: "",
  domain: null,
  type: ActorType.PERSON,
  suspended: false,
};

const identity = ref<IPerson>(baseIdentity);

watch(
  person,
  () => {
    console.debug("person changed", person.value);
    if (person.value) {
      identity.value = { ...person.value };
    }
  },
  { immediate: true }
);

const avatarMaxSize = useAvatarMaxSize();

const errors = ref<string[]>([]);
const avatarFile = ref<File | null>(null);
const showCopiedTooltip = reactive({ ics: false, atom: false });

const isUpdate = computed(() => props.isUpdate);
const identityName = computed(() => props.identityName);

const message = computed((): string | null => {
  if (props.isUpdate) return null;
  return t(
    "Only alphanumeric lowercased characters and underscores are supported."
  );
});

watch(isUpdate, () => {
  resetFields();
});

watch(
  identityName,
  async () => {
    // Only used when we update the identity
    if (!isUpdate.value) {
      identity.value = baseIdentity;
      return;
    }

    await redirectIfNoIdentitySelected(identityName.value);

    if (!identityName.value) {
      router.push({ name: "CreateIdentity" });
      return;
    }

    // Reset avatar file when switching identities
    if (identityName.value) {
      avatarFile.value = null;
      // Reset identity to base state while loading
      identity.value = { ...baseIdentity };
    }
  },
  { immediate: true }
);

// Watch for route parameter changes to handle navigation from settings menu
watch(
  () => route.params.identityName,
  (newIdentityName) => {
    if (
      newIdentityName &&
      typeof newIdentityName === "string" &&
      isUpdate.value
    ) {
      // Reset the form state when switching between identities
      errors.value = [];
      avatarFile.value = null;
      identity.value = { ...baseIdentity };
    }
  },
  { immediate: true }
);

const submit = (): Promise<void> => {
  // Clear previous errors
  errors.value = [];
  
  // Validate required fields
  const validationErrors: string[] = [];
  
  if (!identity.value.name?.trim()) {
    validationErrors.push(t("Display name is required") as string);
  }
  
  if (!identity.value.preferredUsername?.trim()) {
    validationErrors.push(t("Username is required") as string);
  }
  
  if (validationErrors.length > 0) {
    errors.value = validationErrors;
    return Promise.resolve();
  }

  return updateIdentity();
};

const notifier = inject<Notifier>("notifier");

const { resolveClient } = useApolloClient();

const {
  mutate: updateIdentityMutation,
  onDone: updateIdentityDone,
  onError: updateIdentityError,
} = useMutation(UPDATE_PERSON, () => ({
  update: (
    store: ApolloCache<InMemoryCache>,
    { data: updateData }: FetchResult
  ) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data && updateData?.updatePerson) {
      maybeUpdateCurrentActorCache(updateData?.updatePerson);

      store.writeFragment({
        fragment: PERSON_FRAGMENT,
        id: `Person:${updateData?.updatePerson.id}`,
        data: {
          ...updateData?.updatePerson,
          type: ActorType.PERSON,
        },
      });
    }
  },
}));

updateIdentityDone(() => {
  notifier?.success(
    t("Identity {displayName} updated", {
      displayName: displayName(identity.value),
    }) as string
  );
});

updateIdentityError((err) => handleError(err));

const updateIdentity = async (): Promise<void> => {
  const variables = await buildVariables();

  updateIdentityMutation(variables);
};

const handleErrors = (absintheErrors: AbsintheGraphQLErrors): void => {
  if (absintheErrors.some((error) => error.status_code === 401)) {
    router.push({ name: RouteName.LOGIN });
  }
};

// eslint-disable-next-line class-methods-use-this
const getInstanceHost = computed((): string => {
  return MOBILIZON_INSTANCE_HOST;
});

const tokenToURL = (token: string, format: string): string => {
  return `${window.location.origin}/events/going/${token}/${format}`;
};

const copyURL = (e: Event, url: string, format: "ics" | "atom"): void => {
  if (navigator.clipboard) {
    e.preventDefault();
    navigator.clipboard.writeText(url);
    showCopiedTooltip[format] = true;
    setTimeout(() => {
      showCopiedTooltip[format] = false;
    }, 2000);
  }
};

const generateFeedTokens = async (): Promise<void> => {
  await createNewFeedToken({ actor_id: identity.value?.id });
};

const regenerateFeedTokens = async (): Promise<void> => {
  if (identity.value?.feedTokens.length < 1) return;
  await deleteFeedToken({ token: identity.value.feedTokens[0].token });
  await createNewFeedToken(
    { actor_id: identity.value?.id },
    {
      update(cache, { data }) {
        const actorId = data?.createFeedToken.actor?.id;
        const newFeedToken = data?.createFeedToken.token;

        if (!newFeedToken) return;

        let cachedData = cache.readFragment<{
          id: string | undefined;
          feedTokens: { token: string }[];
        }>({
          id: `Person:${actorId}`,
          fragment: PERSON_FRAGMENT_FEED_TOKENS,
        });
        // Remove the old token
        cachedData = {
          id: cachedData?.id,
          feedTokens: [
            ...(cachedData?.feedTokens ?? []).slice(0, -1),
            { token: newFeedToken },
          ],
        };
        cache.writeFragment({
          id: `Person:${actorId}`,
          fragment: PERSON_FRAGMENT_FEED_TOKENS,
          data: cachedData,
        });
      },
    }
  );
};

const { mutate: deleteFeedToken } = useMutation(DELETE_FEED_TOKEN);

const { mutate: createNewFeedToken } = useMutation<{
  createFeedToken: IFeedToken;
}>(CREATE_FEED_TOKEN_ACTOR, () => ({
  update(cache, { data }) {
    const actorId = data?.createFeedToken.actor?.id;
    const newFeedToken = data?.createFeedToken.token;

    if (!newFeedToken) return;

    let cachedData = cache.readFragment<{
      id: string | undefined;
      feedTokens: { token: string }[];
    }>({
      id: `Person:${actorId}`,
      fragment: PERSON_FRAGMENT_FEED_TOKENS,
    });
    // Add the new token to the list
    cachedData = {
      id: cachedData?.id,
      feedTokens: [...(cachedData?.feedTokens ?? []), { token: newFeedToken }],
    };
    cache.writeFragment({
      id: `Person:${actorId}`,
      fragment: PERSON_FRAGMENT_FEED_TOKENS,
      data: cachedData,
    });
  },
}));

const dialog = inject<Dialog>("dialog");

const openRegenerateFeedTokensConfirmation = (): void => {
  dialog?.confirm({
    variant: "warning",
    title: t("Regenerate new links") as string,
    message: t(
      "You'll need to change the URLs where there were previously entered."
    ) as string,
    confirmText: t("Regenerate new links") as string,
    cancelText: t("Cancel") as string,
    onConfirm: () => regenerateFeedTokens(),
  });
};

const openDeleteIdentityConfirmation = (): void => {
  dialog?.prompt({
    variant: "danger",
    title: t("Delete your identity") as string,
    message: `${t(
      "This will delete / anonymize all content (events, comments, messages, participations…) created from this identity."
    )}
            <br /><br />
            ${t(
              "If this identity is the only administrator of some groups, you need to delete them before being able to delete this identity."
            )}
            ${t(
              "Otherwise this identity will just be removed from the group administrators."
            )}
            <br /><br />
            ${t(
              'To confirm, type your identity username "{preferredUsername}"',
              {
                preferredUsername: identity.value.preferredUsername,
              }
            )}`,
    confirmText: t("Delete {preferredUsername}", {
      preferredUsername: identity.value.preferredUsername,
    }),
    inputAttrs: {
      placeholder: identity.value.preferredUsername,
      pattern: identity.value.preferredUsername,
    },
    onConfirm: () => deleteIdentity(),
  });
};

const handleError = (err: any) => {
  console.error(err);

  if (err?.networkError?.name === "ServerParseError") {
    const error = err?.networkError as ServerParseError;

    if (error?.response?.status === 413) {
      const errorMessage = props.isUpdate
        ? t(
            "Unable to update the profile. The avatar picture may be too heavy."
          )
        : t(
            "Unable to create the profile. The avatar picture may be too heavy."
          );
      errors.value.push(errorMessage as string);
    }
  }

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(
      ({ message: errorMessage }: { message: string }) => {
        notifier?.error(errorMessage);
      }
    );
  }
};

const buildVariables = async (): Promise<Record<string, unknown>> => {
  /**
   * We set the avatar only if user has selected one
   */
  let avatarObj: Record<string, unknown> = { avatar: null };
  if (avatarFile.value) {
    avatarObj = buildFileVariable(
      avatarFile.value,
      "avatar",
      `${identity.value.preferredUsername}'s avatar`
    );
  }
  return pick({ ...identity.value, ...avatarObj }, [
    "id",
    "preferredUsername",
    "name",
    "summary",
    "avatar",
  ]);
};

const redirectIfNoIdentitySelected = async (identityParam?: string) => {
  if (identityParam) return;

  // await loadLoggedPersonIfNeeded();

  if (currentActor.value) {
    await router.push({
      params: { identityName: currentActor.value?.preferredUsername },
    });
  }
};

const maybeUpdateCurrentActorCache = async (newIdentity: IPerson) => {
  // Update current actor cache with the updated identity data
  if (currentActor.value && currentActor.value.id === newIdentity.id) {
    await updateCurrentActorClient({
      id: newIdentity.id,
      avatar: newIdentity.avatar?.url,
      preferredUsername: newIdentity.preferredUsername,
      name: newIdentity.name,
    });
  }
};

// const loadLoggedPersonIfNeeded = async (bypassCache = false) => {
//   if (currentActor.value) return;

//   const result = await this.$apollo.query({
//     query: CURRENT_ACTOR_CLIENT,
//     fetchPolicy: bypassCache ? "network-only" : undefined,
//   });

//   currentActor.value = result.data.currentActor;
// };

const resetFields = () => {
  // identity.value = new Person();
  // oldDisplayName.value = null;
  avatarFile.value = null;
};

const breadcrumbsLinks = computed(
  (): { name: string; params: Record<string, any>; text: string }[] => {
    const links = [
      {
        name: RouteName.IDENTITIES,
        params: {},
        text: t("Profiles") as string,
      },
    ];
    if (identity.value) {
      links.push({
        name: RouteName.UPDATE_IDENTITY,
        params: { identityName: identity.value.preferredUsername },
        text: identity.value.name,
      });
    }
    return links;
  }
);

const updateUsername = (value: string) => {
  if (props.isUpdate) return;
  identity.value.preferredUsername = convertToUsername(value);
};

useHead({
  title: computed(() => {
    return t("Edit profile {profile}", {
      profile: identityName.value,
    }) as string;
  }),
});
</script>
