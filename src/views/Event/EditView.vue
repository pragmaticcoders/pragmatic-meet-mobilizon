<template>
  <div
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <h1 class="text-3xl font-bold text-gray-900 mb-8" v-if="isUpdate === true">
      {{ t("Update event {name}", { name: event.title }) }}
    </h1>
    <h1 class="text-3xl font-bold text-gray-900 mb-8" v-else>
      {{ t("Create a new event") }}
    </h1>

    <form ref="form" class="space-y-10">
      <section>
        <h2 class="text-xl font-semibold text-gray-900 mb-6">
          {{ t("General information") }}
        </h2>

        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">{{
            t("Headline picture")
          }}</label>
          <picture-upload
            v-model:modelValue="pictureFile"
            :textFallback="t('Headline picture')"
            :defaultImage="event.picture"
            class="w-full"
          />
        </div>

        <div class="mb-6">
          <label for="title" class="block text-sm font-medium mb-2">{{
            t("Title")
          }}</label>
          <o-input
            class="w-full"
            size="large"
            aria-required="true"
            required
            v-model="event.title"
            id="title"
            dir="auto"
            expanded
          />
          <p v-if="checkTitleLength[1]" class="text-sm text-blue-600 mt-1">
            {{ checkTitleLength[1] }}
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div v-if="orderedCategories">
            <label
              for="categoryField"
              class="block text-sm font-medium text-gray-700 my-2"
              >{{ t("Category") }}</label
            >
            <o-select
              :placeholder="t('Select a category')"
              v-model="event.category"
              id="categoryField"
              expanded
              class="w-full"
            >
              <option
                v-for="category in orderedCategories"
                :value="category.id"
                :key="category.id"
              >
                {{ category.label }}
              </option>
            </o-select>
          </div>
          <div>
            <tag-input v-model="event.tags" class="w-full" />
          </div>
        </div>
      </section>

      <div class="mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">{{
          t("Starts on…")
        }}</label>
        <event-date-picker
          :time="showStartTime"
          v-model="beginsOn"
          @blur="consistencyBeginsOnBeforeEndsOn"
          class="w-full"
        ></event-date-picker>
        <div class="mt-2">
          <o-switch v-model="showStartTime">{{
            t("Show the time when the event begins")
          }}</o-switch>
        </div>
      </div>

      <div class="mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">{{
          t("Ends on…")
        }}</label>
        <event-date-picker
          :time="showEndTime"
          v-model="endsOn"
          @blur="consistencyBeginsOnBeforeEndsOn"
          :min="beginsOn"
          class="w-full"
        ></event-date-picker>
        <div class="mt-2">
          <o-switch v-model="showEndTime">{{
            t("Show the time when the event ends")
          }}</o-switch>
        </div>
      </div>

      <p
        v-if="
          configResult?.config.longEvents &&
          configResult?.config.durationOfLongEvent > 0
        "
      >
        {{
          t(
            "Activities are disabled on this instance.|An event with a duration of more than one day will be categorized as an activity.|An event with a duration of more than {number} days will be categorized as an activity.",
            { number: configResult.config.durationOfLongEvent },
            configResult.config.durationOfLongEvent
          )
        }}
      </p>

      <o-button class="mb-6" variant="text" @click="dateSettingsIsOpen = true">
        {{ t("Timezone parameters") }}
      </o-button>

      <div class="mb-6 gap-2">
        <label class="block text-sm font-medium text-gray-700 mb-4">{{
          t("Location")
        }}</label>
        <full-address-auto-complete
          v-model="eventPhysicalAddress"
          :user-timezone="userActualTimezone"
          :disabled="event.options.isOnline"
          :allowManualDetails="true"
          :hideSelected="true"
          class="w-full mt-2"
        />
        <div class="mt-3">
          <o-switch v-model="isOnline">{{
            t("The event is fully online")
          }}</o-switch>
        </div>
      </div>

      <div class="mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">{{
          t("Description")
        }}</label>
        <editor-component
          v-if="currentActor"
          :current-actor="currentActor as IPerson"
          v-model="event.description"
          :aria-label="t('Event description body')"
          :placeholder="t('Describe your event')"
          class="w-full min-h-[200px]"
        />
      </div>

      <div class="mb-6">
        <label for="website-url" class="block text-sm font-medium mb-2">{{
          t("Website / URL")
        }}</label>
        <o-input
          icon="link"
          type="url"
          v-model="event.onlineAddress"
          placeholder="URL"
          id="website-url"
          expanded
          class="w-full"
        />
      </div>

      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-bold mb-6">{{ t("Organizers") }}</h2>

        <div v-if="features?.groups && organizerActor?.id">
          <o-field>
            <organizer-picker-wrapper
              v-model="organizerActor"
              v-model:contacts="event.contacts"
            />
          </o-field>
          <p v-if="!attributedToAGroup && organizerActorEqualToCurrentActor">
            {{
              t("The event will show as attributed to your personal profile.")
            }}
          </p>
          <p v-else-if="!attributedToAGroup">
            {{ t("The event will show as attributed to this profile.") }}
          </p>
          <p v-else>
            <span>{{
              t("The event will show as attributed to this group.")
            }}</span>
            <span
              v-if="event.contacts && event.contacts.length"
              v-html="
                ' ' +
                t(
                  '<b>{contact}</b> will be displayed as contact.',

                  {
                    contact: formatList(
                      event.contacts.map((contact) =>
                        escapeHtml(displayNameAndUsername(contact))
                      )
                    ),
                  },
                  event.contacts.length
                )
              "
            />
            <span v-else>
              {{ t("You may show some members as contacts.") }}
            </span>
          </p>
        </div>
      </section>
      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-bold mb-4">{{ t("Event metadata") }}</h2>
        <p class="text-sm text-gray-600 mb-4">
          {{
            t(
              "Integrate this event with 3rd-party tools and show metadata for the event."
            )
          }}
        </p>
        <event-metadata-list v-model="event.metadata" />
      </section>
      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-bold mb-6">
          {{ t("Who can view this event and participate") }}
        </h2>
        <fieldset class="space-y-3">
          <legend class="text-sm text-gray-600 mb-4">
            {{
              t(
                "When the event is private, you'll need to share the link around."
              )
            }}
          </legend>
          <div class="field">
            <o-radio
              v-model="event.visibility"
              name="eventVisibility"
              :native-value="EventVisibility.PUBLIC"
              >{{ t("Visible everywhere on the web (public)") }}</o-radio
            >
          </div>
          <div class="field">
            <o-radio
              v-model="event.visibility"
              name="eventVisibility"
              :native-value="EventVisibility.UNLISTED"
              >{{ t("Only accessible through link (private)") }}</o-radio
            >
          </div>
        </fieldset>
        <!-- <div class="field">
          <o-radio v-model="event.visibility"
                   name="eventVisibility"
                   :native-value="EventVisibility.PRIVATE">
             {{ t('Page limited to my group (asks for auth)') }}
          </o-radio>
        </div>-->
      </section>
      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-semibold text-gray-900 mb-6">
          {{ t("Public comment moderation") }}
        </h2>

        <fieldset>
          <legend>{{ t("Who can post a comment?") }}</legend>
          <o-field>
            <o-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.ALLOW_ALL"
              >{{ t("Allow all comments from users with accounts") }}</o-radio
            >
          </o-field>

          <!--          <div class="field">-->
          <!--            <o-radio v-model="eventOptions.commentModeration"-->
          <!--                     name="commentModeration"-->
          <!--                     :native-value="CommentModeration.MODERATED">-->
          <!--              {{ t('Moderated comments (shown after approval)') }}-->
          <!--            </o-radio>-->
          <!--          </div>-->

          <o-field>
            <o-radio
              v-model="eventOptions.commentModeration"
              name="commentModeration"
              :native-value="CommentModeration.CLOSED"
              >{{ t("Close comments for all (except for admins)") }}</o-radio
            >
          </o-field>
        </fieldset>
      </section>
      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">
          {{ t("Status") }}
        </h2>
        <p class="text-sm text-gray-600 mb-4">
          {{
            t("Does the event needs to be confirmed later or is it cancelled?")
          }}
        </p>
        <div class="space-y-3">
          <label class="flex items-start gap-3">
            <o-radio
              v-model="event.status"
              name="status"
              :native-value="EventStatus.TENTATIVE"
              class="mt-1"
            />
            <div class="flex items-center gap-2">
              <o-icon icon="calendar-question" class="text-orange-500" />
              <span>{{ t("Tentative: Will be confirmed later") }}</span>
            </div>
          </label>
          <label class="flex items-start gap-3">
            <o-radio
              v-model="event.status"
              name="status"
              :native-value="EventStatus.CONFIRMED"
              class="mt-1"
            />
            <div class="flex items-center gap-2">
              <o-icon icon="calendar-check" class="text-green-600" />
              <span>{{ t("Confirmed: Will happen") }}</span>
            </div>
          </label>
          <label class="flex items-start gap-3">
            <o-radio
              v-model="event.status"
              name="status"
              :native-value="EventStatus.CANCELLED"
              class="mt-1"
            />
            <div class="flex items-center gap-2">
              <o-icon icon="calendar-remove" class="text-red-600" />
              <span>{{ t("Cancelled: Won't happen") }}</span>
            </div>
          </label>
        </div>
      </section>

      <section
        class="my-8 p-4 bg-gray-50 border border-gray-200"
        :class="{
          'border-red-300 bg-red-50':
            props.isUpdate === false && !agreedToTerms,
        }"
      >
        <h2
          class="text-lg font-semibold mb-3"
          :class="{
            'text-red-700': props.isUpdate === false && !agreedToTerms,
          }"
        >
          {{ t("Zgody") }} <span class="text-red-500">*</span>
        </h2>
        <div class="space-y-3">
          <label
            class="flex items-start gap-3"
            :class="{
              'text-red-700': props.isUpdate === false && !agreedToTerms,
            }"
          >
            <o-checkbox
              v-model="agreedToTerms"
              class="mt-1"
              :class="{
                'border-red-300': props.isUpdate === false && !agreedToTerms,
              }"
            />
            <span class="text-sm">
              *
              {{
                t(
                  "Oświadczam, że rozumiem, iż wydarzeniem bezpłatnego korzystania z platformy Pragmatic Meet jest umieszczenie na stronie mojej społeczności widocznego logo zawierającego link prowadzący do strony"
                )
              }}
              <a
                href="https://www.pragmaticcoders.com/"
                target="_blank"
                class="text-blue-600 hover:underline"
                >Pragmatic Coders</a
              >.
            </span>
          </label>
        </div>
        <o-button
          variant="text"
          class="mt-4 text-blue-600"
          @click="downloadLogo"
        >
          <o-icon icon="inbox-arrow-down" />
          {{ t("Pobierz") }}
        </o-button>
      </section>
    </form>
  </div>
  <div
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    v-else
  >
    <o-notification variant="danger">
      {{ t("Only group moderators can create, edit and delete events.") }}
    </o-notification>
  </div>
  <o-modal
    v-model:active="dateSettingsIsOpen"
    has-modal-card
    trap-focus
    :close-button-aria-label="t('Close')"
  >
    <form class="p-3">
      <header class="">
        <h2 class="">{{ t("Timezone") }}</h2>
      </header>
      <section class="">
        <p>
          {{
            t(
              "Event timezone will default to the timezone of the event's address if there is one, or to your own timezone setting."
            )
          }}
        </p>
        <o-field expanded>
          <o-select
            :placeholder="t('Select a timezone')"
            :loading="timezoneLoading"
            v-model="timezone"
            id="timezone"
          >
            <optgroup
              :label="group"
              v-for="(groupTimezones, group) in timezones"
              :key="group"
            >
              <option
                v-for="timezone in groupTimezones"
                :value="
                  group === t('Other') ? timezone : `${group}/${timezone}`
                "
                :key="timezone"
              >
                {{ sanitizeTimezone(timezone) }}
              </option>
            </optgroup>
          </o-select>
          <o-button
            :disabled="!timezone"
            @click="timezone = null"
            class="reset-area"
            icon-left="close"
            :title="t('Clear timezone field')"
          />
        </o-field>
      </section>
      <footer class="mt-2">
        <o-button @click="dateSettingsIsOpen = false">
          {{ t("OK") }}
        </o-button>
      </footer>
    </form>
  </o-modal>
  <span ref="bottomObserver" />
  <nav
    role="navigation"
    aria-label="main navigation"
    class="bg-white border-t border-gray-200 py-4 mt-8"
    :class="{ 'sticky bottom-0 shadow-lg': showFixedNavbar }"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <div
      class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    >
      <div
        class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3"
      >
        <div
          class="text-sm text-orange-600 order-2 sm:order-1"
          v-if="props.isUpdate === false && !agreedToTerms"
        >
          * {{ t("Wymagane zgody") }}
        </div>
        <div
          class="flex flex-col sm:flex-row gap-3 sm:items-center sm:ml-auto order-1 sm:order-2"
        >
          <o-button
            variant="primary"
            size="medium"
            class="w-full sm:w-auto px-6 py-2 bg-blue-600 text-white hover:bg-blue-700"
            :disabled="saving || (props.isUpdate === false && !agreedToTerms)"
            :loading="saving"
            @click="createOrUpdatePublish"
            @keyup.enter="createOrUpdatePublish"
          >
            <span v-if="props.isUpdate === false">{{
              t("Utwórz wydarzenie")
            }}</span>
            <span v-else-if="event.draft === true">{{ t("Publish") }}</span>
            <span v-else>{{ t("Update my event") }}</span>
          </o-button>
          <o-button
            v-if="event.draft === true"
            variant="text"
            size="medium"
            class="w-full sm:w-auto px-6 py-2 border border-gray-300 hover:bg-gray-50"
            @click="createOrUpdateDraft"
            :disabled="saving || (props.isUpdate === false && !agreedToTerms)"
            :loading="saving"
          >
            <o-icon icon="content-save-outline" />
            {{ t("Zapisz szkic") }}
          </o-button>
          <o-button
            variant="text"
            size="medium"
            class="w-full sm:w-auto px-6 py-2 text-gray-600 hover:text-gray-800"
            @click="confirmGoBack"
          >
            {{ t("Anuluj") }}
          </o-button>
        </div>
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
import { getTimezoneOffset } from "date-fns-tz";
import PictureUpload from "@/components/PictureUpload.vue";
import EditorComponent from "@/components/TextEditor.vue";
import TagInput from "@/components/Event/TagInput.vue";
import EventMetadataList from "@/components/Event/EventMetadataList.vue";
import {
  NavigationGuardNext,
  onBeforeRouteLeave,
  RouteLocationNormalized,
  useRouter,
} from "vue-router";
import { formatList } from "@/utils/i18n";
import {
  ActorType,
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  GroupVisibility,
  MemberRole,
  ParticipantRole,
} from "@/types/enums";
import OrganizerPickerWrapper from "@/components/Event/OrganizerPickerWrapper.vue";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
} from "@/graphql/event";
import {
  EventModel,
  IEditableEvent,
  IEvent,
  removeTypeName,
  toEditJSON,
} from "@/types/event.model";
import { LOGGED_USER_DRAFTS } from "@/graphql/actor";
import {
  IActor,
  IGroup,
  IPerson,
  usernameWithDomain,
  displayNameAndUsername,
} from "@/types/actor";
import {
  buildFileFromIMedia,
  buildFileVariable,
  readFileAsync,
} from "@/utils/image";
import RouteName from "@/router/name";
import "intersection-observer";
import {
  ApolloCache,
  FetchResult,
  InternalRefetchQueriesInclude,
} from "@apollo/client/core";
import cloneDeep from "lodash/cloneDeep";
import { IEventOptions } from "@/types/event-options.model";
import { IAddress } from "@/types/address.model";
import { LOGGED_USER_PARTICIPATIONS } from "@/graphql/participant";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useLoggedUser } from "@/composition/apollo/user";
import {
  computed,
  inject,
  onMounted,
  ref,
  watch,
  defineAsyncComponent,
} from "vue";
import { useFetchEvent } from "@/composition/apollo/event";
import { useI18n } from "vue-i18n";
import { useGroup } from "@/composition/apollo/group";
import {
  useAnonymousParticipationConfig,
  useEventCategories,
  useFeatures,
  useTimezones,
} from "@/composition/apollo/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";
import { useOruga } from "@oruga-ui/oruga-next";
import sortBy from "lodash/sortBy";
import { escapeHtml } from "@/utils/html";
import EventDatePicker from "@/components/Event/EventDatePicker.vue";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

