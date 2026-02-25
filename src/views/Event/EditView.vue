<template>
  <div
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <h1 class="text-3xl font-bold text-gray-900 mb-8" v-if="isUpdate === true">
      {{ t("Update event {name}", { name: event.title }) }}
    </h1>
    <h1 v-else class="text-3xl font-bold text-gray-900 mb-8">
      {{ t("Create a new event") }}
    </h1>

    <!-- Group Selector (only show when creating new event, not updating) -->
    <div v-if="!isUpdate" class="mb-8">
      <h2 class="text-xl font-semibold text-gray-900 mb-6">
        {{ t("Event organizer") }}
      </h2>
      <p class="text-sm text-gray-600 mb-4">
        {{ t("Choose who will organize this event") }}
      </p>

      <!-- Selected organizer preview -->
      <div
        class="flex items-center gap-3 mb-3 p-3 bg-gray-50 rounded-lg border border-gray-200"
      >
        <img
          v-if="selectedOrganizerData?.avatar?.url"
          :src="selectedOrganizerData.avatar.url"
          :alt="
            selectedOrganizerData.name ||
            selectedOrganizerData.preferredUsername
          "
          class="w-10 h-10 rounded-full object-cover border-2 border-white shadow-sm"
        />
        <div
          v-else
          class="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-semibold shadow-sm"
        >
          {{
            (selectedOrganizerData?.name ||
              selectedOrganizerData?.preferredUsername ||
              "P")[0].toUpperCase()
          }}
        </div>
        <div class="flex-1">
          <p class="text-sm font-semibold text-gray-900">
            {{
              selectedOrganizerData?.name ||
              selectedOrganizerData?.preferredUsername ||
              t("Personal event")
            }}
          </p>
          <p
            v-if="selectedOrganizer !== 'personal'"
            class="text-xs text-gray-500"
          >
            @{{ selectedOrganizerData?.preferredUsername }}
          </p>
        </div>
      </div>

      <div class="relative w-full md:w-1/2">
        <select
          id="eventOrganizer"
          v-model="selectedOrganizer"
          class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 appearance-none bg-white !bg-none"
        >
          <option value="personal">
            {{ t("Personal event") }}
          </option>
          <option
            v-for="group in administeredGroups"
            :key="group.id"
            :value="group.id"
          >
            {{ t("Group:") }} {{ group.name || group.preferredUsername }}
          </option>
        </select>
        <div
          class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700"
        >
          <svg
            class="fill-current h-4 w-4"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
          >
            <path
              d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"
            />
          </svg>
        </div>
      </div>
    </div>

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
          <p
            v-if="checkTitleLength[1]"
            :class="{
              'text-sm mt-1': true,
              'text-blue-600': checkTitleLength[0] === 'info',
              'text-red-600': checkTitleLength[0] === 'danger',
            }"
          >
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

      <div class="mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">{{
          t("Timezone")
        }}</label>
        <div
          class="flex items-center justify-between p-4 border border-gray-200 rounded-lg bg-gradient-to-r from-blue-50 to-indigo-50 hover:from-blue-100 hover:to-indigo-100 transition-all duration-200 shadow-sm"
        >
          <div class="flex items-center gap-3">
            <div
              class="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center shadow-md"
            >
              <o-icon icon="earth" size="small" class="text-white" />
            </div>
            <div>
              <span class="text-sm font-medium text-gray-800">
                {{ currentTimezoneDisplay }}
              </span>
              <p class="text-xs text-gray-500 mt-0.5">
                {{ t("Current event timezone") }}
              </p>
            </div>
          </div>
          <o-button
            variant="primary"
            size="small"
            outlined
            @click="dateSettingsIsOpen = true"
            class="!px-4 !py-2 hover:scale-105 transition-transform duration-200"
          >
            {{ t("Change") }}
          </o-button>
        </div>
      </div>

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
          {{ t("Participation") }}
        </h2>

        <div class="space-y-6">
          <div>
            <o-switch v-model="limitedPlaces">
              {{ t("Limit the number of participants") }}
            </o-switch>
          </div>

          <div v-if="limitedPlaces" class="space-y-4 ml-6">
            <div>
              <label
                for="maximumAttendeeCapacity"
                class="block text-sm font-medium text-gray-700 mb-2"
              >
                {{ t("Maximum number of participants") }}
              </label>
              <o-input
                id="maximumAttendeeCapacity"
                v-model="maximumAttendeeCapacity"
                type="number"
                min="1"
                class="w-32"
                placeholder="Enter limit"
              />
              <p
                v-if="currentParticipantCount > 0"
                class="text-sm mt-1"
                :class="
                  currentParticipantCount >
                  event.options.maximumAttendeeCapacity
                    ? 'text-amber-700'
                    : 'text-gray-500'
                "
              >
                {{
                  currentParticipantCount >
                  event.options.maximumAttendeeCapacity
                    ? t("Participant count exceeds limit.")
                    : t(
                        "Current participants: {count}. Limit cannot be lower than current participants.",
                        { count: currentParticipantCount }
                      )
                }}
              </p>
            </div>

            <div>
              <o-switch v-model="enableWaitlist">
                {{ t("Enable waitlist when event is full") }}
              </o-switch>
              <p class="text-sm text-gray-500 mt-1">
                {{
                  t(
                    "When enabled, participants can join a waitlist if the event reaches capacity. They'll be notified if spots become available."
                  )
                }}
              </p>

              <div v-if="enableWaitlist" class="ml-6 mt-4 space-y-4">
                <!-- Waitlist-only mode toggle -->
                <div>
                  <o-switch v-model="waitlistOnly">
                    {{ t("Waitlist-only mode") }}
                  </o-switch>
                  <p class="text-sm text-gray-500 mt-1">
                    {{
                      t(
                        "All participants must join the waitlist first. You will need to manually approve each participant."
                      )
                    }}
                  </p>
                </div>

                <!-- Show auto-promote options only when NOT in waitlist-only mode -->
                <div v-if="!waitlistOnly" class="space-y-3">
                  <label class="flex items-start gap-3">
                    <o-radio
                      v-model="waitlistAutoPromote"
                      name="waitlistMode"
                      :native-value="true"
                      class="mt-1"
                    />
                    <div>
                      <span class="font-medium">{{
                        t("Automatically promote from waitlist")
                      }}</span>
                      <p class="text-sm text-gray-500 mt-1">
                        {{
                          t(
                            "Participants from the waitlist will automatically join the event when a spot becomes available (first-come, first-served)"
                          )
                        }}
                      </p>
                    </div>
                  </label>

                  <label class="flex items-start gap-3">
                    <o-radio
                      v-model="waitlistAutoPromote"
                      name="waitlistMode"
                      :native-value="false"
                      class="mt-1"
                    />
                    <div>
                      <span class="font-medium">{{
                        t("Require manual approval")
                      }}</span>
                      <p class="text-sm text-gray-500 mt-1">
                        {{
                          t(
                            "You will need to manually approve participants from the waitlist, even when spots become available"
                          )
                        }}
                      </p>
                    </div>
                  </label>
                </div>

                <!-- Message when waitlist-only is enabled -->
                <div
                  v-else
                  class="bg-blue-50 border border-blue-200 rounded-lg p-3"
                >
                  <p class="text-sm text-blue-800">
                    {{
                      t(
                        "In waitlist-only mode, you must manually promote participants. Automatic promotion is not available."
                      )
                    }}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6">
            <o-switch v-model="blockNewRegistrations">
              {{ t("Block new registrations") }}
            </o-switch>
            <p class="text-sm text-gray-500 mt-1">
              {{
                t(
                  "When enabled, new participants cannot join this event. Existing participants remain unaffected."
                )
              }}
            </p>
          </div>
        </div>
      </section>

      <section class="border-t pt-8 mt-8">
        <h2 class="text-xl font-semibold text-gray-900 mb-6">
          {{ t("Public comment moderation") }}
        </h2>

        <fieldset>
          <legend>{{ t("Who can post a comment?") }}</legend>
          <o-field>
            <o-radio
              v-model="event.options.commentModeration"
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
              v-model="event.options.commentModeration"
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
            props.isUpdate === true
              ? t(
                  "Does the event needs to be confirmed later or is it cancelled?"
                )
              : t("Does the event needs to be confirmed later?")
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
          <label v-if="props.isUpdate === true" class="flex items-start gap-3">
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
    </form>
  </div>
  <div
    class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    v-else
  >
    <o-notification variant="danger">
      {{ missingActorMessage }}
    </o-notification>
    <div v-if="!currentActor?.id && !props.eventId" class="mt-4">
      <o-button
        variant="primary"
        @click="$router.push('/identity/create')"
        class="mr-3"
      >
        {{ t("Create Profile") }}
      </o-button>
      <o-button variant="text" @click="$router.push('/')">
        {{ t("Go to Home") }}
      </o-button>
    </div>
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
    :class="{ 'sm:sticky sm:bottom-0 shadow-lg': showFixedNavbar }"
    v-if="hasCurrentActorPermissionsToEdit"
  >
    <div
      class="max-w-screen-xl mx-auto pl-4 md:pl-16 pr-4 md:pr-[20%] lg:pr-[20%]"
    >
      <div
        class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3"
      >
        <div
          class="flex flex-col sm:flex-row gap-3 sm:items-center sm:ml-auto order-1 sm:order-2"
        >
          <o-button
            variant="primary"
            size="medium"
            class="w-full sm:w-auto px-6 py-2 bg-blue-600 text-white hover:bg-blue-700"
            :disabled="saving"
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
            :disabled="saving"
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
  useRoute,
} from "vue-router";
import {
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  GroupVisibility,
  MemberRole,
  ParticipantRole,
} from "@/types/enums";
import {
  CREATE_EVENT,
  EDIT_EVENT,
  EVENT_PERSON_PARTICIPATION,
} from "@/graphql/event";
import { HOME_USER_QUERIES } from "@/graphql/home";
import { SEARCH_CALENDAR_EVENTS } from "@/graphql/search";
import {
  EventModel,
  IEditableEvent,
  IEvent,
  toEditJSON,
} from "@/types/event.model";
import { LOGGED_USER_DRAFTS, LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { LOGGED_USER_PARTICIPATIONS } from "@/graphql/participant";
import { IMember } from "@/types/actor/member.model";
import { IGroup, IPerson, usernameWithDomain } from "@/types/actor";
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
import { IAddress } from "@/types/address.model";
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
import { useEventCategories, useTimezones } from "@/composition/apollo/config";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useHead } from "@/utils/head";
import { useOruga } from "@oruga-ui/oruga-next";
import sortBy from "lodash/sortBy";
import EventDatePicker from "@/components/Event/EventDatePicker.vue";
import { FETCH_GROUP_PUBLIC } from "@/graphql/group";

