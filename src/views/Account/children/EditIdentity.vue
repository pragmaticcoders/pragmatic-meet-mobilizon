<template>
  <div class="bg-white min-h-screen">
    <breadcrumbs-nav :links="breadcrumbsLinks" />
    <div v-if="identity" class="py-4">
      <h1 class="font-bold text-[28px] leading-[36px] text-[#1c1b1f] mb-8">
        <span v-if="isUpdate" class="line-clamp-2">{{
          displayName(identity)
        }}</span>
        <span v-else>{{ t("Create a new profile") }}</span>
      </h1>
      <div
        v-if="identities?.length == 0"
        class="text-[16px] leading-[24px] text-[#1c1b1f] mb-8"
      >
        {{ t("Congratulations, your account is now created!") }}
        {{ t("Now, create your first profile:") }}
      </div>

      <!-- Avatar Section -->
      <div class="mb-8">
        <label
          class="block font-semibold text-[14px] leading-[20px] text-[#1c1b1f] mb-3"
        >
          {{ t("Avatar") }}
        </label>
        <div class="flex justify-center">
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
          {{ t("Display name") }}
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
          {{ t("Username") }}
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
          {{ isUpdate ? t("Save") : t("Create my profile") }}
        </button>
        <button
          v-if="isUpdate"
          @click="openDeleteIdentityConfirmation()"
          type="button"
          class="px-6 py-3 bg-[#cc0000] text-white font-bold text-[16px] leading-[24px] hover:bg-red-700 transition-colors"
        >
          {{ t("Delete this identity") }}
        </button>
      </div>

      <!-- Profile Feeds Section -->
      <section v-if="isUpdate" class="border-t border-gray-200 pt-8">
        <h2 class="font-bold text-[20px] leading-[28px] text-[#1c1b1f] mb-4">
          {{ t("Profile feeds") }}
        </h2>
        <p class="text-[14px] leading-[20px] text-gray-600 mb-6">
          {{
            t(
              "These feeds contain event data for the events for which this specific profile is a participant or creator." +
                "You should keep these private." +
                " You can find feeds for all of your profiles into your notification settings."
            )
          }}
        </p>
        <div v-if="identity.feedTokens && identity.feedTokens.length > 0">
          <div
            class="flex flex-wrap gap-3"
            v-for="feedToken in identity.feedTokens"
            :key="feedToken.token"
          >
            <o-tooltip
              :label="t('URL copied to clipboard')"
              :active="showCopiedTooltip.atom"
              variant="success"
              position="left"
            />
            <button
              @click="
                (e: Event) =>
                  copyURL(e, tokenToURL(feedToken.token, 'atom'), 'atom')
              "
              class="inline-flex items-center gap-2 px-4 py-2 bg-white text-[#155eef] border border-[#155eef] font-medium text-[14px] hover:bg-blue-50 transition-colors"
            >
              <o-icon icon="rss" size="small" />
              {{ t("RSS/Atom Feed") }}
            </button>
            <o-tooltip
              :label="t('URL copied to clipboard')"
              :active="showCopiedTooltip.ics"
              variant="success"
              position="left"
            />
            <button
              @click="
                (e: Event) =>
                  copyURL(e, tokenToURL(feedToken.token, 'ics'), 'ics')
              "
              class="inline-flex items-center gap-2 px-4 py-2 bg-white text-[#155eef] border border-[#155eef] font-medium text-[14px] hover:bg-blue-50 transition-colors"
            >
              <o-icon icon="calendar-sync" size="small" />
              {{ t("ICS/WebCal Feed") }}
            </button>
            <button
              @click="openRegenerateFeedTokensConfirmation"
              class="inline-flex items-center gap-2 px-4 py-2 text-[#155eef] font-medium text-[14px] hover:bg-gray-50 transition-colors"
            >
              <o-icon icon="refresh" size="small" />
              {{ t("Regenerate new links") }}
            </button>
          </div>
        </div>
        <div v-else>
          <button
            @click="generateFeedTokens"
            class="inline-flex items-center gap-2 px-4 py-2 text-[#155eef] font-medium text-[14px] hover:bg-gray-50 transition-colors"
          >
            <o-icon icon="refresh" size="small" />
            {{ t("Create new links") }}
          </button>
        </div>
      </section>
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
  CREATE_PERSON,
  DELETE_PERSON,
  FETCH_PERSON_OWNED,
  IDENTITIES,
  PERSON_FRAGMENT,
  PERSON_FRAGMENT_FEED_TOKENS,
  UPDATE_PERSON,
} from "@/graphql/actor";
import { IPerson, displayName } from "@/types/actor";
import PictureUpload from "@/components/PictureUpload.vue";
import { MOBILIZON_INSTANCE_HOST } from "@/api/_entrypoint";
import RouteName from "@/router/name";
import { buildFileFromIMedia, buildFileVariable } from "@/utils/image";
import { changeIdentity } from "@/utils/identity";
import {
  CREATE_FEED_TOKEN_ACTOR,
  DELETE_FEED_TOKEN,
} from "@/graphql/feed_tokens";
import { IFeedToken } from "@/types/feedtoken.model";
import { ServerParseError } from "@apollo/client/link/http";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import pick from "lodash/pick";
import { ActorType } from "@/types/enums";
import { useRouter } from "vue-router";
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

