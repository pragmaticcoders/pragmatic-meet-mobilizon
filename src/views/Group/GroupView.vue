<template>
  <div class="min-h-screen">
    <o-notification v-if="groupLoading" variant="info">
      {{ t("Loading…") }}
    </o-notification>
    <o-notification v-if="!group && groupLoading === false" variant="danger">
      {{ t("No group found") }}
    </o-notification>

    <div v-if="group">
      <!-- Breadcrumbs -->
      <div class="max-w-screen-xl mx-auto px-4 md:px-16 pt-4">
        <breadcrumbs-nav
          :links="[
            { name: RouteName.MY_GROUPS, text: t('My groups') },
            {
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
              text: displayName(group),
            },
          ]"
        />
      </div>

      <!-- Pending Approval Banner - Positioned under breadcrumbs -->
      <div
        v-if="isGroupPendingApproval && isCurrentActorAGroupAdminOrOwner"
        class="max-w-screen-xl mx-auto px-4 md:px-16 pb-4"
      >
        <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-md">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg
                class="h-5 w-5 text-yellow-400"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm text-yellow-700">
                <strong>{{
                  t("Group Awaiting Administrator Approval")
                }}</strong>
              </p>
              <p class="text-sm text-yellow-700 mt-1">
                {{
                  t(
                    "This group is pending approval from site administrators and is currently only visible to administrators and the group owner. Most group functionalities including member management, event creation, discussions, and announcements are limited until the group is approved. Resources can still be added and managed."
                  )
                }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Header Section - Banner Area -->
      <div class="max-w-screen-xl mx-auto px-4 md:px-16 pt-4">
        <!-- Top Banner - Bigger without gray background -->
        <div class="relative overflow-hidden" v-if="group.banner">
          <!-- Group Banner Background -->
          <lazy-image-wrapper :picture="group.banner" class="w-full" />
        </div>
        <!-- Fallback when no banner -->
        <div
          class="relative bg-gray-50 dark:bg-gray-800 overflow-hidden h-64 flex items-center justify-center"
          v-else
        >
          <svg
            width="96"
            height="96"
            viewBox="0 0 48 48"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            class="text-gray-300 dark:text-gray-600"
          >
            <!-- Group/People icon -->
            <circle
              cx="20"
              cy="16"
              r="6"
              stroke="currentColor"
              stroke-width="2"
              fill="none"
            />
            <circle
              cx="32"
              cy="20"
              r="4"
              stroke="currentColor"
              stroke-width="2"
              fill="none"
            />
            <path
              d="M8 38v-4c0-4.418 3.582-8 8-8h8c4.418 0 8 3.582 8 8v4"
              stroke="currentColor"
              stroke-width="2"
              fill="none"
              stroke-linecap="round"
            />
            <path
              d="M36 38v-2c0-2.761-1.567-5.149-3.861-6.349"
              stroke="currentColor"
              stroke-width="2"
              fill="none"
              stroke-linecap="round"
            />
          </svg>
        </div>

        <!-- Floating Avatar positioned at bottom of banner -->
        <div class="relative max-w-screen-xl mx-auto px-4 md:px-16">
          <div
            class="absolute left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-20"
          >
            <!-- Avatar with proper rounded styling -->
            <div class="w-28 h-28 bg-transparent">
              <img
                v-if="group.avatar"
                class="w-full h-full object-cover rounded-full border-4 border-white"
                :src="group.avatar.url"
                :alt="displayName(group)"
                width="130"
                height="130"
              />
              <!-- Default avatar when no avatar is set -->
              <div
                v-else
                class="bg-gray-200 dark:bg-gray-600"
                style="
                  width: 100%;
                  height: 100%;
                  border-radius: 50%;
                  border: 4px solid white;
                  background: radial-gradient(circle, #f3f4f6 0%, #e5e7eb 100%);
                  display: flex;
                  align-items: center;
                  justify-content: center;
                "
              >
                <AccountGroup
                  class="text-gray-500 dark:text-gray-400"
                  :size="48"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Bottom Section with Gray Border and NavBar width -->
        <div class="mt-8">
          <div
            class="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 shadow-sm w-full"
          >
            <div class="text-center">
              <!-- Group Info -->
              <h1
                class="text-3xl font-bold text-gray-900 dark:text-white mb-2"
                v-if="group.name"
              >
                {{ group.name }}
              </h1>
              <p
                class="text-gray-600 dark:text-gray-400 text-lg mb-8"
                v-if="group.preferredUsername"
              >
                @{{ usernameWithDomain(group) }}
              </p>

              <!-- Action Buttons with Icons -->
              <div class="flex flex-wrap justify-center gap-3 max-w-lg mx-auto">
                <!-- Follow Button -->
                <o-button
                  v-if="showFollowButton"
                  @click="followGroup"
                  icon-left="rss"
                  class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-md font-medium transition-colors"
                >
                  {{ t("Follow") }}
                </o-button>

                <!-- Contact Button -->
                <o-button
                  tag="router-link"
                  :to="{
                    name: RouteName.CONVERSATION_LIST,
                    query: {
                      newMessage: 'true',
                      groupMentions: usernameWithDomain(group),
                    },
                  }"
                  icon-left="email"
                  class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-md font-medium transition-colors"
                >
                  {{ t("Contact") }}
                </o-button>

                <!-- Share Button -->
                <o-button
                  @click="triggerShare()"
                  icon-left="share"
                  class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-md font-medium transition-colors"
                >
                  {{ t("Share") }}
                </o-button>

                <!-- More Options Menu -->
                <o-dropdown aria-role="list">
                  <template #trigger>
                    <o-button
                      icon-left="dots-horizontal"
                      class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-md font-medium transition-colors"
                    >
                    </o-button>
                  </template>

                  <!-- Settings for Admins -->
                  <o-dropdown-item
                    v-if="isCurrentActorAGroupAdmin && !previewPublic"
                    aria-role="menuitem"
                  >
                    <router-link
                      :to="{
                        name: RouteName.GROUP_PUBLIC_SETTINGS,
                        params: {
                          preferredUsername: usernameWithDomain(group),
                        },
                      }"
                      class="flex items-center w-full px-4 py-2"
                    >
                      <Cog class="mr-2" :size="18" />
                      {{ t("Group settings") }}
                    </router-link>
                  </o-dropdown-item>

                  <!-- Activity for Members -->
                  <o-dropdown-item
                    v-if="isCurrentActorAGroupMember && !previewPublic"
                    aria-role="menuitem"
                  >
                    <router-link
                      :to="{
                        name: RouteName.TIMELINE,
                        params: {
                          preferredUsername: usernameWithDomain(group),
                        },
                      }"
                      class="flex items-center w-full px-4 py-2"
                    >
                      <ViewList class="mr-2" :size="18" />
                      {{ t("Activity") }}
                    </router-link>
                  </o-dropdown-item>

                  <!-- Join Button for eligible users -->
                  <o-dropdown-item
                    v-if="showJoinButton && !isCurrentActorAGroupMember"
                    aria-role="menuitem"
                  >
                    <button
                      @click="joinGroup"
                      class="flex items-center w-full px-4 py-2"
                    >
                      <AccountMultiplePlus class="mr-2" :size="18" />
                      {{ t("Join group") }}
                    </button>
                  </o-dropdown-item>

                  <!-- Additional options -->
                  <o-dropdown-item
                    v-if="ableToReport"
                    aria-role="menuitem"
                    @click="isReportModalActive = true"
                  >
                    <span class="flex items-center px-4 py-2">
                      <Flag class="mr-2" :size="18" />
                      {{ t("Report") }}
                    </span>
                  </o-dropdown-item>

                  <o-dropdown-item
                    v-if="isCurrentActorAGroupMember && !previewPublic"
                    aria-role="menuitem"
                    @click="openLeaveGroupModal"
                  >
                    <span class="flex items-center px-4 py-2">
                      <ExitToApp class="mr-2" :size="18" />
                      {{ t("Leave group") }}
                    </span>
                  </o-dropdown-item>
                </o-dropdown>
              </div>

              <!-- Notifications and Status Messages -->
              <div class="mt-8 space-y-4">
                <!-- Invitation Notice -->
                <InvitationsList
                  v-if="
                    isCurrentActorAnInvitedGroupMember &&
                    groupMember !== undefined
                  "
                  :invitations="[groupMember]"
                />

                <!-- Rejection Notice -->
                <o-notification
                  v-if="isCurrentActorARejectedGroupMember"
                  variant="danger"
                  class="max-w-2xl mx-auto"
                >
                  {{ t("You have been removed from this group's members.") }}
                </o-notification>

                <!-- New Member Notice -->
                <o-notification
                  v-if="
                    isCurrentActorAGroupMember &&
                    isCurrentActorARecentMember &&
                    isCurrentActorOnADifferentDomainThanGroup
                  "
                  variant="info"
                  class="max-w-2xl mx-auto"
                >
                  {{
                    t(
                      "Since you are a new member, private content can take a few minutes to appear."
                    )
                  }}
                </o-notification>

                <!-- External Instance Notice -->
                <o-notification
                  v-if="group && group.domain && !isCurrentActorAGroupMember"
                  variant="info"
                  class="max-w-2xl mx-auto"
                >
                  <p>
                    {{
                      t(
                        "This profile is from another instance, the informations shown here may be incomplete."
                      )
                    }}
                  </p>
                  <o-button
                    variant="text"
                    tag="a"
                    :href="group.url"
                    rel="noopener noreferrer external"
                    class="mt-2"
                  >
                    {{ t("View full profile") }}
                  </o-button>
                </o-notification>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="max-w-screen-xl mx-auto px-4 md:px-16 py-8">
        <!-- Two-column layout for main sections -->
        <div
          class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4"
          style="grid-template-rows: 1fr"
        >
          <!-- Members Section -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center mb-2">
              <AccountGroup class="text-blue-500 mr-3" :size="24" />
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                {{ t("Members") }}
              </h2>
            </div>

            <!-- Content area that grows -->
            <div
              class="flex-grow flex flex-col justify-center items-center min-h-[160px]"
            >
              <div
                class="flex flex-wrap justify-center mb-2"
                v-if="isCurrentActorAGroupMember && !previewPublic && members"
              >
                <figure
                  v-for="member in members.elements.slice(0, 6)"
                  :key="member.actor.id"
                  class="-mr-2 relative"
                  :title="
                    t(`{'@'}{username} ({role})`, {
                      username: usernameWithDomain(member.actor),
                      role: member.role,
                    })
                  "
                >
                  <img
                    class="rounded-full h-10 w-10 border-2 border-white dark:border-gray-800"
                    :src="member.actor.avatar.url"
                    v-if="member.actor.avatar"
                    alt=""
                    width="40"
                    height="40"
                  />
                  <AccountCircle v-else :size="40" class="text-gray-400" />
                </figure>
              </div>

              <div class="text-center">
                <p class="text-lg font-semibold text-gray-900 dark:text-white">
                  {{
                    t(
                      "{count} member(s)",
                      {
                        count: group?.members?.total || 0,
                      },
                      group?.members?.total || 0
                    )
                  }}
                </p>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                v-if="isCurrentActorAGroupAdmin && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.GROUP_MEMBERS_SETTINGS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                :disabled="isGroupPendingApproval"
                :class="[
                  'w-full py-2 px-4 rounded-lg font-medium transition-colors',
                  isGroupPendingApproval
                    ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                    : 'bg-blue-600 hover:bg-blue-700 text-white',
                ]"
                :title="
                  isGroupPendingApproval
                    ? t('This group is pending approval from administrators')
                    : ''
                "
              >
                {{ t("Manage Members") }}
              </o-button>
            </div>
          </div>

          <!-- Information Section -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center mb-2">
              <Information class="text-green-500 mr-3" :size="24" />
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                {{ t("Information") }}
              </h2>
            </div>

            <!-- Content area that grows -->
            <div class="flex-grow flex flex-col justify-center min-h-[160px]">
              <div
                v-if="group?.summary"
                dir="auto"
                class="prose prose-sm dark:prose-invert text-gray-600 dark:text-gray-300"
                v-html="group.summary"
              ></div>
              <div
                v-else
                class="text-center text-gray-500 dark:text-gray-400 py-8"
              >
                <Information
                  class="mx-auto mb-2 opacity-50 empty-state-icon"
                  :size="48"
                />
                <p>{{ t("No information available yet") }}</p>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                v-if="isCurrentActorAGroupAdmin && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.GROUP_PUBLIC_SETTINGS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
              >
                {{ t("Edit Information") }}
              </o-button>
            </div>
          </div>
        </div>

        <!-- Bottom sections for Events and Announcements -->
        <div
          class="grid grid-cols-1 lg:grid-cols-2 gap-3 mb-6"
          style="grid-template-rows: 1fr"
        >
          <!-- Events Section -->
          <div
            v-if="group"
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center">
                <Calendar class="text-blue-500 mr-3" :size="24" />
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                  {{ t("Events") }}
                </h2>
              </div>
              <router-link
                :to="{
                  name: RouteName.GROUP_EVENTS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                {{ t("View all") }}
              </router-link>
            </div>

            <!-- Content area that grows -->
            <div class="flex-grow space-y-4 min-h-[160px]">
              <div
                v-for="event in group.organizedEvents.elements
                  .filter((event) => !event.longEvent)
                  .slice(0, 2)"
                :key="event.uuid"
                class="border border-gray-200 dark:border-gray-600 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                @click="
                  $router.push({
                    name: RouteName.EVENT,
                    params: { uuid: event.uuid },
                  })
                "
              >
                <div class="flex items-start space-x-3">
                  <div class="flex-shrink-0">
                    <img
                      v-if="event.picture"
                      :src="event.picture.url"
                      :alt="event.title"
                      class="w-12 h-12 rounded-lg object-cover"
                    />
                    <div
                      v-else
                      class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center"
                    >
                      <Calendar class="text-blue-500" :size="20" />
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3
                      class="text-sm font-medium text-gray-900 dark:text-white truncate"
                    >
                      {{ event.title }}
                    </h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                      🕒 {{ new Date(event.beginsOn).toLocaleDateString() }}
                    </p>
                    <p
                      v-if="event.physicalAddress"
                      class="text-xs text-gray-500 dark:text-gray-400"
                    >
                      📍 {{ event.physicalAddress.locality }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                v-if="
                  group.organizedEvents.elements.filter(
                    (event) => !event.longEvent
                  ).length === 0
                "
                class="flex flex-col items-center justify-center min-h-64 text-gray-500 dark:text-gray-400"
              >
                <Calendar
                  class="mx-auto mb-2 opacity-50 empty-state-icon"
                  :size="48"
                />
                <p>{{ t("No upcoming events") }}</p>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                v-if="isCurrentActorAGroupModerator && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.CREATE_EVENT,
                  query: { actorId: group?.id },
                }"
                :disabled="isGroupPendingApproval"
                :class="[
                  'w-full py-2 px-4 rounded-lg font-medium transition-colors',
                  isGroupPendingApproval
                    ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                    : 'bg-blue-600 hover:bg-blue-700 text-white',
                ]"
                :title="
                  isGroupPendingApproval
                    ? t('This group is pending approval from administrators')
                    : ''
                "
              >
                {{ t("Create Event") }}
              </o-button>
            </div>
          </div>

          <!-- Announcements Section -->
          <div
            v-if="group"
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center">
                <Bullhorn class="text-orange-500 mr-3" :size="24" />
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                  {{ t("Announcements") }}
                </h2>
              </div>
              <router-link
                :to="{
                  name: RouteName.POSTS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                {{ t("View all") }}
              </router-link>
            </div>

            <!-- Content area that grows -->
            <div class="flex-grow space-y-4 min-h-[160px]">
              <div
                v-for="post in (isCurrentActorAGroupMember && !previewPublic
                  ? group.posts?.elements
                  : group.posts?.elements?.filter(
                      (post) => !post.draft && post.visibility === 'PUBLIC'
                    )
                )?.slice(0, 2) || []"
                :key="post.id"
                class="border border-gray-200 dark:border-gray-600 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                @click="
                  $router.push({
                    name: RouteName.POST,
                    params: { slug: post.slug },
                  })
                "
              >
                <div class="flex items-start space-x-3">
                  <div class="flex-shrink-0">
                    <img
                      v-if="post.picture"
                      :src="post.picture.url"
                      :alt="post.title"
                      class="w-12 h-12 rounded-lg object-cover"
                    />
                    <div
                      v-else
                      class="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center"
                    >
                      <Bullhorn class="text-orange-500" :size="20" />
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3
                      class="text-sm font-medium text-gray-900 dark:text-white truncate"
                    >
                      {{ post.title }}
                    </h3>
                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                      🕒
                      {{
                        new Date(
                          post.publishAt || post.insertedAt || new Date()
                        ).toLocaleDateString()
                      }}
                    </p>
                    <p
                      v-if="post.author"
                      class="text-xs text-gray-500 dark:text-gray-400"
                    >
                      👤 {{ displayName(post.author) }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                v-if="
                  !group.posts?.elements || group.posts.elements.length === 0
                "
                class="flex flex-col items-center justify-center min-h-64 text-gray-500 dark:text-gray-400"
              >
                <Bullhorn
                  class="mx-auto mb-2 opacity-50 empty-state-icon"
                  :size="48"
                />
                <p>{{ t("No announcements yet") }}</p>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                v-if="isCurrentActorAGroupModerator && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.POST_CREATE,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                :disabled="isGroupPendingApproval"
                :class="[
                  'w-full py-2 px-4 rounded-lg font-medium transition-colors',
                  isGroupPendingApproval
                    ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                    : 'bg-blue-600 hover:bg-blue-700 text-white',
                ]"
                :title="
                  isGroupPendingApproval
                    ? t('This group is pending approval from administrators')
                    : ''
                "
              >
                {{ t("Create Announcement") }}
              </o-button>
            </div>
          </div>
        </div>

        <!-- Private sections -->
        <div
          v-if="isCurrentActorAGroupMember && !previewPublic"
          class="grid grid-cols-1 gap-3 mb-6 md:grid-cols-2"
          style="grid-template-rows: 1fr"
        >
          <!-- Group discussions -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center">
                <Chat class="text-blue-500 mr-3" :size="24" />
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                  {{ t("Discussions") }}
                </h2>
              </div>
              <router-link
                :to="{
                  name: RouteName.DISCUSSION_LIST,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                {{ t("View all") }}
              </router-link>
            </div>

            <!-- Content area that grows -->
            <div class="flex-grow min-h-[160px]">
              <div class="space-y-4">
                <div
                  v-for="discussion in (
                    discussionGroup || group
                  )?.discussions?.elements?.slice(0, 2) || []"
                  :key="discussion.id"
                  class="border border-gray-200 dark:border-gray-600 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                  @click="
                    $router.push({
                      name: RouteName.DISCUSSION,
                      params: { slug: discussion.slug },
                    })
                  "
                >
                  <div class="flex items-start space-x-3">
                    <div class="flex-shrink-0">
                      <div
                        class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center"
                      >
                        <Chat class="text-blue-600" :size="20" />
                      </div>
                    </div>
                    <div class="flex-1 min-w-0">
                      <h3
                        class="text-sm font-medium text-gray-900 dark:text-white truncate"
                      >
                        {{ discussion.title }}
                      </h3>
                      <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        <i class="fas fa-clock mr-1"></i>
                        {{
                          new Date(
                            discussion.updatedAt || new Date()
                          ).toLocaleDateString()
                        }}
                      </p>
                      <p
                        v-if="discussion.lastComment?.actor"
                        class="text-xs text-gray-500 dark:text-gray-400"
                      >
                        <i class="fas fa-user mr-1"></i>
                        {{ displayName(discussion.lastComment.actor) }}
                      </p>
                    </div>
                  </div>
                </div>

                <div
                  v-if="
                    !(discussionGroup || group)?.discussions?.elements?.length
                  "
                  class="text-center py-12 text-gray-500 dark:text-gray-400"
                >
                  <Chat
                    class="mx-auto mb-2 opacity-50 empty-state-icon"
                    :size="48"
                  />
                  <p class="text-lg">{{ t("No discussions yet") }}</p>
                </div>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                tag="router-link"
                :to="{
                  name: RouteName.CREATE_DISCUSSION,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                :disabled="isGroupPendingApproval"
                :class="[
                  'w-full py-2 px-4 rounded-lg font-medium transition-colors',
                  isGroupPendingApproval
                    ? 'bg-gray-400 text-gray-600 cursor-not-allowed opacity-60'
                    : 'bg-blue-600 hover:bg-blue-700 text-white',
                ]"
                :title="
                  isGroupPendingApproval
                    ? t('This group is pending approval from administrators')
                    : ''
                "
              >
                {{ t("Start Discussion") }}
              </o-button>
            </div>
          </div>

          <!-- Resources -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 flex flex-col"
            style="height: 380px"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center">
                <Link class="text-green-500 mr-3" :size="24" />
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                  {{ t("Resources") }}
                </h2>
              </div>
              <router-link
                :to="{
                  name: RouteName.RESOURCE_FOLDER_ROOT,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                {{ t("View all") }}
              </router-link>
            </div>

            <!-- Content area that grows -->
            <div class="flex-grow min-h-[160px]">
              <div class="space-y-4">
                <div
                  v-for="resource in (
                    resourcesGroup || group
                  )?.resources?.elements?.slice(0, 2) || []"
                  :key="resource.id"
                  class="border border-gray-200 dark:border-gray-600 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                  @click="
                    $router.push({
                      name: RouteName.RESOURCE_FOLDER,
                      params: {
                        preferredUsername: usernameWithDomain(group),
                        path: resource.path,
                      },
                    })
                  "
                >
                  <div class="flex items-start space-x-3">
                    <div class="flex-shrink-0">
                      <div
                        class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center"
                      >
                        <component
                          :is="
                            resource.type === 'folder'
                              ? 'FolderOutline'
                              : 'FileDocumentOutline'
                          "
                          class="text-blue-600"
                          :size="20"
                        />
                      </div>
                    </div>
                    <div class="flex-1 min-w-0">
                      <h3
                        class="text-sm font-medium text-gray-900 dark:text-white truncate"
                      >
                        {{ resource.title }}
                      </h3>
                      <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        <i class="fas fa-clock mr-1"></i>
                        {{
                          new Date(
                            resource.updatedAt || new Date()
                          ).toLocaleDateString()
                        }}
                      </p>
                      <p
                        v-if="resource.creator"
                        class="text-xs text-gray-500 dark:text-gray-400"
                      >
                        <i class="fas fa-user mr-1"></i>
                        {{ displayName(resource.creator) }}
                      </p>
                    </div>
                  </div>
                </div>

                <div
                  v-if="!(resourcesGroup || group)?.resources?.elements?.length"
                  class="text-center py-12 text-gray-500 dark:text-gray-400"
                >
                  <Link
                    class="mx-auto mb-2 opacity-50 empty-state-icon"
                    :size="48"
                  />
                  <p class="text-lg">{{ t("No resources yet") }}</p>
                </div>
              </div>
            </div>

            <!-- Button at bottom -->
            <div
              class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600"
            >
              <o-button
                tag="router-link"
                :to="{
                  name: RouteName.RESOURCE_FOLDER_ROOT,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="w-full py-2 px-4 rounded-lg font-medium transition-colors bg-blue-600 hover:bg-blue-700 text-white"
              >
                {{ t("Add Resource") }}
              </o-button>
            </div>
          </div>
        </div>
      </div>

      <!-- Notifications and Additional Information -->
      <div v-if="group" class="max-w-screen-xl mx-auto px-4 md:px-16 pb-8">
        <div v-if="isCurrentActorFollowing" class="my-2">
          <i18n-t
            class="my-2 text-sm text-gray-600 dark:text-gray-400"
            keypath="You will receive notifications about this group's public activity depending on %{notification_settings}."
          >
            <template #notification_settings>
              <router-link
                :to="{ name: RouteName.NOTIFICATIONS }"
                class="text-blue-600 hover:text-blue-700 underline"
              >
                {{ t("your notification settings") }}
              </router-link>
            </template>
          </i18n-t>
        </div>
      </div>

      <!-- Modals -->

      <o-modal
        v-if="group"
        v-model:active="isReportModalActive"
        :autoFocus="false"
        :trapFocus="false"
      >
        <report-modal
          ref="reportModalRef"
          :on-confirm="reportGroup"
          :title="t('Report this group')"
          :outside-domain="group.domain"
          @close="isReportModalActive = false"
        />
      </o-modal>

      <o-modal v-model:active="isShareModalActive" v-if="group">
        <ShareGroupModal :group="group" />
      </o-modal>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  displayName,
  IActor,
  IFollower,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";