const DEFAULT_LIMIT_NUMBER_OF_PLACES = 10;

const { eventCategories } = useEventCategories();
const { currentActor } = useCurrentActorClient();
const { loggedUser } = useLoggedUser();
const { identities } = useCurrentUserIdentities();

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

const event = ref<IEditableEvent>(new EventModel());
const unmodifiedEvent = ref<IEditableEvent>(new EventModel());

const pictureFile = ref<File | null>(null);

// Separate state to track if user wants to limit places (independent of current capacity value)
const limitedPlacesEnabled = ref(false);

const limitedPlaces = computed({
  get(): boolean {
    return limitedPlacesEnabled.value;
  },
  set(value: boolean) {
    limitedPlacesEnabled.value = value;
    if (!value) {
      event.value.options = {
        ...event.value.options,
        maximumAttendeeCapacity: 0,
        remainingAttendeeCapacity: 0,
        showRemainingAttendeeCapacity: false,
      };
    } else if (event.value.options.maximumAttendeeCapacity === 0) {
      // Only set default if capacity is currently 0
      event.value.options = {
        ...event.value.options,
        maximumAttendeeCapacity: DEFAULT_LIMIT_NUMBER_OF_PLACES,
      };
    }
  },
});
const showFixedNavbar = ref(true);

const observer = ref<IntersectionObserver | null>(null);
const bottomObserver = ref<HTMLElement | null>(null);

