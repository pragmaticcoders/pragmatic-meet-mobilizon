<template>
  <div>
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Settings'),
        },
        {
          name: RouteName.GROUP_PUBLIC_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Group settings'),
        },
      ]"
    />
    <o-loading :active="loading" />
    <section class="" v-if="group && isCurrentActorAGroupAdmin">
      <div class="bg-white shadow-sm p-2">
        <div class="mb-8">
          <h2 class="text-2xl font-semibold text-gray-900">
            {{ t("Group settings") }}
          </h2>
        </div>
        <form
          @submit.prevent="updateGroup(buildVariables)"
          v-if="editableGroup"
          class="space-y-8"
        >
          <div class="space-y-2">
            <label
              for="group-settings-name"
              class="block text-sm font-medium text-gray-700"
            >
              {{ t("Group name") }}
            </label>
            <o-input
              v-model="editableGroup.name"
              id="group-settings-name"
              expanded
              class="w-full"
            />
          </div>
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
              {{ t("Group short description") }}
            </label>
            <Editor
              mode="basic"
              v-model="editableGroup.summary"
              :maxSize="500"
              :aria-label="t('Group description body')"
              v-if="currentActor"
              :currentActor="currentActor"
              :placeholder="t('A few lines about your group')"
              class="w-full"
            />
          </div>
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
              {{ t("Custom URL") }}
            </label>
            <o-input
              v-model="editableGroup.customUrl"
              type="url"
              :placeholder="t('https://example.com')"
              :disabled="group?.approvalStatus === ApprovalStatus.PENDING_APPROVAL"
              expanded
              class="w-full"
            />
            <p class="text-sm text-gray-500">
              {{ t("Optional: Add a custom URL for your group (e.g., your website or social media)") }}
            </p>
            <p v-if="group?.approvalStatus === ApprovalStatus.PENDING_APPROVAL" class="text-sm text-amber-600">
              {{ t("URL editing is disabled while your group is awaiting approval") }}
            </p>
          </div>
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
              {{ t("Avatar") }}
            </label>
            <picture-upload
              :textFallback="t('Avatar')"
              v-model="avatarFile"
              :defaultImage="group.avatar"
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
              :defaultImage="group.banner"
              :maxSize="bannerMaxSize"
            />
          </div>
          <div class="space-y-3">
            <h3 class="text-lg font-semibold text-gray-900">
              {{ t("Group visibility") }}
            </h3>
            <div class="space-y-3">
              <label class="flex items-start">
                <o-radio
                  v-model="editableGroup.visibility"
                  name="groupVisibility"
                  :native-value="GroupVisibility.PUBLIC"
                  class="mt-1"
                />
                <div class="ml-3">
                  <span class="text-gray-900">{{
                    t("Visible everywhere on the web")
                  }}</span>
                  <p class="text-sm text-gray-600 mt-1">
                    {{
                      t(
                        "The group will be publicly listed in search results and may be suggested in the explore section. Only public informations will be shown on it's page."
                      )
                    }}
                  </p>
                </div>
              </label>
            </div>
            <div class="space-y-3">
              <label class="flex items-start">
                <o-radio
                  v-model="editableGroup.visibility"
                  name="groupVisibility"
                  :native-value="GroupVisibility.UNLISTED"
                  class="mt-1"
                />
                <div class="ml-3">
                  <span class="text-gray-900">{{
                    t("Only accessible through link")
                  }}</span>
                  <p class="text-sm text-gray-600 mt-1">
                    {{
                      t(
                        "You'll need to transmit the group URL so people may access the group's profile. The group won't be findable in Mobilizon's search or regular search engines."
                      )
                    }}
                  </p>
                </div>
              </label>
              <div class="ml-9 flex items-center gap-2 mt-2">
                <code class="text-sm bg-gray-100 px-2 py-1 rounded">{{
                  group.url
                }}</code>
                <o-tooltip
                  v-if="canShowCopyButton"
                  :label="t('URL copied to clipboard')"
                  :active="showCopiedTooltip"
                  variant="success"
                  position="left"
                />
                <o-button
                  variant="primary"
                  icon-right="content-paste"
                  native-type="button"
                  @click="copyURL"
                  @keyup.enter="copyURL"
                />
              </div>
            </div>
          </div>

          <div class="space-y-3">
            <h3 class="text-lg font-semibold text-gray-900">
              {{ t("New members") }}
            </h3>
            <div class="space-y-3">
              <label class="flex items-start">
                <o-radio
                  v-model="editableGroup.openness"
                  name="groupOpenness"
                  :native-value="Openness.OPEN"
                  class="mt-1"
                />
                <div class="ml-3">
                  <span class="text-gray-900">{{
                    t("Anyone can join freely")
                  }}</span>
                  <p class="text-sm text-gray-600 mt-1">
                    {{
                      t(
                        "Anyone wanting to be a member from your group will be able to from your group page."
                      )
                    }}
                  </p>
                </div>
              </label>
            </div>
            <div class="space-y-3">
              <label class="flex items-start">
                <o-radio
                  v-model="editableGroup.openness"
                  name="groupOpenness"
                  :native-value="Openness.MODERATED"
                  class="mt-1"
                />
                <div class="ml-3">
                  <span class="text-gray-900">{{
                    t("Moderate new members")
                  }}</span>
                  <p class="text-sm text-gray-600 mt-1">
                    {{
                      t(
                        "Anyone can request being a member, but an administrator needs to approve the membership."
                      )
                    }}
                  </p>
                </div>
              </label>
            </div>
            <div class="space-y-3">
              <label class="flex items-start">
                <o-radio
                  v-model="editableGroup.openness"
                  name="groupOpenness"
                  :native-value="Openness.INVITE_ONLY"
                  class="mt-1"
                />
                <div class="ml-3">
                  <span class="text-gray-900">{{
                    t("Manually invite new members")
                  }}</span>
                  <p class="text-sm text-gray-600 mt-1">
                    {{
                      t(
                        "The only way for your group to get new members is if an admininistrator invites them."
                      )
                    }}
                  </p>
                </div>
              </label>
            </div>
          </div>

          <div class="space-y-3">
            <h3 class="text-lg font-semibold text-gray-900">
              {{ t("Followers") }}
            </h3>
            <p class="text-sm text-gray-600">
              {{ t("Followers will receive new public events and posts.") }}
            </p>
            <label class="flex items-center">
              <o-checkbox v-model="editableGroup.manuallyApprovesFollowers" />
              <span class="ml-3 text-gray-900">{{
                t("Manually approve new followers")
              }}</span>
            </label>
          </div>

          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
              {{ t("Group address") }}
            </label>
            <full-address-auto-complete
              v-model="currentAddress"
              :allowManualDetails="true"
              :hideMap="true"
            />
          </div>

          <div class="flex gap-3 pt-6 border-t border-gray-200">
            <o-button
              :loading="loadingUpdateGroup"
              native-type="submit"
              variant="primary"
              class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
              >{{ t("Update group") }}</o-button
            >
            <o-button
              @click="confirmDeleteGroup"
              variant="danger"
              class="px-6 py-2.5 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors"
              >{{ t("Delete group") }}</o-button
            >
          </div>
        </form>
      </div>
      <o-notification
        variant="danger"
        v-for="(value, index) in errors"
        :key="index"
      >
        {{ value }}
      </o-notification>
    </section>
    <o-notification v-else-if="!loading">
      {{ t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import PictureUpload from "@/components/PictureUpload.vue";
import { GroupVisibility, MemberRole, Openness, ApprovalStatus } from "@/types/enums";
import { IGroup, usernameWithDomain, displayName } from "@/types/actor";
import { IAddress } from "@/types/address.model";
import { ServerParseError } from "@apollo/client/link/http";
import { ErrorResponse } from "@apollo/client/link/error";
import RouteName from "@/router/name";
import { buildFileFromIMedia } from "@/utils/image";
import { useAvatarMaxSize, useBannerMaxSize } from "@/composition/config";
import { useI18n } from "vue-i18n";
import { computed, ref, defineAsyncComponent, inject } from "vue";
import { useGroup, useUpdateGroup } from "@/composition/apollo/group";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { DELETE_GROUP } from "@/graphql/group";
import { useMutation } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { Dialog } from "@/plugins/dialog";
import { useHead } from "@/utils/head";
import { Notifier } from "@/plugins/notifier";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const props = defineProps<{ preferredUsername: string }>();
const preferredUsername = computed(() => props.preferredUsername);

const { currentActor } = useCurrentActorClient();

const { group, loading, onResult: onGroupResult } = useGroup(preferredUsername);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group settings")),
});