import InvitationsList from "@/components/Group/InvitationsList.vue";
import { addMinutes } from "date-fns";
import { JOIN_GROUP } from "@/graphql/member";
import { MemberRole, ApprovalStatus } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";
import ReportModal from "@/components/Report/ReportModal.vue";
import {
  GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  PERSON_STATUS_GROUP,
} from "@/graphql/actor";
import LazyImageWrapper from "../../components/Image/LazyImageWrapper.vue";
import { FOLLOW_GROUP, UNFOLLOW_GROUP } from "@/graphql/followers";
import { useAnonymousReportsConfig } from "../../composition/apollo/config";
import { computed, defineAsyncComponent, inject, ref, watch } from "vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useGroup, useLeaveGroup } from "@/composition/apollo/group";
import { useGroupDiscussionsList } from "@/composition/apollo/discussions";
import { useRouter } from "vue-router";
import { useMutation, useQuery } from "@vue/apollo-composable";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";

import Flag from "vue-material-design-icons/Flag.vue";
import ExitToApp from "vue-material-design-icons/ExitToApp.vue";
import AccountMultiplePlus from "vue-material-design-icons/AccountMultiplePlus.vue";

import Cog from "vue-material-design-icons/Cog.vue";
import ViewList from "vue-material-design-icons/ViewList.vue";
import Chat from "vue-material-design-icons/Chat.vue";
import Link from "vue-material-design-icons/Link.vue";

