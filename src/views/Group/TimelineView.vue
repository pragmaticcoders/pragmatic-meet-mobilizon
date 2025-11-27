<template>
  <div class="min-h-screen dark:bg-gray-900">
    <!-- Breadcrumbs -->
    <div class="max-w-screen-xl mx-auto px-4 md:px-16 pt-4">
      <breadcrumbs-nav
        v-if="group"
        :links="[
          {
            name: RouteName.GROUP,
            params: { preferredUsername: usernameWithDomain(group) },
            text: displayName(group),
          },
          {
            name: RouteName.TIMELINE,
            params: { preferredUsername: usernameWithDomain(group) },
            text: t('Activity'),
          },
        ]"
      />
    </div>

    <!-- Main Content -->
    <div class="max-w-screen-xl mx-auto px-4 md:px-16 py-8">
      <!-- Activity Filters Card -->
      <div
        class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-6"
      >
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          {{ t("Activity Filter") }}
        </h2>

        <!-- Filter by Type -->
        <div class="mb-6">
          <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            {{ t("Filter by type") }}
          </h3>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === undefined,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="undefined"
                class="sr-only"
              />
              <TimelineText
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("All activities")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.MEMBER,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.MEMBER"
                class="sr-only"
              />
              <o-icon
                icon="account-multiple-plus"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Members")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.GROUP,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.GROUP"
                class="sr-only"
              />
              <o-icon
                icon="cog"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Settings")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.EVENT,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.EVENT"
                class="sr-only"
              />
              <o-icon
                icon="calendar"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Events")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.POST,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.POST"
                class="sr-only"
              />
              <o-icon
                icon="bullhorn"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Posts")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.DISCUSSION,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.DISCUSSION"
                class="sr-only"
              />
              <o-icon
                icon="chat"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Discussions")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityType === ActivityType.RESOURCE,
              }"
            >
              <input
                type="radio"
                v-model="activityType"
                :value="ActivityType.RESOURCE"
                class="sr-only"
              />
              <o-icon
                icon="link"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("Resources")
              }}</span>
            </label>
          </div>
        </div>

        <!-- Filter by Author -->
        <div>
          <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            {{ t("Filter by author") }}
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityAuthor === undefined,
              }"
            >
              <input
                type="radio"
                v-model="activityAuthor"
                :value="undefined"
                class="sr-only"
              />
              <TimelineText
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("All activities")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityAuthor === ActivityAuthorFilter.SELF,
              }"
            >
              <input
                type="radio"
                v-model="activityAuthor"
                :value="ActivityAuthorFilter.SELF"
                class="sr-only"
              />
              <o-icon
                icon="account"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("From yourself")
              }}</span>
            </label>

            <label
              class="flex items-center p-3 border border-gray-200 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              :class="{
                'bg-blue-50 dark:bg-blue-900/30 border-blue-300 dark:border-blue-600':
                  activityAuthor === ActivityAuthorFilter.BY,
              }"
            >
              <input
                type="radio"
                v-model="activityAuthor"
                :value="ActivityAuthorFilter.BY"
                class="sr-only"
              />
              <o-icon
                icon="account-multiple"
                class="mr-2 text-gray-600 dark:text-gray-400"
                :size="18"
              />
              <span class="text-sm font-medium text-gray-900 dark:text-white">{{
                t("By others")
              }}</span>
            </label>
          </div>
        </div>
      </div>

      <!-- Timeline Content Card -->
      <div
        class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
      >
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">
          {{ t("Activity Timeline") }}
        </h2>

        <section class="timeline">
          <transition-group name="timeline-list" tag="div">
            <div
              class="day"
              v-for="[date, activityItems] in Object.entries(activities)"
              :key="date"
            >
              <o-skeleton
                v-if="date.search(/skeleton/) !== -1"
                width="300px"
                height="48px"
              />
              <h2 v-else-if="isToday(date)">
                <span v-tooltip="formatDateString(date)">
                  {{ t("Today") }}
                </span>
              </h2>
              <h2 v-else-if="isYesterday(date)">
                <span v-tooltip="formatDateString(date)">{{
                  t("Yesterday")
                }}</span>
              </h2>
              <h2 v-else>
                {{ formatDateString(date) }}
              </h2>
              <ul class="before:opacity-10">
                <li
                  v-for="activityItem in activityItems"
                  :key="activityItem.id"
                >
                  <skeleton-activity-item
                    v-if="activityItem.type === 'skeleton'"
                  />
                  <component
                    v-else
                    :is="component(activityItem.type)"
                    :activity="activityItem"
                  />
                </li>
              </ul>
            </div>
          </transition-group>

          <empty-content
            icon="timeline-text"
            v-if="
              !loading &&
              activity.elements.length > 0 &&
              activity.elements.length >= activity.total
            "
          >
            {{ t("No more activity to display.") }}
          </empty-content>

          <empty-content
            v-if="!loading && activity.total === 0"
            icon="timeline-text"
          >
            {{
              t(
                "There is no activity yet. Start doing some things to see activity appear here."
              )
            }}
          </empty-content>
        </section>

        <!-- Load More Button -->
        <div class="mt-8 text-center">
          <observer @intersect="loadMore" />
          <o-button
            v-if="activity.elements.length < activity.total"
            @click="loadMore"
            class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors"
          >
            {{ t("Load more activities") }}
          </o-button>
        </div>
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { GROUP_TIMELINE } from "@/graphql/group";
import { IGroup, usernameWithDomain, displayName } from "@/types/actor";
import { ActivityType } from "@/types/enums";
import { Paginate } from "@/types/paginate";
import { IActivity } from "../../types/activity.model";
import Observer from "../../components/Utils/ObserverElement.vue";
import SkeletonActivityItem from "../../components/Activity/SkeletonActivityItem.vue";
import RouteName from "../../router/name";
import TimelineText from "vue-material-design-icons/TimelineText.vue";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@/utils/head";
import { enumTransformer, useRouteQuery } from "vue-use-route-query";
import { computed, defineAsyncComponent, ref } from "vue";
import { useI18n } from "vue-i18n";
import { formatDateString } from "@/filters/datetime";