const notifier = inject<Notifier>("notifier");

const avatarFile = ref<File | null>(null);
const bannerFile = ref<File | null>(null);

const errors = ref<string[]>([]);

const showCopiedTooltip = ref(false);

const editableGroup = ref<IGroup>();

const {
  onDone,
  onError,
  mutate: updateGroup,
  loading: loadingUpdateGroup,
} = useUpdateGroup();

onDone(() => {
  notifier?.success(t("Group settings saved"));
});

onError((err) => {
  handleError(err as unknown as ErrorResponse);
});

const copyURL = async (): Promise<void> => {
  await window.navigator.clipboard.writeText(group.value?.url ?? "");
  showCopiedTooltip.value = true;
  setTimeout(() => {
    showCopiedTooltip.value = false;
  }, 2000);
};

onGroupResult(async ({ data }) => {
  if (!data) return;
  editableGroup.value = { ...data.group };
  try {
    avatarFile.value = await buildFileFromIMedia(editableGroup.value?.avatar);
    bannerFile.value = await buildFileFromIMedia(editableGroup.value?.banner);
  } catch (e) {
    // Catch errors while building media
    console.error(e);
  }
});

const buildVariables = computed(() => {
  let avatarObj = {};
  let bannerObj = {};
  const variables = { ...editableGroup.value };
  let physicalAddress;
  if (variables.physicalAddress) {
    physicalAddress = { ...variables.physicalAddress };
  } else {
    physicalAddress = variables.physicalAddress;
  }

  // eslint-disable-next-line
  // @ts-ignore
  if (variables.__typename) {
    // eslint-disable-next-line
    // @ts-ignore
    delete variables.__typename;
  }
  // eslint-disable-next-line
  // @ts-ignore
  if (physicalAddress && physicalAddress.__typename) {
    // eslint-disable-next-line
    // @ts-ignore
    delete physicalAddress.__typename;
  }
  delete physicalAddress?.pictureInfo;
  delete variables.avatar;
  delete variables.banner;

  if (avatarFile.value) {
    avatarObj = {
      avatar: {
        media: {
          name: avatarFile.value?.name,
          alt: `${editableGroup.value?.preferredUsername}'s avatar`,
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
          alt: `${editableGroup.value?.preferredUsername}'s banner`,
          file: bannerFile.value,
        },
      },
    };
  }
  return {
    id: group.value?.id ?? "",
    name: editableGroup.value?.name,
    summary: editableGroup.value?.summary,
    customUrl: editableGroup.value?.customUrl,
    visibility: editableGroup.value?.visibility,
    openness: editableGroup.value?.openness,
    manuallyApprovesFollowers: editableGroup.value?.manuallyApprovesFollowers,
    physicalAddress,
    ...avatarObj,
    ...bannerObj,
  };
});