import Information from "vue-material-design-icons/Information.vue";

import Calendar from "vue-material-design-icons/Calendar.vue";
import Bullhorn from "vue-material-design-icons/Bullhorn.vue";
import { useI18n } from "vue-i18n";
import { useCreateReport } from "@/composition/apollo/report";
import { useHead } from "@/utils/head";

import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useGroupResourcesList } from "@/composition/apollo/resources";
import { useGroupMembers } from "@/composition/apollo/members";

const props = defineProps<{
  preferredUsername: string;
}>();

const preferredUsername = computed(() => props.preferredUsername);

const { anonymousReportsConfig } = useAnonymousReportsConfig();
const { currentActor } = useCurrentActorClient();
const {
  group,
  loading: groupLoading,
  refetch: refetchGroup,
} = useGroup(preferredUsername, { afterDateTime: new Date() });
const router = useRouter();

const { group: discussionGroup } = useGroupDiscussionsList(preferredUsername);
const { group: resourcesGroup } = useGroupResourcesList(preferredUsername, {
  resourcesPage: 1,
  resourcesLimit: 3,
});

const { t } = useI18n({ useScope: "global" });

// const { isLongEvents } = useIsLongEvents();

// const { person } = usePersonStatusGroup(group);

const { result, subscribeToMore } = useQuery<{
  person: IPerson;
}>(
  PERSON_STATUS_GROUP,
  () => ({
    id: currentActor.value?.id,
    group: usernameWithDomain(group.value),
  }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined &&
      currentActor.value?.id !== null &&
      currentActor.value?.id !== "" &&
      group.value?.preferredUsername !== undefined &&
      group.value?.preferredUsername !== "" &&
      usernameWithDomain(group.value) !== "",
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: false,
  })
);
// Only subscribe if we have valid values
if (currentActor.value?.id && group.value?.preferredUsername) {
  subscribeToMore<{ actorId: string; group: string }>({
    document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
    variables: {
      actorId: currentActor.value.id,
      group: usernameWithDomain(group.value),
    },
  });
}
const person = computed(() => result.value?.person);