const PAGINATION_LIMIT = 25;
const SKELETON_DAY_ITEMS = 2;
const SKELETON_ITEMS_PER_DAY = 5;
type IActivitySkeleton =
  | IActivity
  | { skeleton: string; id: string; type: "skeleton" };

enum ActivityAuthorFilter {
  SELF = "SELF",
  BY = "BY",
}

// type ActivityFilter = ActivityType | ActivityAuthorFilter | null;

const props = defineProps<{ preferredUsername: string }>();

const { t } = useI18n({ useScope: "global" });

const EventActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/EventActivityItem.vue")
);
const PostActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/PostActivityItem.vue")
);
const MemberActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/MemberActivityItem.vue")
);
const ResourceActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/ResourceActivityItem.vue")
);
const DiscussionActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/DiscussionActivityItem.vue")
);
const GroupActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/GroupActivityItem.vue")
);
const EmptyContent = defineAsyncComponent(
  () => import("../../components/Utils/EmptyContent.vue")
);

const activityType = useRouteQuery(
  "activityType",
  undefined,
  enumTransformer(ActivityType)
);
const activityAuthor = useRouteQuery(
  "activityAuthor",
  undefined,
  enumTransformer(ActivityAuthorFilter)
);

const page = ref(1);

const {
  result: groupTimelineResult,
  fetchMore: fetchMoreActivities,
  onError: onGroupTLError,
  loading,
} = useQuery<{ group: IGroup }>(GROUP_TIMELINE, () => ({
  preferredUsername: props.preferredUsername,
  page: page.value,
  limit: PAGINATION_LIMIT,
  type: activityType.value,
  author: activityAuthor.value,
}));

onGroupTLError((err) => console.error(err));

const group = computed(() => groupTimelineResult.value?.group);

useHead({
  title: computed(() =>
    t("{group} activity timeline", { group: group.value?.name })
  ),
});

const activity = computed((): Paginate<IActivitySkeleton> => {
  if (group.value) {
    return group.value.activity;
  }
  return {
    total: 0,
    elements: skeletons.value.map((skeleton) => ({
      skeleton,
      id: skeleton,
      type: "skeleton",
    })),
  };
});

const component = (type: ActivityType): any | undefined => {
  switch (type) {
    case ActivityType.EVENT:
      return EventActivityItem;
    case ActivityType.POST:
      return PostActivityItem;
    case ActivityType.MEMBER:
      return MemberActivityItem;
    case ActivityType.RESOURCE:
      return ResourceActivityItem;
    case ActivityType.DISCUSSION:
      return DiscussionActivityItem;
    case ActivityType.GROUP:
      return GroupActivityItem;
  }
};