const canShowCopyButton = computed((): boolean => {
  return window.isSecureContext;
});

const currentAddress = computed({
  get(): IAddress | null {
    return editableGroup.value?.physicalAddress ?? null;
  },
  set(address: IAddress | null) {
    if (editableGroup.value && address && (address.id || address.geom)) {
      editableGroup.value = {
        ...editableGroup.value,
        physicalAddress: address,
      };
    }
  },
});

const avatarMaxSize = useAvatarMaxSize();
const bannerMaxSize = useBannerMaxSize();

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
  errors.value.push(
    ...(err.graphQLErrors || []).map(
      ({ message }: { message: string }) => message
    )
  );
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(preferredUsername);

const dialog = inject<Dialog>("dialog");

const confirmDeleteGroup = (): void => {
  console.debug("confirm delete group", dialog);
  dialog?.confirm({
    title: t("Delete group"),
    message: t(
      "Are you sure you want to <b>completely delete</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
    ),
    confirmText: t("Delete group"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    onConfirm: () =>
      deleteGroupMutation({
        groupId: group.value?.id,
      }),
  });
};

const { mutate: deleteGroupMutation, onDone: deleteGroupDone } = useMutation<{
  deleteGroup: IGroup;
}>(DELETE_GROUP);

const router = useRouter();

deleteGroupDone(() => {
  router.push({ name: RouteName.MY_GROUPS });
});
</script>