const ShareGroupModal = defineAsyncComponent(
  () => import("@/components/Group/ShareGroupModal.vue")
);

const isReportModalActive = ref(false);
const reportModalRef = ref();
const isShareModalActive = ref(false);
const previewPublic = ref(false);

const notifier = inject<Notifier>("notifier");

watch(
  currentActor,
  (watchedCurrentActor: IActor | undefined, oldActor: IActor | undefined) => {
    if (
      watchedCurrentActor?.id &&
      oldActor &&
      watchedCurrentActor?.id !== oldActor.id
    ) {
      refetchGroup();
    }
  }
);

const { mutate: joinGroupMutation, onError: onJoinGroupError } =
  useMutation(JOIN_GROUP);

const joinGroup = async (): Promise<void> => {
  if (!currentActor.value?.id) {
    router.push({
      name: RouteName.GROUP_JOIN,
      params: { preferredUsername: usernameWithDomain(group.value) },
    });
    return;
  }
  const [groupUsername, currentActorId] = [
    usernameWithDomain(group.value),
    currentActor.value?.id,
  ];

  joinGroupMutation(
    {
      groupId: group.value?.id,
    },
    {
      refetchQueries: [
        {
          query: PERSON_STATUS_GROUP,
          variables: {
            id: currentActorId,
            group: groupUsername,
          },
        },
      ],
    }
  );

  onJoinGroupError((error) => {
    if (error.graphQLErrors && error.graphQLErrors.length > 0) {
      notifier?.error(error.graphQLErrors[0].message);
    }
  });
};