const props = defineProps<{ isUpdate: boolean; identityName?: string }>();

const { currentActor } = useCurrentActorClient();

const { identities } = useCurrentUserIdentities();

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
  avatarFile.value = await buildFileFromIMedia(data?.fetchPerson?.avatar);
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

watch(person, () => {
  console.debug("person changed", person.value);
  if (person.value) {
    identity.value = { ...person.value };
  }
});

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

watch(identityName, async () => {
  // Only used when we update the identity
  if (!isUpdate.value) {
    identity.value = baseIdentity;
    return;
  }

  await redirectIfNoIdentitySelected(identityName.value);

  if (!identityName.value) {
    router.push({ name: "CreateIdentity" });
  }

  if (identityName.value && identity.value) {
    avatarFile.value = null;
  }
});

const submit = (): Promise<void> => {
  if (props.isUpdate) return updateIdentity();

  return createIdentity();
};

const {
  mutate: deletePersonMutation,
  onDone: deletePersonDone,
  onError: deletePersonError,
} = useMutation(DELETE_PERSON, () => ({
  update: (store: ApolloCache<InMemoryCache>) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data) {
      store.writeQuery({
        query: IDENTITIES,
        data: {
          loggedUser: {
            ...data.loggedUser,
            actors: data.loggedUser.actors.filter(
              (i) => i.id !== identity.value.id
            ),
          },
        },
      });
    }
  },
}));

const notifier = inject<Notifier>("notifier");

const { resolveClient } = useApolloClient();

deletePersonDone(async () => {
  notifier?.success(
    t("Identity {displayName} deleted", {
      displayName: displayName(identity.value),
    })
  );
  /**
   * If we just deleted the current identity,
   * we need to change it to the next one
   */
  const client = resolveClient();
  const data = client.readQuery<{
    loggedUser: Pick<ICurrentUser, "actors">;
  }>({ query: IDENTITIES });
  if (data) {
    await maybeUpdateCurrentActorCache(data.loggedUser.actors[0]);
  }

  await redirectIfNoIdentitySelected();
});

deletePersonError((err) => handleError(err));

/**
 * Delete an identity
 */
const deleteIdentity = async (): Promise<void> => {
  deletePersonMutation({
    id: identity.value?.id,
  });
};

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

const {
  mutate: createIdentityMutation,
  onDone: createIdentityDone,
  onError: createIdentityError,
} = useMutation(CREATE_PERSON, () => ({
  update: (
    store: ApolloCache<InMemoryCache>,
    { data: updateData }: FetchResult
  ) => {
    const data = store.readQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>({
      query: IDENTITIES,
    });

    if (data && updateData?.createPerson) {
      store.writeQuery({
        query: IDENTITIES,
        data: {
          loggedUser: {
            ...data.loggedUser,
            actors: [
              ...data.loggedUser.actors,
              { ...updateData?.createPerson, type: ActorType.PERSON },
            ],
          },
        },
      });
    }
  },
}));

createIdentityDone(async () => {
  notifier?.success(
    t("Identity {displayName} created", {
      displayName: displayName(identity.value),
    })
  );

  // If it is the fisrt created identity, then we need to activate this identity
  const client = resolveClient();
  const data = client.readQuery<{
    loggedUser: Pick<ICurrentUser, "actors">;
  }>({ query: IDENTITIES });
  if (data) {
    await maybeUpdateCurrentActorCache(data.loggedUser.actors[0]);
  }

  router.push({
    name: RouteName.UPDATE_IDENTITY,
    params: { identityName: identity.value.preferredUsername },
  });
});

createIdentityError((err) => handleError(err));

const createIdentity = async (): Promise<void> => {
  const variables = await buildVariables();

  createIdentityMutation(variables);
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
  if (currentActor.value) {
    // If there is no current actor, update the current actor
    if (
      currentActor.value.preferredUsername ===
        identity.value.preferredUsername ||
      currentActor.value.id == null
    ) {
      await changeIdentity(newIdentity);
    }
    // currentActor.value = newIdentity;
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
    if (props.isUpdate && identity.value) {
      links.push({
        name: RouteName.UPDATE_IDENTITY,
        params: { identityName: identity.value.preferredUsername },
        text: identity.value.name,
      });
    } else {
      links.push({
        name: RouteName.CREATE_IDENTITY,
        params: {},
        text: t("New profile") as string,
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
    let title = t("Create a new profile") as string;
    if (isUpdate.value) {
      title = t("Edit profile {profile}", {
        profile: identityName.value,
      }) as string;
    }
    return title;
  }),
});
</script>