const { eventCategories } = useEventCategories();
const { anonymousParticipationConfig } = useAnonymousParticipationConfig();
const { currentActor } = useCurrentActorClient();
const { loggedUser } = useLoggedUser();
const { identities } = useCurrentUserIdentities();

const { features } = useFeatures();

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const { t } = useI18n({ useScope: "global" });

const props = withDefaults(
  defineProps<{
    eventId?: undefined | string;
    isUpdate?: boolean;
    isDuplicate?: boolean;
  }>(),
  { isUpdate: false, isDuplicate: false }
);

const eventId = computed(() => props.eventId);

useHead({
  title: computed(() =>
    props.isUpdate ? t("Event edition") : t("Event creation")
  ),
});

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const event = ref<IEditableEvent>(new EventModel());
const unmodifiedEvent = ref<IEditableEvent>(new EventModel());

const pictureFile = ref<File | null>(null);

const limitedPlaces = ref(false);
const showFixedNavbar = ref(true);

const observer = ref<IntersectionObserver | null>(null);
const bottomObserver = ref<HTMLElement | null>(null);

const dateSettingsIsOpen = ref(false);

const saving = ref(false);
const agreedToTerms = ref(false);

const setEventTimezoneToUserTimezoneIfUnset = () => {
  if (userTimezone.value && event.value.options.timezone == null) {
    event.value.options.timezone = userTimezone.value;
  }
};