const dialog = inject<Dialog>("dialog");

const openLeaveGroupModal = async (): Promise<void> => {
  dialog?.confirm({
    variant: "danger",
    title: t("Leave group"),
    message: t(
      "Are you sure you want to leave the group {groupName}? You'll loose access to this group's private content. This action cannot be undone.",
      { groupName: `<b>${displayName(group.value)}</b>` }
    ),
    onConfirm: leaveGroup,
    confirmText: t("Leave group"),
    cancelText: t("Cancel"),
  });
};

const {
  mutate: leaveGroupMutation,
  onError: onLeaveGroupError,
  onDone: onLeaveGroupDone,
} = useLeaveGroup();

const leaveGroup = () => {
  console.debug("called leaveGroup");

  const [groupFederatedUsername, currentActorId] = [
    usernameWithDomain(group.value),
    currentActor.value?.id,
  ];

  leaveGroupMutation(
    {
      groupId: group.value?.id,
    },
    {
      refetchQueries: [
        {
          query: PERSON_STATUS_GROUP,
          variables: {
            id: currentActorId,
            group: groupFederatedUsername,
          },
        },
      ],
    }
  );
};

onLeaveGroupError((error: any) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

onLeaveGroupDone(() => {
  console.debug("done");
});

const { mutate: followGroupMutation, onError: onFollowGroupError } =
  useMutation(FOLLOW_GROUP, () => ({
    refetchQueries: [
      {
        query: PERSON_STATUS_GROUP,
        variables: {
          id: currentActor.value?.id,
          group: usernameWithDomain(group.value),
        },
      },
    ],
  }));

onFollowGroupError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const followGroup = async (): Promise<void> => {
  if (!currentActor.value?.id) {
    router.push({
      name: RouteName.GROUP_FOLLOW,
      params: {
        preferredUsername: usernameWithDomain(group.value),
      },
    });
    return;
  }
  followGroupMutation({
    groupId: group.value?.id,
  });
};

const { onError: onUnfollowGroupError } = useMutation(UNFOLLOW_GROUP, () => ({
  refetchQueries: [
    {
      query: PERSON_STATUS_GROUP,
      variables: {
        id: currentActor.value?.id,
        group: usernameWithDomain(group.value),
      },
    },
  ],
}));

onUnfollowGroupError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const {
  mutate: createReportMutation,
  onError: onCreateReportError,
  onDone: onCreateReportDone,
} = useCreateReport();

const reportGroup = (content: string, forward: boolean) => {
  isReportModalActive.value = false;
  console.debug("report group", {
    reportedId: group.value?.id ?? "",
    content,
    forward,
  });

  createReportMutation({
    reportedId: group.value?.id ?? "",
    content,
    forward,
  });
};

onCreateReportDone(() => {
  notifier?.success(
    t("Group {groupTitle} reported", { groupTitle: groupTitle.value })
  );
});

onCreateReportError((error: any) => {
  console.error(error);
  notifier?.error(
    t("Error while reporting group {groupTitle}", {
      groupTitle: groupTitle.value,
    })
  );
});

const triggerShare = (): void => {
  if (navigator.share) {
    navigator
      .share({
        title: displayName(group.value),
        url: group.value?.url,
      })
      .then(() => console.debug("Successful share"))
      .catch((error: any) => console.debug("Error sharing", error));
  } else {
    isShareModalActive.value = true;
    // send popup
  }
};

const groupTitle = computed((): undefined | string => {
  return displayName(group.value);
});

const groupSummary = computed((): undefined | string => {
  return group.value?.summary;
});

useHead({
  title: computed(() => groupTitle.value ?? ""),
  meta: [{ name: "description", content: computed(() => groupSummary.value) }],
});

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const groupMember = computed((): IMember | undefined => {
  if (personMemberships.value?.total > 0) {
    return personMemberships.value?.elements[0];
  }
  return undefined;
});

const isCurrentActorARejectedGroupMember = computed((): boolean => {
  return personMemberships.value.elements
    .filter((membership) => membership.role === MemberRole.REJECTED)
    .map(({ parent: { id } }) => id)
    .includes(group.value?.id);
});

const isCurrentActorAnInvitedGroupMember = computed((): boolean => {
  return personMemberships.value.elements
    .filter((membership) => membership.role === MemberRole.INVITED)
    .map(({ parent: { id } }) => id)
    .includes(group.value?.id);
});

/**
 * New members, if on a different server,
 * can take a while to refresh the group and fetch all private data
 */
const isCurrentActorARecentMember = computed((): boolean => {
  return (
    groupMember.value !== undefined &&
    groupMember.value?.role === MemberRole.MEMBER &&
    addMinutes(new Date(`${groupMember.value?.updatedAt}Z`), 10) > new Date()
  );
});

const isCurrentActorOnADifferentDomainThanGroup = computed((): boolean => {
  return group.value?.domain !== null;
});

// const members = computed((): IMember[] => {
//   return (
//     (group.value?.members?.elements ?? []).filter(
//       (member: IMember) =>
//         ![
//           MemberRole.INVITED,
//           MemberRole.REJECTED,
//           MemberRole.NOT_APPROVED,
//         ].includes(member.role)
//     ) ?? []
//   );
// });

const ableToReport = computed((): boolean => {
  return (
    currentActor.value?.id !== undefined ||
    anonymousReportsConfig.value?.allowed === true
  );
});

const showFollowButton = computed((): boolean => {
  return !isCurrentActorFollowing.value || previewPublic.value;
});

const showJoinButton = computed((): boolean => {
  return !isCurrentActorAGroupMember.value || previewPublic.value;
});

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const isCurrentActorAGroupOwner = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.CREATOR);
});

