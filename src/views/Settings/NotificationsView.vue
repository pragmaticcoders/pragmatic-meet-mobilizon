<template>
  <div v-if="loggedUser" class="bg-white">
    <!-- Powiadomienia przeglądarki -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Browser notifications") }}
      </h2>

      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <p class="font-medium text-[17px] leading-[26px] text-[#1c1b1f]">
            {{ t("Enable browser notifications to receive real-time alerts") }}
          </p>
          <o-switch
            v-model="subscribed"
            @update:modelValue="handleWebPushToggle"
            :disabled="!webPushEnabled || !canShowWebPush"
          />
        </div>

        <o-notification
          variant="warning"
          v-if="!webPushEnabled"
          :closable="false"
        >
          {{ t("This instance hasn't got push notifications enabled.") }}
          <i18n-t keypath="Ask your instance admin to {enable_feature}.">
            <template #enable_feature>
              <a
                href="https://docs.joinmobilizon.org/administration/configure/push/"
                target="_blank"
                rel="noopener noreferer"
                class="text-[#155eef] underline"
                >{{ t("enable the feature") }}</a
              >
            </template>
          </i18n-t>
        </o-notification>

        <o-notification
          variant="danger"
          v-else-if="!canShowWebPush"
          :closable="false"
        >
          {{ t("You can't use push notifications in this browser.") }}
        </o-notification>
      </div>
    </section>

    <!-- Ustawienia powiadomień -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Notification settings") }}
      </h2>

      <p class="font-medium text-[17px] leading-[26px] text-[#1c1b1f] mb-6">
        {{
          t(
            "Select the activities for which you wish to receive an email or a push notification."
          )
        }}
      </p>

      <div class="space-y-6">
        <!-- Notification types table -->
        <div
          v-for="notificationType in notificationTypes"
          :key="notificationType.label"
          class="border border-[#cac9cb]"
        >
          <div class="bg-gray-50 px-4 py-3 border-b border-[#cac9cb]">
            <h3 class="text-[17px] text-[#1c1b1f]">
              {{ notificationType.label }}
            </h3>
          </div>

          <table class="w-full">
            <thead>
              <tr class="border-b border-[#cac9cb]">
                <th
                  class="px-4 py-2 text-left font-medium text-[15px] text-[#1c1b1f] w-20"
                >
                  {{ t("Email") }}
                </th>
                <th
                  class="px-4 py-2 text-left font-medium text-[15px] text-[#1c1b1f] w-20"
                >
                  {{ t("Push") }}
                </th>
                <th
                  class="px-4 py-2 text-left font-medium text-[15px] text-[#1c1b1f]"
                >
                  {{ t("Description") }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="subType in notificationType.subtypes"
                :key="subType.id"
                class="border-b border-gray-100 last:border-b-0"
              >
                <td class="px-4 py-3">
                  <o-checkbox
                    :modelValue="
                      notificationValues?.[subType.id]?.email?.enabled
                    "
                    @update:modelValue="
                      (e: boolean) =>
                        updateNotificationValue({
                          key: subType.id,
                          method: 'email',
                          enabled: e,
                        })
                    "
                    :disabled="
                      notificationValues?.[subType.id]?.email?.disabled
                    "
                  />
                </td>
                <td class="px-4 py-3">
                  <o-checkbox
                    :modelValue="
                      notificationValues?.[subType.id]?.push?.enabled
                    "
                    @update:modelValue="
                      (e: boolean) =>
                        updateNotificationValue({
                          key: subType.id,
                          method: 'push',
                          enabled: e,
                        })
                    "
                    :disabled="notificationValues?.[subType.id]?.push?.disabled"
                  />
                </td>
                <td class="px-4 py-3 font-medium text-[15px] text-[#1c1b1f]">
                  {{ subType.label }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Grupowanie powiadomień -->
      <div class="mt-6">
        <label class="block text-[17px] text-[#1c1b1f] mb-2">
          {{ t("Send notification e-mails") }}
        </label>
        <p class="font-medium text-[15px] text-gray-600 mb-3">
          {{
            t(
              "Announcements and mentions notifications are always sent straight away."
            )
          }}
        </p>
        <o-select
          v-model="groupNotifications"
          @update:modelValue="updateSetting({ groupNotifications })"
          class="w-full max-w-md"
        >
          <option
            v-for="(value, key) in groupNotificationsValues"
            :value="key"
            :key="key"
          >
            {{ value }}
          </option>
        </o-select>
      </div>
    </section>

    <!-- Powiadomienia o uczestnictwie -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Participation notifications") }}
      </h2>

      <p class="text-[17px] text-[#1c1b1f] mb-4">
        {{
          t(
            "Mobilizon will send you an email when the events you are attending have important changes: date and time, address, confirmation or cancellation, etc."
          )
        }}
      </p>

      <p class="font-medium text-[17px] text-[#1c1b1f] mb-4">
        {{ t("Other notification options:") }}
      </p>

      <div class="space-y-4">
        <div class="flex items-start">
          <o-checkbox
            v-model="notificationOnDay"
            @update:modelValue="updateSetting({ notificationOnDay })"
            class="mt-1"
          />
          <div class="ml-3">
            <label class="text-[17px] text-[#1c1b1f] block mb-1">
              {{ t("Notification on the day of the event") }}
            </label>
            <p class="font-medium text-[15px] text-gray-600">
              {{
                t(
                  "We use your timezone to make sure you get notifications for an event at the correct time."
                )
              }}
            </p>
            <div v-if="loggedUser.settings?.timezone" class="mt-2">
              <em class="text-[15px] text-gray-600">
                {{
                  t("Your timezone is currently set to {timezone}.", {
                    timezone: loggedUser.settings.timezone,
                  })
                }}
              </em>
              <router-link
                :to="{ name: RouteName.PREFERENCES }"
                class="text-[#155eef] underline ml-2"
              >
                {{ t("Change timezone") }}
              </router-link>
            </div>
          </div>
        </div>

        <div class="flex items-start">
          <o-checkbox
            v-model="notificationEachWeek"
            @update:modelValue="updateSetting({ notificationEachWeek })"
            class="mt-1"
          />
          <div class="ml-3">
            <label class="text-[17px] text-[#1c1b1f] block mb-1">
              {{ t("Weekly summary") }}
            </label>
            <p class="font-medium text-[15px] text-gray-600">
              {{
                t(
                  "You'll receive a weekly summary every Monday for upcoming events, if you have any."
                )
              }}
            </p>
          </div>
        </div>

        <div class="flex items-start">
          <o-checkbox
            v-model="notificationBeforeEvent"
            @update:modelValue="updateSetting({ notificationBeforeEvent })"
            class="mt-1"
          />
          <div class="ml-3">
            <label class="text-[17px] text-[#1c1b1f] block mb-1">
              {{ t("Notification before the event") }}
            </label>
            <p class="font-medium text-[15px] text-gray-600">
              {{
                t(
                  "We'll send you an email one hour before the event begins, to be sure you won't forget about it."
                )
              }}
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Powiadomienia organizatora -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Organizer notifications") }}
      </h2>

      <div>
        <label class="text-[17px] text-[#1c1b1f] block mb-2">
          {{
            t("Notifications for manually approved participations to an event")
          }}
        </label>
        <p class="font-medium text-[15px] text-gray-600 mb-4">
          {{
            t(
              "If you have opted for manual validation of participants, Mobilizon will send you an email to inform you of new participations to be processed. You can choose the frequency of these notifications below."
            )
          }}
        </p>
        <o-select
          v-model="notificationPendingParticipation"
          @update:modelValue="
            updateSetting({ notificationPendingParticipation })
          "
          class="w-full max-w-md"
        >
          <option
            v-for="(value, key) in notificationPendingParticipationValues"
            :value="key"
            :key="key"
          >
            {{ value }}
          </option>
        </o-select>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { INotificationPendingEnum } from "@/types/enums";
import {
  SET_USER_SETTINGS,
  USER_NOTIFICATIONS,
  UPDATE_ACTIVITY_SETTING,
} from "../../graphql/user";
import {
  IActivitySetting,
  IActivitySettingMethod,
  IUser,
} from "../../types/current-user.model";
import RouteName from "../../router/name";
import {
  subscribeUserToPush,
  unsubscribeUserToPush,
} from "../../services/push-subscription";
import {
  REGISTER_PUSH_MUTATION,
  UNREGISTER_PUSH_MUTATION,
} from "@/graphql/webPush";
import merge from "lodash/merge";
import { WEB_PUSH } from "@/graphql/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, onBeforeMount, onMounted, ref, watch } from "vue";
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";

type NotificationSubType = { label: string; id: string };
type NotificationType = { label: string; subtypes: NotificationSubType[] };

const { result: loggedUserResult } = useQuery<{ loggedUser: IUser }>(
  USER_NOTIFICATIONS
);
const loggedUser = computed(() => loggedUserResult.value?.loggedUser);

const { result: webPushEnabledResult } = useQuery<{
  config: Pick<IConfig, "webPush">;
}>(WEB_PUSH);

const webPushEnabled = computed(
  () => webPushEnabledResult.value?.config?.webPush.enabled
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Notifications")),
});

const notificationOnDay = ref<boolean | undefined>(true);
const notificationEachWeek = ref<boolean | undefined>(false);
const notificationBeforeEvent = ref<boolean | undefined>(false);
const notificationPendingParticipation = ref<
  INotificationPendingEnum | undefined
>(INotificationPendingEnum.NONE);
const groupNotifications = ref<INotificationPendingEnum | undefined>(
  INotificationPendingEnum.ONE_DAY
);
const notificationPendingParticipationValues = ref<Record<string, unknown>>({});
const groupNotificationsValues = ref<Record<string, unknown>>({});
const subscribed = ref(false);
const canShowWebPush = ref(false);

const defaultNotificationValues = {
  participation_event_updated: {
    email: { enabled: true, disabled: true },
    push: { enabled: true, disabled: true },
  },
  participation_event_comment: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  event_new_pending_participation: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  event_new_participation: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_created: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  discussion_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  post_published: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  post_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  resource_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  member_request: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  member_updated: {
    email: { enabled: false, disabled: false },
    push: { enabled: false, disabled: false },
  },
  user_email_password_updated: {
    email: { enabled: true, disabled: true },
    push: { enabled: false, disabled: true },
  },
  event_comment_mention: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  conversation_mention: {
    email: { enabled: true, disabled: false },
    push: { enabled: true, disabled: false },
  },
  discussion_mention: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
  event_new_comment: {
    email: { enabled: true, disabled: false },
    push: { enabled: false, disabled: false },
  },
};

const notificationTypes: NotificationType[] = [
  {
    label: t("Mentions") as string,
    subtypes: [
      {
        id: "conversation_mention",
        label: t("I was mentioned in a conversation") as string,
      },
      {
        id: "event_comment_mention",
        label: t("I was mentioned in an event comment") as string,
      },
      {
        id: "discussion_mention",
        label: t("I was mentioned in a group discussion") as string,
      },
    ],
  },
  {
    label: t("Participations") as string,
    subtypes: [
      {
        id: "participation_event_updated",
        label: t("An event I'm going to has been updated") as string,
      },
      {
        id: "participation_event_comment",
        label: t("An event I'm going to published an announcement") as string,
      },
    ],
  },
  {
    label: t("Organizers") as string,
    subtypes: [
      {
        id: "event_new_pending_participation",
        label: t(
          "An event I'm organizing has a new pending participation"
        ) as string,
      },
      {
        id: "event_new_participation",
        label: t("An event I'm organizing has a new participation") as string,
      },
      {
        id: "event_new_comment",
        label: t("An event I'm organizing has a new comment") as string,
      },
    ],
  },
  {
    label: t("Group activity") as string,
    subtypes: [
      {
        id: "event_created",
        label: t("An event from one of my groups has been published") as string,
      },
      {
        id: "event_updated",
        label: t(
          "An event from one of my groups has been updated or deleted"
        ) as string,
      },
      {
        id: "discussion_updated",
        label: t("A discussion has been created or updated") as string,
      },
      {
        id: "post_published",
        label: t("A post has been published") as string,
      },
      {
        id: "post_updated",
        label: t("A post has been updated") as string,
      },
      {
        id: "resource_updated",
        label: t("A resource has been created or updated") as string,
      },
      {
        id: "member_request",
        label: t("A member requested to join one of my groups") as string,
      },
      {
        id: "member_updated",
        label: t("A member has been updated") as string,
      },
    ],
  },
  {
    label: t("User settings") as string,
    subtypes: [
      {
        id: "user_email_password_updated",
        label: t("You changed your email or password") as string,
      },
    ],
  },
];

const userNotificationValues = computed(
  (): Record<
    string,
    Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
  > => {
    return (loggedUser.value?.activitySettings ?? []).reduce(
      (acc, activitySetting) => {
        acc[activitySetting.key] = acc[activitySetting.key] || {};
        acc[activitySetting.key][activitySetting.method] =
          acc[activitySetting.key][activitySetting.method] || {};
        acc[activitySetting.key][activitySetting.method].enabled =
          activitySetting.enabled;
        return acc;
      },
      {} as Record<
        string,
        Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
      >
    );
  }
);

const notificationValues = computed(
  (): Record<
    string,
    Record<IActivitySettingMethod, { enabled: boolean; disabled: boolean }>
  > => {
    const values = merge(
      defaultNotificationValues,
      userNotificationValues.value
    );
    for (const value in values) {
      if (!canShowWebPush.value) {
        values[value].push.disabled = true;
      }
    }
    return values;
  }
);

onMounted(async () => {
  notificationPendingParticipationValues.value = {
    [INotificationPendingEnum.NONE]: t("Disabled"),
    [INotificationPendingEnum.DIRECT]: t("Receive one email per request"),
    [INotificationPendingEnum.ONE_HOUR]: t("Hourly email summary"),
    [INotificationPendingEnum.ONE_DAY]: t("Daily email summary"),
    [INotificationPendingEnum.ONE_WEEK]: t("Weekly email summary"),
  };
  groupNotificationsValues.value = {
    [INotificationPendingEnum.NONE]: t("Disabled"),
    [INotificationPendingEnum.DIRECT]: t("Receive one email for each activity"),
    [INotificationPendingEnum.ONE_HOUR]: t("Hourly email summary"),
    [INotificationPendingEnum.ONE_DAY]: t("Daily email summary"),
    [INotificationPendingEnum.ONE_WEEK]: t("Weekly email summary"),
  };
  canShowWebPush.value = await checkCanShowWebPush();
});

watch(loggedUser, () => {
  if (loggedUser.value?.settings) {
    notificationOnDay.value = loggedUser.value.settings.notificationOnDay;
    notificationEachWeek.value = loggedUser.value.settings.notificationEachWeek;
    notificationBeforeEvent.value =
      loggedUser.value.settings.notificationBeforeEvent;
    notificationPendingParticipation.value =
      loggedUser.value.settings.notificationPendingParticipation;
    groupNotifications.value = loggedUser.value.settings.groupNotifications;
  }
});

const { mutate: updateSetting } = useMutation<{ setUserSettings: string }>(
  SET_USER_SETTINGS,
  () => ({ refetchQueries: [{ query: USER_NOTIFICATIONS }] })
);

const {
  mutate: registerPushMutation,
  onDone: registerPushMutationDone,
  onError: registerPushMutationError,
} = useMutation(REGISTER_PUSH_MUTATION);

registerPushMutationDone(() => {
  subscribed.value = true;
});

registerPushMutationError((err) => {
  console.error(err);
});

const handleWebPushToggle = async (value: boolean): Promise<void> => {
  if (value) {
    await subscribeToWebPush();
  } else {
    await unsubscribeToWebPush();
  }
};

const subscribeToWebPush = async (): Promise<void> => {
  if (canShowWebPush.value) {
    const subscription = await subscribeUserToPush();
    if (subscription) {
      const subscriptionJSON = subscription?.toJSON();
      registerPushMutation({
        endpoint: subscriptionJSON.endpoint,
        auth: subscriptionJSON?.keys?.auth,
        p256dh: subscriptionJSON?.keys?.p256dh,
      });
      subscribed.value = true;
    }
  }
};

const {
  mutate: unregisterPushMutation,
  onDone: onUnregisterPushMutationDone,
  onError: onUnregisterPushMutationError,
} = useMutation(UNREGISTER_PUSH_MUTATION);

onUnregisterPushMutationDone(({ data }) => {
  console.debug(data);
  subscribed.value = false;
});

onUnregisterPushMutationError((e) => {
  console.error(e);
});

const unsubscribeToWebPush = async (): Promise<void> => {
  const endpoint = await unsubscribeUserToPush();
  if (endpoint) {
    unregisterPushMutation({
      endpoint,
    });
  }
};

const checkCanShowWebPush = async (): Promise<boolean> => {
  try {
    if (!window.isSecureContext || !("serviceWorker" in navigator))
      return Promise.resolve(false);
    const registration = await navigator.serviceWorker.getRegistration();
    return registration !== undefined;
  } catch (e) {
    console.error(e);
    return Promise.resolve(false);
  }
};

onBeforeMount(async () => {
  subscribed.value = await isSubscribed();
});

const { mutate: updateNotificationValue } = useMutation<
  {
    updateActivitySetting: IActivitySetting;
  },
  {
    key: string;
    method: IActivitySettingMethod;
    enabled: boolean;
  }
>(UPDATE_ACTIVITY_SETTING);

const isSubscribed = async (): Promise<boolean> => {
  try {
    if (!("serviceWorker" in navigator)) return Promise.resolve(false);
    const registration = await navigator.serviceWorker.getRegistration();
    return (await registration?.pushManager?.getSubscription()) != null;
  } catch (e) {
    console.error(e);
    return Promise.resolve(false);
  }
};
</script>
