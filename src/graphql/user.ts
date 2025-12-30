import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const CREATE_USER = gql`
  mutation CreateUser(
    $email: String!
    $password: String!
    $locale: String
    $marketingConsent: Boolean
  ) {
    createUser(
      email: $email
      password: $password
      locale: $locale
      marketingConsent: $marketingConsent
    ) {
      email
      confirmationSentAt
    }
  }
`;

export const VALIDATE_USER = gql`
  mutation ValidateUser($token: String!) {
    validateUser(token: $token) {
      accessToken
      refreshToken
      user {
        id
        email
        defaultActor {
          ...ActorFragment
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const LOGGED_USER = gql`
  query LoggedUserQuery {
    loggedUser {
      id
      email
      defaultActor {
        ...ActorFragment
      }
      provider
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const CHANGE_PASSWORD = gql`
  mutation ChangePassword($oldPassword: String!, $newPassword: String!) {
    changePassword(oldPassword: $oldPassword, newPassword: $newPassword) {
      id
    }
  }
`;

export const SET_MARKETING_CONSENT = gql`
  mutation SetMarketingConsent($consent: Boolean!) {
    setMarketingConsent(consent: $consent) {
      id
      marketingConsent
      marketingConsentUpdatedAt
    }
  }
`;

export const CHANGE_EMAIL = gql`
  mutation ChangeEmail($email: String!, $password: String!) {
    changeEmail(email: $email, password: $password) {
      id
    }
  }
`;

export const VALIDATE_EMAIL = gql`
  mutation ValidateEmail($token: String!) {
    validateEmail(token: $token) {
      id
    }
  }
`;

export const DELETE_ACCOUNT = gql`
  mutation DeleteAccount($password: String, $userId: ID) {
    deleteAccount(password: $password, userId: $userId) {
      id
    }
  }
`;

export const SUSPEND_USER = gql`
  mutation SuspendUser($userId: ID!) {
    suspendUser(userId: $userId) {
      id
      email
      suspended
    }
  }
`;

export const UNSUSPEND_USER = gql`
  mutation UnsuspendUser($userId: ID!) {
    unsuspendUser(userId: $userId) {
      id
      email
      suspended
    }
  }
`;

export const DELETE_USER = gql`
  mutation DeleteUser($userId: ID!, $permanent: Boolean) {
    deleteAccount(userId: $userId, permanent: $permanent) {
      id
    }
  }
`;

export const CURRENT_USER_CLIENT = gql`
  query CurrentUserClient {
    currentUser @client {
      id
      email
      isLoggedIn
      role
    }
  }
`;

export const UPDATE_CURRENT_USER_CLIENT = gql`
  mutation UpdateCurrentUser(
    $id: String
    $email: String
    $isLoggedIn: Boolean
    $role: UserRole
  ) {
    updateCurrentUser(
      id: $id
      email: $email
      isLoggedIn: $isLoggedIn
      role: $role
    ) @client
  }
`;

export const USER_SETTINGS_FRAGMENT = gql`
  fragment UserSettingFragment on UserSettings {
    timezone
    notificationOnDay
    notificationEachWeek
    notificationBeforeEvent
    notificationPendingParticipation
    notificationPendingMembership
    groupNotifications
    location {
      range
      geohash
      name
    }
  }
`;

export const LOGGED_USER_AND_SETTINGS = gql`
  query LoggedUserQuery {
    loggedUser {
      id
      email
      locale
      provider
      marketingConsent
      marketingConsentUpdatedAt
      defaultActor {
        ...ActorFragment
      }
      settings {
        ...UserSettingFragment
      }
    }
  }
  ${ACTOR_FRAGMENT}
  ${USER_SETTINGS_FRAGMENT}
`;

export const USER_SETTINGS = gql`
  query UserSetting {
    loggedUser {
      id
      locale
      settings {
        ...UserSettingFragment
      }
    }
  }
  ${USER_SETTINGS_FRAGMENT}
`;

export const LOGGED_USER_LOCATION = gql`
  query LoggedUserLocation {
    loggedUser {
      settings {
        location {
          range
          geohash
          name
        }
      }
    }
  }
`;

export const LOGGED_USER_TIMEZONE = gql`
  query LoggedUserTimezone {
    loggedUser {
      id
      settings {
        timezone
      }
    }
  }
`;

export const SET_USER_SETTINGS = gql`
  mutation SetUserSettings(
    $timezone: Timezone
    $notificationOnDay: Boolean
    $notificationEachWeek: Boolean
    $notificationBeforeEvent: Boolean
    $notificationPendingParticipation: NotificationPendingEnum
    $notificationPendingMembership: NotificationPendingEnum
    $groupNotifications: NotificationPendingEnum
    $location: LocationInput
  ) {
    setUserSettings(
      timezone: $timezone
      notificationOnDay: $notificationOnDay
      notificationEachWeek: $notificationEachWeek
      notificationBeforeEvent: $notificationBeforeEvent
      notificationPendingParticipation: $notificationPendingParticipation
      notificationPendingMembership: $notificationPendingMembership
      groupNotifications: $groupNotifications
      location: $location
    ) {
      ...UserSettingFragment
    }
  }
  ${USER_SETTINGS_FRAGMENT}
`;

export const USER_NOTIFICATIONS = gql`
  query UserNotifications {
    loggedUser {
      id
      locale
      settings {
        ...UserSettingFragment
      }
      feedTokens {
        token
        actor {
          id
        }
      }
      activitySettings {
        key
        method
        enabled
      }
    }
  }
  ${USER_SETTINGS_FRAGMENT}
`;

export const USER_FRAGMENT_FEED_TOKENS = gql`
  fragment UserFeedTokensFragment on User {
    id
    feedTokens {
      token
    }
  }
`;

export const UPDATE_ACTIVITY_SETTING = gql`
  mutation UpdateActivitySetting(
    $key: String!
    $method: String!
    $enabled: Boolean!
  ) {
    updateActivitySetting(key: $key, method: $method, enabled: $enabled) {
      key
      method
      enabled
    }
  }
`;

export const LIST_USERS = gql`
  query ListUsers(
    $email: String
    $currentSignInIp: String
    $page: Int
    $limit: Int
    $sort: SortableUserField
    $direction: SortDirection
  ) {
    users(
      email: $email
      currentSignInIp: $currentSignInIp
      page: $page
      limit: $limit
      sort: $sort
      direction: $direction
    ) {
      total
      elements {
        id
        email
        locale
        confirmedAt
        currentSignInIp
        currentSignInAt
        disabled
        marketingConsent
        marketingConsentUpdatedAt
        actors {
          ...ActorFragment
        }
        settings {
          timezone
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const GET_USER = gql`
  query GetUser(
    $id: ID!
    $organizedEventsPage: Int
    $organizedEventsLimit: Int
    $participationsPage: Int
    $participationsLimit: Int
    $membershipsPage: Int
    $membershipsLimit: Int
  ) {
    user(id: $id) {
      id
      email
      confirmedAt
      confirmationSentAt
      lastSignInAt
      lastSignInIp
      currentSignInIp
      currentSignInAt
      locale
      disabled
      suspended
      mediaSize
      marketingConsent
      marketingConsentUpdatedAt
      defaultActor {
        ...ActorFragment
        suspended
        mediaSize
        avatar {
          uuid
          name
          url
          alt
        }
        banner {
          uuid
          url
        }
        organizedEvents(
          page: $organizedEventsPage
          limit: $organizedEventsLimit
        ) {
          total
          elements {
            id
            uuid
            title
            beginsOn
            status
          }
        }
        participations(page: $participationsPage, limit: $participationsLimit) {
          total
          elements {
            id
            event {
              id
              uuid
              title
              beginsOn
              status
            }
          }
        }
        memberships(page: $membershipsPage, limit: $membershipsLimit) {
          total
          elements {
            id
            role
            insertedAt
            parent {
              ...ActorFragment
            }
          }
        }
      }
      actors {
        ...ActorFragment
      }
      participations {
        total
      }
      role
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const UPDATE_USER_LOCALE = gql`
  mutation UpdateUserLocale($locale: String!) {
    updateLocale(locale: $locale) {
      id
      locale
    }
  }
`;

export const FEED_TOKENS_LOGGED_USER = gql`
  query FeedTokensLoggedUser {
    loggedUser {
      id
      feedTokens {
        token
        actor {
          id
        }
      }
    }
  }
`;

export const UNREAD_ACTOR_CONVERSATIONS = gql`
  query LoggedUserUnreadConversations {
    loggedUser {
      id
      defaultActor {
        id
        unreadConversationsCount
      }
    }
  }
`;

export const UNREAD_ACTOR_CONVERSATIONS_SUBSCRIPTION = gql`
  subscription OnUreadActorConversationsChanged($personId: ID!) {
    personUnreadConversationsCount(personId: $personId)
  }
`;