const dateSettingsIsOpen = ref(false);

const saving = ref(false);

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

  // Set default category if not already set
  if (!event.value.category) {
    event.value.category = "SOCIAL_ACTIVITIES";
  }
};

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
  limitedPlacesEnabled.value =
    (event.value?.options?.maximumAttendeeCapacity || 0) > 0;
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
const route = useRoute();

// Watch for query params to set up group attribution
const actorId = computed(() => {
  const id = route.query.actorId as string | undefined;
  return id;
});

const groupUsername = computed(() => {
  const username = route.query.groupUsername as string | undefined;
  return username;
});

// Fetch group data using groupUsername (same as group pages for proper permissions)
const { result: groupResult, error: groupError } = useQuery<{ group: IGroup }>(
  FETCH_GROUP_PUBLIC,
  () => ({ name: groupUsername.value }),
  () => ({
    enabled: !!groupUsername.value,
    fetchPolicy: "cache-and-network",
  })
);

// Watch for group data and set up event attribution
watch(
  [groupResult, groupError],
  ([newGroupResult, error]) => {
    if (error) {
      console.error("Group query error:", error);
      return;
    }

    if (
      newGroupResult?.group &&
      actorId.value &&
      !(props.isUpdate || props.isDuplicate)
    ) {
      const group = newGroupResult.group;

      // Ensure we have the group ID set properly (should match actorId from route)
      if (!group.id) {
        group.id = actorId.value;
      }

      event.value.attributedTo = group;
      event.value.organizerActor = currentActor.value;
    }
  },
  { immediate: true }
);