const isCurrentActorAGroupAdminOrOwner = computed((): boolean => {
  return isCurrentActorAGroupAdmin.value || isCurrentActorAGroupOwner.value;
});

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const isCurrentActorAGroupMember = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
    MemberRole.MEMBER,
  ]);
});

const isGroupPendingApproval = computed((): boolean => {
  return group.value?.approvalStatus === ApprovalStatus.PENDING_APPROVAL;
});

const currentActorFollow = computed((): IFollower | undefined => {
  if (person?.value?.follows?.total && person?.value?.follows?.total > 0) {
    return person?.value?.follows?.elements[0];
  }
  return undefined;
});

const isCurrentActorFollowing = computed((): boolean => {
  return currentActorFollow.value?.approved === true;
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const { members } = useGroupMembers(preferredUsername, {
  enabled: computed(() => isCurrentActorAGroupMember.value),
});

watch(isCurrentActorAGroupMember, () => {
  refetchGroup();
});
</script>
<style lang="scss" scoped>
// Custom animations for geometric shapes
@keyframes float {
  0%,
  100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-10px) rotate(5deg);
  }
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.3;
  }
  50% {
    opacity: 0.6;
  }
}

.geometric-shape {
  animation: float 6s ease-in-out infinite;
}

.geometric-shape:nth-child(2) {
  animation-delay: -2s;
}