// usefull if the page is loaded from scratch
watch(loggedUser, setEventTimezoneToUserTimezoneIfUnset);

const initializeNewEvent = () => {
  // usefull if the data is already cached
  setEventTimezoneToUserTimezoneIfUnset();

  // Default values for beginsOn and endsOn

  const roundUpTo15Minutes = (time: Date) => {
    time.setUTCMilliseconds(
      Math.round(time.getUTCMilliseconds() / 1000) * 1000
    );
    time.setUTCSeconds(Math.round(time.getUTCSeconds() / 60) * 60);
    time.setUTCMinutes(Math.round(time.getUTCMinutes() / 15) * 15);
    return time;
  };

  const now = roundUpTo15Minutes(new Date());
  const end = new Date(now.valueOf());

  end.setUTCHours(now.getUTCHours() + 3);

  beginsOn.value = now;
  endsOn.value = end;

  // Default values for showStartTime and showEndTime
  showStartTime.value = false;
  showEndTime.value = false;

  // Default values for hideParticipants
  hideParticipants.value = true;
};

const organizerActor = computed({
  get(): IActor | undefined {
    if (event.value?.attributedTo?.id) {
      return event.value.attributedTo;
    }
    if (event.value?.organizerActor?.id) {
      return event.value.organizerActor;
    }
    return currentActor.value;
  },
  set(actor: IActor | undefined) {
    if (actor?.type === ActorType.GROUP) {
      event.value.attributedTo = actor as IGroup;
      event.value.organizerActor = currentActor.value;
    } else {
      event.value.attributedTo = undefined;
      event.value.organizerActor = actor;
    }
  },
});