// Fetch user's groups where they are moderator or administrator
const { result: userMembershipsResult } = useQuery<{
  loggedUser: { memberships: { elements: IMember[] } };
}>(LOGGED_USER_MEMBERSHIPS, { limit: 100 }, () => ({
  enabled: !props.isUpdate && currentActor.value?.id !== undefined,
  fetchPolicy: "cache-and-network",
}));

// Filter groups where user has moderator or administrator role
const administeredGroups = computed<IGroup[]>(() => {
  const memberships =
    userMembershipsResult.value?.loggedUser?.memberships?.elements || [];
  return memberships
    .filter((membership: IMember) =>
      [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(membership.role)
    )
    .map((membership: IMember) => membership.parent as IGroup);
});

// Selected organizer value for the dropdown
const selectedOrganizer = ref<string>("personal");

// Watch for changes in selectedOrganizer and update event attribution
watch(selectedOrganizer, (newValue) => {
  if (newValue === "personal") {
    event.value.attributedTo = undefined;
    event.value.organizerActor = currentActor.value;
    // Update URL to remove query params
    if (route.query.actorId || route.query.groupUsername) {
      router.replace({ name: route.name as string, query: {} });
    }
  } else {
    // Find the selected group
    const selectedGroup = administeredGroups.value.find(
      (group) => group.id === newValue
    );
    if (selectedGroup) {
      event.value.attributedTo = selectedGroup;
      event.value.organizerActor = currentActor.value;
      // Update URL with query params
      router.replace({
        name: route.name as string,
        query: {
          actorId: selectedGroup.id,
          groupUsername: selectedGroup.preferredUsername,
        },
      });
    }
  }
});

// Initialize selectedOrganizer based on query params or event attribution
watch(
  [groupResult, administeredGroups],
  () => {
    if (props.isUpdate || props.isDuplicate) {
      // For update/duplicate, set based on existing event attribution
      if (event.value.attributedTo?.id) {
        selectedOrganizer.value = event.value.attributedTo.id;
      } else {
        selectedOrganizer.value = "personal";
      }
    } else if (actorId.value && groupResult.value?.group) {
      // From query params (coming from group page)
      selectedOrganizer.value = actorId.value;
    } else {
      // Default to personal event
      selectedOrganizer.value = "personal";
      // Explicitly clear attribution for new personal events
      if (!actorId.value) {
        event.value.attributedTo = undefined;
        event.value.organizerActor = currentActor.value;
      }
    }
  },
  { immediate: true }
);

// Computed property to get the selected organizer's full data (for preview with avatar)
const selectedOrganizerData = computed(() => {
  if (selectedOrganizer.value === "personal") {
    return currentActor.value;
  }
  return administeredGroups.value.find(
    (group) => group.id === selectedOrganizer.value
  );
});

const validateForm = () => {
  if (!form.value) return;

  // Check title length validation
  if (event.value.title.length < 3) {
    notification.open({
      message: t(
        "The event title must be at least 3 characters long."
      ) as string,
      variant: "danger",
      position: "bottom-right",
      duration: 5000,
    });
    return false;
  }

  // Check participant capacity validation
  if (limitedPlaces.value) {
    const currentCount = currentParticipantCount.value;
    const maxCapacity = event.value.options.maximumAttendeeCapacity;

    if (maxCapacity < 1) {
      notification.open({
        message: t(
          "Maximum number of participants must be at least 1"
        ) as string,
        variant: "danger",
        position: "bottom-right",
        duration: 5000,
      });
      return false;
    }

    // When participants exceed limit, allow save so organizer can change options
    // (e.g. switch to "Require manual approval"). Only block when reducing capacity below current count
    // and we're not already over capacity (backend will reject capacity < count on update).
    const isOverCapacity = currentCount > 0 && maxCapacity < currentCount;
    if (isOverCapacity && event.value.id) {
      // Editing existing event that is over capacity: allow save so they can update
      // waitlist_auto_promote, block_new_registrations, etc.
    } else if (currentCount > 0 && maxCapacity < currentCount) {
      notification.open({
        message: t(
          "Cannot set participant limit below current participant count ({count})",
          { count: currentCount }
        ) as string,
        variant: "danger",
        position: "bottom-right",
        duration: 5000,
      });
      return false;
    }
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

  // Mark that events were updated for later calendar refresh
  localStorage.setItem("lastEventUpdate", Date.now().toString());

  // Trigger calendar refresh to show new events immediately
  window.dispatchEvent(new CustomEvent("calendar-refresh"));

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

  // Mark that events were updated for later calendar refresh
  localStorage.setItem("lastEventUpdate", Date.now().toString());

  // Trigger calendar refresh to show updated events immediately
  window.dispatchEvent(new CustomEvent("calendar-refresh"));

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
  editEventMutation(variables);
};

const hasCurrentActorPermissionsToEdit = computed((): boolean => {
  // First check if we have a current actor for new events
  if (!props.eventId && !currentActor.value?.id) {
    return false;
  }

  return !(
    props.eventId &&
    event.value?.organizerActor?.id !== undefined &&
    !identities.value
      ?.map(({ id }) => id)
      .includes(event.value?.organizerActor?.id) &&
    !hasGroupPrivileges.value
  );
});

const missingActorMessage = computed((): string => {
  if (!currentActor.value?.id && !props.eventId) {
    return t(
      "No organizer profile found. You need to create a profile to organize events. This may happen after logging in with LinkedIn - please create your profile first."
    ) as string;
  }
  return t(
    "Only group moderators can create, edit and delete events."
  ) as string;
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
          // Handle specific validation errors with user-friendly messages
          if (
            message.includes("title") &&
            message.includes("should be at least 3")
          ) {
            notifier?.error(
              t("The event title must be at least 3 characters long.")
            );
          } else if (
            message.includes("title") &&
            (message.includes("too short") || message.includes("min: 3"))
          ) {
            notifier?.error(
              t("The event title must be at least 3 characters long.")
            );
          } else {
            notifier?.error(message);
          }
        }
      }
    );
  } else {
    // Handle generic errors
    notifier?.error(
      t(
        "An error occurred while saving the event. Please check your input and try again."
      )
    );
  }
};