.geometric-shape:nth-child(3) {
  animation-delay: -4s;
}

.geometric-shape:nth-child(4) {
  animation-delay: -1s;
}

// Card hover effects
.bg-white:hover {
  transform: translateY(-2px);
  transition: transform 0.2s ease-in-out;
}

// Address styling
address {
  font-style: normal;
}

// Map modal
.map {
  height: 60vh;
  width: 100%;
}

// Grid layout improvements
.grid {
  &.grid-cols-1 {
    @media (min-width: 768px) {
      &.md\\:grid-cols-3 {
        grid-template-columns: repeat(3, 1fr);
        align-items: start;
      }
    }

    @media (min-width: 1024px) {
      &.lg\\:grid-cols-3 {
        grid-template-columns: repeat(3, 1fr);
        align-items: start;
      }
    }
  }
}

// Card height consistency
.h-fit {
  height: fit-content;
}

// Responsive adjustments
@media (max-width: 768px) {
  .grid-cols-1.md\\:grid-cols-3,
  .grid-cols-1.lg\\:grid-cols-3 {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .geometric-shape {
    display: none; // Hide geometric shapes on mobile for better performance
  }

  // Stack cards vertically on mobile with proper spacing
  .bg-white,
  .dark .bg-gray-800 {
    margin-bottom: 1rem;
  }
}

// Improve card spacing on larger screens
@media (min-width: 1024px) {
  .gap-3 {
    gap: 0.5 rem;
  }
}

// 3D Perspective for geometric shapes
.perspective-1000 {
  perspective: 1000px;
}

// Enhanced geometric shape animations
.geometric-shape {
  animation: float 8s ease-in-out infinite;
}

.geometric-shape:nth-child(odd) {
  animation-direction: reverse;
}

// Dark mode specific adjustments
:deep(.dark) {
  .prose {
    color: #d1d5db;
  }

  .prose h1,
  .prose h2,
  .prose h3 {
    color: #f9fafb;
  }
}
</style>