const attributedToAGroup = computed((): boolean => {
  return event.value.attributedTo?.id !== undefined;
});

const eventOptions = computed({
  get(): IEventOptions {
    return removeTypeName(cloneDeep(event.value.options));
  },
  set(options: IEventOptions) {
    event.value.options = options;
  },
});

onMounted(async () => {
  observer.value = new IntersectionObserver(
    (entries) => {
      // eslint-disable-next-line no-restricted-syntax
      for (const entry of entries) {
        if (entry) {
          showFixedNavbar.value = !entry.isIntersecting;
        }
      }
    },
    {
      rootMargin: "-50px 0px -50px",
    }
  );
  if (bottomObserver.value) {
    observer.value.observe(bottomObserver.value);
  }

  pictureFile.value = await buildFileFromIMedia(event.value.picture);
  limitedPlaces.value = eventOptions.value.maximumAttendeeCapacity > 0;
  if (!(props.isUpdate || props.isDuplicate)) {
    initializeNewEvent();
  } else {
    event.value = new EventModel({
      ...event.value,
      options: cloneDeep(event.value.options),
      description: event.value.description || "",
    });
  }
  unmodifiedEvent.value = cloneDeep(event.value);
});

const createOrUpdateDraft = (e: Event): void => {
  e.preventDefault();
  if (validateForm()) {
    if (eventId.value && !props.isDuplicate) {
      updateEvent();
    } else {
      createEvent();
    }
  }
};