/**
 * Put in cache the updated or created event.
 * If the event is not a draft anymore, also put in cache the participation
 */
const postCreateOrUpdate = (store: any, updatedEvent: IEvent) => {
  const resultEvent: IEvent = { ...updatedEvent };
  if (!updatedEvent.draft && resultEvent?.organizerActor?.id) {
    // Update the EVENT_PERSON_PARTICIPATION cache with correct variables
    try {
      store.writeQuery({
        query: EVENT_PERSON_PARTICIPATION,
        variables: {
          eventId: resultEvent.id,
          actorId: resultEvent.organizerActor.id, // Fixed: use actorId instead of name
        },
        data: {
          person: {
            __typename: "Person",
            id: resultEvent.organizerActor.id,
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
                    id: resultEvent.organizerActor.id,
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
    } catch (error) {
      console.warn("Failed to update EVENT_PERSON_PARTICIPATION cache:", error);
    }

    // Also try to update the HOME_USER_QUERIES cache to immediately show the event on home page
    try {
      // Use start of today to match HomeView query
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const afterDateTime = todayStart.toISOString();

      const homeData = store.readQuery({
        query: HOME_USER_QUERIES,
        variables: {
          afterDateTime,
        },
      });

      if (homeData?.loggedUser?.participations?.elements) {
        const newParticipation = {
          __typename: "Participant",
          id: "unknown",
          role: ParticipantRole.CREATOR,
          actor: {
            __typename: "Actor",
            id: resultEvent.organizerActor.id,
            preferredUsername: resultEvent.organizerActor.preferredUsername,
            name: resultEvent.organizerActor.name,
            avatar: resultEvent.organizerActor.avatar,
          },
          event: resultEvent,
        };

        const updatedHomeData = {
          ...homeData,
          loggedUser: {
            ...homeData.loggedUser,
            participations: {
              ...homeData.loggedUser.participations,
              total: homeData.loggedUser.participations.total + 1,
              elements: [
                newParticipation,
                ...homeData.loggedUser.participations.elements,
              ],
            },
          },
        };

        store.writeQuery({
          query: HOME_USER_QUERIES,
          variables: {
            afterDateTime,
          },
          data: updatedHomeData,
        });
      }
    } catch (error) {
      console.warn("Failed to update HOME_USER_QUERIES cache:", error);
    }
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

  // Use start of today to match HomeView query
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const afterDateTime = todayStart.toISOString();

  // Get calendar date range - refetch for current month and next month to cover updated events
  const calendarStart = new Date();
  calendarStart.setDate(1); // First day of current month
  calendarStart.setHours(0, 0, 0, 0);

  const calendarEnd = new Date(calendarStart);
  calendarEnd.setMonth(calendarEnd.getMonth() + 2); // End of next month
  calendarEnd.setHours(23, 59, 59, 999);

  return [
    {
      query: LOGGED_USER_PARTICIPATIONS,
      variables: {
        afterDateTime,
      },
    },
    {
      query: HOME_USER_QUERIES,
      variables: {
        afterDateTime,
      },
    },
    {
      query: SEARCH_CALENDAR_EVENTS,
      variables: {
        beginsOn: calendarStart.toISOString(),
        endsOn: calendarEnd.toISOString(),
        limit: 999,
      },
    },
  ];
};

/**
 * Build variables for Event GraphQL creation query
 * Note: organizerActorId is no longer needed - the backend uses the current user's default profile
 */
const buildVariables = async () => {
  // Clean the options object to remove Apollo Client metadata like __typename
  const cleanOptions = { ...event.value.options };
  delete (cleanOptions as any).__typename;

  let res = {
    ...toEditJSON(new EventModel(event.value)),
    options: cleanOptions,
  };

  // Ensure category is always set to a valid value
  if (!res.category) {
    res.category = "SOCIAL_ACTIVITIES";
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
  } catch (e) {
    console.error(e);
  }

  return res;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
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

const enableWaitlist = computed({
  get(): boolean {
    return event.value?.options.enableWaitlist || false;
  },
  set(value: boolean) {
    event.value.options = {
      ...event.value.options,
      enableWaitlist: value,
    };
  },
});

const waitlistAutoPromote = computed({
  get(): boolean {
    return event.value?.options.waitlistAutoPromote !== undefined
      ? event.value.options.waitlistAutoPromote
      : true;
  },
  set(value: boolean) {
    event.value.options = {
      ...event.value.options,
      waitlistAutoPromote: value,
    };
  },
});

const waitlistOnly = computed({
  get(): boolean {
    return event.value?.options.waitlistOnly || false;
  },
  set(value: boolean) {
    event.value.options = {
      ...event.value.options,
      waitlistOnly: value,
      // When enabling waitlist-only mode, force disable auto-promote
      ...(value ? { waitlistAutoPromote: false } : {}),
    };
  },
});

const blockNewRegistrations = computed({
  get(): boolean {
    return event.value?.options.blockNewRegistrations || false;
  },
  set(value: boolean) {
    event.value.options = {
      ...event.value.options,
      blockNewRegistrations: value,
    };
  },
});

const currentParticipantCount = computed((): number => {
  const stats = event.value?.participantStats;
  if (!stats) return 0;

  // Count participants, administrators, and moderators (but NOT creator)
  return (
    (stats.participant || 0) +
    (stats.administrator || 0) +
    (stats.moderator || 0)
  );
});

const checkTitleLength = computed((): Array<string | undefined> => {
  if (event.value.title.length < 3 && event.value.title.length > 0) {
    return ["danger", t("The event title must be at least 3 characters long.")];
  } else if (event.value.title.length > 80) {
    return ["info", t("The event title will be ellipsed.")];
  }
  return [undefined, undefined];
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

// Display current timezone in a user-friendly format
const currentTimezoneDisplay = computed((): string => {
  const currentTz = timezone.value || userActualTimezone.value;
  if (currentTz) {
    return sanitizeTimezone(currentTz.split("/").pop() || currentTz);
  }
  return t("Default timezone") as string;
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

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const maximumAttendeeCapacity = computed({
  get(): string {
    const capacity = event.value.options.maximumAttendeeCapacity;
    return capacity > 0 ? capacity.toString() : "";
  },
  set(newMaximumAttendeeCapacity: string) {
    const parsedValue = parseInt(newMaximumAttendeeCapacity) || 0;
    event.value.options = {
      ...event.value.options,
      maximumAttendeeCapacity: parsedValue,
    };
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
  async () => {
    if (!fetchedEvent.value) return;
    event.value = { ...fetchedEvent.value };
    // Update pictureFile when event data is loaded
    pictureFile.value = await buildFileFromIMedia(fetchedEvent.value.picture);
    // Update limitedPlacesEnabled based on loaded event data
    limitedPlacesEnabled.value =
      (fetchedEvent.value?.options?.maximumAttendeeCapacity || 0) > 0;
  },
  { immediate: true }
);

onFetchEventResult(async (result) => {
  if (!result.loading && result.data?.event) {
    event.value = { ...result.data?.event };
    // Update pictureFile when event data is loaded
    pictureFile.value = await buildFileFromIMedia(result.data.event.picture);
    // Update limitedPlacesEnabled based on loaded event data
    limitedPlacesEnabled.value =
      (result.data.event?.options?.maximumAttendeeCapacity || 0) > 0;
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

// eslint-disable-next-line @typescript-eslint/no-unused-vars
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