const skeletons = computed((): string[] => {
  return [...Array(SKELETON_DAY_ITEMS)]
    .map((_, i) => {
      return [...Array(SKELETON_ITEMS_PER_DAY)].map((_a, j) => {
        return `${i}-${j}`;
      });
    })
    .flat();
});

const loadMore = async (): Promise<void> => {
  if (page.value * PAGINATION_LIMIT >= activity.value.total) {
    return;
  }
  page.value++;
  try {
    await fetchMoreActivities({
      variables: {
        page: page.value,
        limit: PAGINATION_LIMIT,
      },
    });
  } catch (e) {
    console.error(e);
  }
};

const activities = computed((): Record<string, IActivitySkeleton[]> => {
  return activity.value.elements.reduce(
    (acc: Record<string, IActivitySkeleton[]>, elem) => {
      let key;
      if (isIActivity(elem)) {
        const insertedAt = new Date(elem.insertedAt);
        insertedAt.setHours(0);
        insertedAt.setMinutes(0);
        insertedAt.setSeconds(0);
        insertedAt.setMilliseconds(0);
        key = insertedAt.toISOString();
      } else {
        key = `skeleton-${elem.skeleton.split("-")[0]}`;
      }
      const existing = acc[key];
      if (existing) {
        acc[key] = [...existing, ...[elem]];
      } else {
        acc[key] = [elem];
      }
      return acc;
    },
    {}
  );
});

const isIActivity = (object: IActivitySkeleton): object is IActivity => {
  return !("skeleton" in object);
};
// const getRandomInt = (min: number, max: number): number => {
//   min = Math.ceil(min);
//   max = Math.floor(max);
//   return Math.floor(Math.random() * (max - min) + min);
// };

const isToday = (dateString: string): boolean => {
  const now = new Date();
  const date = new Date(dateString);
  return (
    now.getFullYear() === date.getFullYear() &&
    now.getMonth() === date.getMonth() &&
    now.getDate() === date.getDate()
  );
};

const isYesterday = (dateString: string): boolean => {
  const date = new Date(dateString);
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return (
    yesterday.getFullYear() === date.getFullYear() &&
    yesterday.getMonth() === date.getMonth() &&
    yesterday.getDate() === date.getDate()
  );
};
</script>
<style lang="scss" scoped>
.timeline {
  ul {
    margin: 0;
    padding: 0;
    list-style: none;
    position: relative;

    &::before {
      content: "";
      height: 100%;
      width: 2px;
      background: linear-gradient(to bottom, #e5e7eb, #d1d5db);
      position: absolute;
      top: 0;
      left: 1rem;
      border-radius: 1px;
    }

    :deep(.dark) &::before {
      background: linear-gradient(to bottom, #374151, #4b5563);
    }

    li {
      display: flex;
      margin: 1rem 0;
      position: relative;

      &::before {
        content: "";
        width: 8px;
        height: 8px;
        background-color: #3b82f6;
        border: 2px solid #ffffff;
        border-radius: 50%;
        position: absolute;
        left: 0.75rem;
        top: 0.75rem;
        z-index: 10;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      }

      :deep(.dark) &::before {
        background-color: #60a5fa;
        border-color: #1f2937;
      }
    }
  }

  .day {
    margin-bottom: 2rem;

    h2 {
      color: #374151;
      font-weight: 600;
      font-size: 1.125rem;
      margin-bottom: 1rem;
      padding-left: 0;

      :deep(.dark) & {
        color: #f3f4f6;
      }

      span {
        background-color: #ffffff;
        padding: 0.25rem 0.75rem;
        border-radius: 0.5rem;
        border: 1px solid #e5e7eb;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);

        :deep(.dark) & {
          background-color: #1f2937;
          border-color: #374151;
          color: #f3f4f6;
        }
      }
    }
  }
}

// Timeline animations
.timeline-list-enter-active,
.timeline-list-leave-active {
  transition: all 0.3s ease;
}

.timeline-list-enter-from,
.timeline-list-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

// Empty states
.empty-content {
  text-align: center;
  padding: 3rem 1rem;
  color: #6b7280;

  :deep(.dark) & {
    color: #9ca3af;
  }
}

// Dark mode improvements
:deep(.dark) {
  .bg-gray-50 {
    background-color: #111827;
  }

  .border-gray-200 {
    border-color: #374151;
  }

  .text-gray-900 {
    color: #f9fafb;
  }

  .text-gray-700 {
    color: #d1d5db;
  }

  .text-gray-600 {
    color: #9ca3af;
  }
}
</style>