const createOrUpdatePublish = (e: Event): void => {
  e.preventDefault();
  if (validateForm()) {
    event.value.draft = false;
    createOrUpdateDraft(e);
  }
};

const form = ref<HTMLFormElement | null>(null);

const router = useRouter();

const validateForm = () => {
  if (!form.value) return;

  // Check if agreement is ticked (only for new events, not drafts or updates)
  if (props.isUpdate === false && !agreedToTerms.value) {
    notification.open({
      message: t("Wymagane zgody"),
      variant: "danger",
      position: "bottom-right",
      duration: 3000,
    });
    return false;
  }

  if (form.value.checkValidity()) {
    return true;
  }
  form.value.reportValidity();
  return false;
};

const {
  mutate: createEventMutation,
  onDone: onCreateEventMutationDone,
  onError: onCreateEventMutationError,
} = useMutation<{ createEvent: IEvent }>(CREATE_EVENT, () => ({
  update: (
    store: ApolloCache<{ createEvent: IEvent }>,
    { data: updatedData }: FetchResult
  ) => postCreateOrUpdate(store, updatedData?.createEvent),
  refetchQueries: ({ data: updatedData }: FetchResult) =>
    postRefetchQueries(updatedData?.createEvent),
}));

const { notification } = useOruga();

onCreateEventMutationDone(async ({ data }) => {
  notification.open({
    message: (event.value.draft
      ? t("The event has been created as a draft")
      : t("The event has been published")) as string,
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
  if (data?.createEvent) {
    await router.push({
      name: "Event",
      params: { uuid: data.createEvent.uuid },
    });
  }
});

onCreateEventMutationError((err) => {
  saving.value = false;
  console.error(err);
  handleError(err);
});

const createEvent = async (): Promise<void> => {
  saving.value = true;
  const variables = await buildVariables();

  createEventMutation(variables);
};

const {
  mutate: editEventMutation,
  onDone: onEditEventMutationDone,
  onError: onEditEventMutationError,
} = useMutation(EDIT_EVENT, () => ({
  update: (
    store: ApolloCache<{ updateEvent: IEvent }>,
    { data: updatedData }: FetchResult
  ) => postCreateOrUpdate(store, updatedData?.updateEvent),
  refetchQueries: ({ data }: FetchResult) =>
    postRefetchQueries(data?.updateEvent),
}));

onEditEventMutationDone(() => {
  notification.open({
    message: updateEventMessage.value,
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
  return router.push({
    name: "Event",
    params: { uuid: props.eventId as string },
  });
});

onEditEventMutationError((err) => {
  saving.value = false;
  handleError(err);
});

const updateEvent = async (): Promise<void> => {
  saving.value = true;
  const variables = await buildVariables();
  console.debug("update event", variables);
  editEventMutation(variables);
};

const hasCurrentActorPermissionsToEdit = computed((): boolean => {
  return !(
    props.eventId &&
    event.value?.organizerActor?.id !== undefined &&
    !identities.value
      ?.map(({ id }) => id)
      .includes(event.value?.organizerActor?.id) &&
    !hasGroupPrivileges.value
  );
});

const hasGroupPrivileges = computed((): boolean => {
  return (
    person.value?.memberships?.total !== undefined &&
    person.value?.memberships?.total > 0 &&
    [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(
      person.value?.memberships?.elements[0].role
    )
  );
});

const updateEventMessage = computed((): string => {
  if (unmodifiedEvent.value.draft && !event.value.draft)
    return t("The event has been updated and published") as string;
  return (
    event.value.draft
      ? t("The draft event has been updated")
      : t("The event has been updated")
  ) as string;
});

const notifier = inject<Notifier>("notifier");

const handleError = (err: any) => {
  console.error(err);

  if (err.graphQLErrors !== undefined) {
    err.graphQLErrors.forEach(
      ({
        message,
        field,
      }: {
        message: string | { slug?: string[] }[];
        field: string;
      }) => {
        if (
          field === "tags" &&
          Array.isArray(message) &&
          message.some((msg) => msg.slug)
        ) {
          const finalMsg = message.find((msg) => msg.slug?.[0]);
          notifier?.error(
            t("Error while adding tag: {error}", { error: finalMsg?.slug?.[0] })
          );
        } else if (typeof message === "string") {
          notifier?.error(message);
        }
      }
    );
  }
};

/**
 * Put in cache the updated or created event.
 * If the event is not a draft anymore, also put in cache the participation
 */
const postCreateOrUpdate = (store: any, updatedEvent: IEvent) => {
  const resultEvent: IEvent = { ...updatedEvent };
  if (!updatedEvent.draft) {
    store.writeQuery({
      query: EVENT_PERSON_PARTICIPATION,
      variables: {
        eventId: resultEvent.id,
        name: resultEvent.organizerActor?.preferredUsername,
      },
      data: {
        person: {
          __typename: "Person",
          id: resultEvent?.organizerActor?.id,
          participations: {
            __typename: "PaginatedParticipantList",
            total: 1,
            elements: [
              {
                __typename: "Participant",
                id: "unknown",
                role: ParticipantRole.CREATOR,
                actor: {
                  __typename: "Actor",
                  id: resultEvent?.organizerActor?.id,
                },
                event: {
                  __typename: "Event",
                  id: resultEvent.id,
                },
              },
            ],
          },
        },
      },
    });
  }
};

/**
 * Refresh drafts or participation cache depending if the event is still draft or not
 */
const postRefetchQueries = (
  updatedEvent: IEvent
): InternalRefetchQueriesInclude => {
  if (updatedEvent.draft) {
    return [
      {
        query: LOGGED_USER_DRAFTS,
      },
    ];
  }
  return [
    {
      query: LOGGED_USER_PARTICIPATIONS,
      variables: {
        afterDateTime: new Date(),
      },
    },
  ];
};

const organizerActorEqualToCurrentActor = computed((): boolean => {
  return (
    currentActor.value?.id !== undefined &&
    organizerActor.value?.id === currentActor.value?.id
  );
});

/**
 * Build variables for Event GraphQL creation query
 */
const buildVariables = async () => {
  let res = {
    ...toEditJSON(new EventModel(event.value)),
    options: eventOptions.value,
  };

  const localOrganizerActor = event.value?.organizerActor?.id
    ? event.value.organizerActor
    : organizerActor.value;
  if (organizerActor.value) {
    res = { ...res, organizerActorId: localOrganizerActor?.id };
  }
  const attributedToId = event.value?.attributedTo?.id
    ? event.value?.attributedTo.id
    : null;
  res = { ...res, attributedToId };

  if (pictureFile.value) {
    const pictureObj = buildFileVariable(pictureFile.value, "picture");
    res = { ...res, ...pictureObj };
  }

  try {
    if (event.value?.picture && pictureFile.value) {
      const oldPictureFile = (await buildFileFromIMedia(
        event.value?.picture
      )) as File;
      const oldPictureFileContent = await readFileAsync(oldPictureFile);
      const newPictureFileContent = await readFileAsync(
        pictureFile.value as File
      );
      if (oldPictureFileContent === newPictureFileContent) {
        res.picture = { mediaId: event.value?.picture?.uuid };
      }
    }
    console.debug("builded variables", res);
  } catch (e) {
    console.error(e);
  }
  return res;
};

watch(limitedPlaces, () => {
  if (!limitedPlaces.value) {
    eventOptions.value.maximumAttendeeCapacity = 0;
    eventOptions.value.remainingAttendeeCapacity = 0;
    eventOptions.value.showRemainingAttendeeCapacity = false;
  } else {
    eventOptions.value.maximumAttendeeCapacity =
      eventOptions.value.maximumAttendeeCapacity ||
      DEFAULT_LIMIT_NUMBER_OF_PLACES;
  }
});

const needsApproval = computed({
  get(): boolean {
    return event.value?.joinOptions == EventJoinOptions.RESTRICTED;
  },
  set(value: boolean) {
    if (value === true) {
      event.value.joinOptions = EventJoinOptions.RESTRICTED;
    } else {
      event.value.joinOptions = EventJoinOptions.FREE;
    }
  },
});

const hideParticipants = computed({
  get(): boolean {
    return event.value?.options.hideNumberOfParticipants;
  },
  set(value: boolean) {
    event.value.options.hideNumberOfParticipants = value;
  },
});

const checkTitleLength = computed((): Array<string | undefined> => {
  return event.value.title.length > 80
    ? ["info", t("The event title will be ellipsed.")]
    : [undefined, undefined];
});

const dialog = inject<Dialog>("dialog");

/**
 * Confirm cancel
 */
const confirmGoElsewhere = (): Promise<boolean> => {
  // TODO: Make calculation of changes work again and bring this back
  // If the event wasn't modified, no need to warn
  // if (!this.isEventModified) {
  //   return Promise.resolve(true);
  // }
  const title: string = props.isUpdate
    ? t("Cancel edition")
    : t("Cancel creation");
  const message: string = props.isUpdate
    ? t(
        "Are you sure you want to cancel the event edition? You'll lose all modifications.",
        { title: event.value?.title }
      )
    : t(
        "Are you sure you want to cancel the event creation? You'll lose all modifications.",
        { title: event.value?.title }
      );

  return new Promise((resolve) => {
    dialog?.confirm({
      title,
      message,
      confirmText: t("Abandon editing") as string,
      cancelText: t("Continue editing") as string,
      variant: "danger",
      hasIcon: true,
      onConfirm: () => resolve(true),
      onCancel: () => resolve(false),
    });
  });
};

/**
 * Download the Pragmatic Coders logo zip file
 */
const downloadLogo = (): void => {
  const link = document.createElement("a");
  link.href = "/Logo-Pragmatic-Coders.zip";
  link.download = "Logo-Pragmatic-Coders.zip";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Confirm cancel
 */
const confirmGoBack = (): void => {
  router.go(-1);
};

onBeforeRouteLeave(
  async (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    next: NavigationGuardNext
  ) => {
    if (to.name === RouteName.EVENT) return next();
    if (await confirmGoElsewhere()) {
      return next();
    }
    return next(false);
  }
);

const showStartTime = computed({
  get(): boolean {
    return event.value.options.showStartTime;
  },
  set(newShowStartTime: boolean) {
    event.value.options = {
      ...event.value.options,
      showStartTime: newShowStartTime,
    };
  },
});

const showEndTime = computed({
  get(): boolean {
    return event.value.options.showEndTime;
  },
  set(newshowEndTime: boolean) {
    event.value.options = {
      ...event.value.options,
      showEndTime: newshowEndTime,
    };
  },
});

const beginsOn = ref(new Date());
const endsOn = ref(new Date());

const updateEventDateRelatedToTimezone = () => {
  // update event.value.beginsOn taking care of timezone
  if (beginsOn.value) {
    const dateBeginsOn = new Date(beginsOn.value.getTime());
    dateBeginsOn.setUTCMinutes(dateBeginsOn.getUTCMinutes() - tzOffset.value);
    event.value.beginsOn = dateBeginsOn.toISOString();
  }

  if (endsOn.value) {
    // update event.value.endsOn taking care of timezone
    const dateEndsOn = new Date(endsOn.value.getTime());
    dateEndsOn.setUTCMinutes(dateEndsOn.getUTCMinutes() - tzOffset.value);
    event.value.endsOn = dateEndsOn.toISOString();
  }
};

watch(beginsOn, (newBeginsOn) => {
  if (!newBeginsOn) {
    event.value.beginsOn = null;
    return;
  }

  // usefull for comparaison
  newBeginsOn.setUTCSeconds(0);
  newBeginsOn.setUTCMilliseconds(0);

  // update event.value.beginsOn taking care of timezone
  updateEventDateRelatedToTimezone();
});

watch(endsOn, (newEndsOn) => {
  if (!newEndsOn) {
    event.value.endsOn = null;
    return;
  }

  // usefull for comparaison
  newEndsOn.setUTCSeconds(0);
  newEndsOn.setUTCMilliseconds(0);

  // update event.value.endsOn taking care of timezone
  updateEventDateRelatedToTimezone();
});

/*
For endsOn, we need to check consistencyBeginsOnBeforeEndsOn() at blur
because the datetime-local component update itself immediately
Ex : your event start at 10:00 and stops at 12:00
To type "10" hours, you will first have "1" hours, then "10" hours
So you cannot check consistensy in real time, only onBlur because of the moment we falsely have "1:00"
 */
const consistencyBeginsOnBeforeEndsOn = () => {
  // Update endsOn to make sure endsOn is later than beginsOn
  if (endsOn.value && beginsOn.value && endsOn.value <= beginsOn.value) {
    const newEndsOn = new Date(beginsOn.value);
    newEndsOn.setUTCHours(beginsOn.value.getUTCHours() + 1);
    endsOn.value = newEndsOn;
  }
};

const { timezones: rawTimezones, loading: timezoneLoading } = useTimezones();

const timezones = computed((): Record<string, string[]> => {
  return (rawTimezones.value || []).reduce(
    (acc: { [key: string]: Array<string> }, val: string) => {
      const components = val.split("/");
      const [prefix, suffix] = [
        components.shift() as string,
        components.join("/"),
      ];
      const pushOrCreate = (
        acc2: { [key: string]: Array<string> },
        prefix2: string,
        suffix2: string
      ) => {
        // eslint-disable-next-line no-param-reassign
        (acc2[prefix2] = acc2[prefix2] || []).push(suffix2);
        return acc2;
      };
      if (suffix) {
        return pushOrCreate(acc, prefix, suffix);
      }
      return pushOrCreate(acc, t("Other") as string, prefix);
    },
    {}
  );
});

// eslint-disable-next-line class-methods-use-this
const sanitizeTimezone = (timezone: string): string => {
  return timezone
    .split("_")
    .join(" ")
    .replace("St ", "St. ")
    .split("/")
    .join(" - ");
};

const timezone = computed({
  get(): string | null {
    return event.value.options.timezone;
  },
  set(newTimezone: string | null) {
    event.value.options = {
      ...event.value.options,
      timezone: newTimezone,
    };
  },
});

// Timezone specified in user settings
const userTimezone = computed((): string | undefined => {
  return loggedUser.value?.settings?.timezone;
});

const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

// Timezone specified in user settings or local timezone browser if unavailable
const userActualTimezone = computed((): string => {
  if (userTimezone.value) {
    return userTimezone.value;
  }
  return browserTimeZone;
});

const tzOffset = computed((): number => {
  if (!timezone.value) {
    return 0;
  }

  const date = new Date();

  // diff between UTC and selected timezone
  // example: Asia/Shanghai is + 8 hours
  const eventUTCOffset = getTimezoneOffset(timezone.value, date);

  // diff between UTC and local browser timezone
  // example: Europe/Paris is + 1 hour (or +2 depending of daylight saving time)
  const localUTCOffset = getTimezoneOffset(browserTimeZone, date);

  // example : offset is 8-1=7
  return (eventUTCOffset - localUTCOffset) / (60 * 1000);
});

watch(tzOffset, () => {
  // tzOffset has been changed, we need to update the event dates
  updateEventDateRelatedToTimezone();
});

const eventPhysicalAddress = computed({
  get(): IAddress | null {
    return event.value.physicalAddress;
  },
  set(address: IAddress | null) {
    if (address && address.timezone) {
      timezone.value = address.timezone;
    }
    event.value.physicalAddress = address;
  },
});

const isOnline = computed({
  get(): boolean {
    return event.value.options.isOnline;
  },
  set(newIsOnline: boolean) {
    event.value.options = {
      ...event.value.options,
      isOnline: newIsOnline,
    };
  },
});

watch(isOnline, (newIsOnline) => {
  if (newIsOnline === true) {
    eventPhysicalAddress.value = null;
  }
});

const maximumAttendeeCapacity = computed({
  get(): string {
    return eventOptions.value.maximumAttendeeCapacity.toString();
  },
  set(newMaximumAttendeeCapacity: string) {
    eventOptions.value.maximumAttendeeCapacity = parseInt(
      newMaximumAttendeeCapacity
    );
  },
});

const { event: fetchedEvent, onResult: onFetchEventResult } = useFetchEvent(
  eventId.value
);

// update the date components if the event changed (after fetching it, for example)
watch(event, () => {
  if (event.value.beginsOn) {
    const date = new Date(event.value.beginsOn);
    date.setUTCMinutes(date.getUTCMinutes() + tzOffset.value);
    beginsOn.value = date;
  }
  if (event.value.endsOn) {
    const date = new Date(event.value.endsOn);
    date.setUTCMinutes(date.getUTCMinutes() + tzOffset.value);
    endsOn.value = date;
  }
});

watch(
  fetchedEvent,
  () => {
    if (!fetchedEvent.value) return;
    event.value = { ...fetchedEvent.value };
  },
  { immediate: true }
);

onFetchEventResult((result) => {
  if (!result.loading && result.data?.event) {
    event.value = { ...result.data?.event };
  }
});

const groupFederatedUsername = computed(() =>
  usernameWithDomain(fetchedEvent.value?.attributedTo)
);

const { person } = usePersonStatusGroup(groupFederatedUsername);

const { group } = useGroup(groupFederatedUsername);

watch(group, () => {
  if (!props.isUpdate && group.value?.visibility == GroupVisibility.UNLISTED) {
    event.value.visibility = EventVisibility.UNLISTED;
  }
  if (!props.isUpdate && group.value?.visibility == GroupVisibility.PUBLIC) {
    event.value.visibility = EventVisibility.PUBLIC;
  }
});

const orderedCategories = computed(() => {
  if (!eventCategories.value) return undefined;
  return sortBy(eventCategories.value, ["label"]);
});

const RegisterOption = {
  MOBILIZON: "mobilizon",
  EXTERNAL: "external",
};

const registerOption = computed({
  get() {
    return event.value?.joinOptions === EventJoinOptions.EXTERNAL
      ? RegisterOption.EXTERNAL
      : RegisterOption.MOBILIZON;
  },
  set(newValue) {
    if (newValue === RegisterOption.EXTERNAL) {
      event.value.joinOptions = EventJoinOptions.EXTERNAL;
    } else {
      event.value.joinOptions = EventJoinOptions.FREE;
    }
  },
});
</script>

<style lang="scss">
.radio-buttons input[type="radio"] {
  & {
    display: none;
  }

  & + span.radio-label {
    padding-left: 3px;
  }
}

#status .o-field--addons {
  flex-wrap: wrap;
  gap: 5px;
}

#status .o-field--addons > label {
  flex: 1 1 0;
  margin: 0;
}
#status .o-field--addons .mr-2 {
  margin: 0;
}

#status .o-field--addons > label .o-radio__label {
  width: 100%;
}

@media screen and (max-width: 700px) {
  #status .o-field--addons {
    flex-direction: column;
  }
}
</style>
