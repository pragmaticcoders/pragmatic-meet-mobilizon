<template>
  <p>{{ t("Redirecting in progress…") }}</p>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import { GET_PERSON } from "../../graphql/actor";
import RouteName from "../../router/name";
import { saveUserData } from "../../utils/auth";
import { changeIdentity } from "../../utils/identity";
import { ICurrentUser, IUser } from "../../types/current-user.model";
import { IPerson } from "../../types/actor";
import { useRouter } from "vue-router";
import {
  useLazyQuery,
  useMutation,
  useApolloClient,
} from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { computed, onMounted } from "vue";
import { getValueFromMetaWithRetry } from "@/utils/html";
import { AUTH_ACCESS_TOKEN } from "@/constants";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Redirecting to Mobilizon")),
});

const router = useRouter();
const { client: apolloClient } = useApolloClient();

const {
  onDone: onUpdateCurrentUserClientDone,
  mutate: updateCurrentUserClient,
} = useMutation<
  { updateCurrentUser: ICurrentUser },
  { id: string; email: string; isLoggedIn: boolean; role: ICurrentUserRole }
>(UPDATE_CURRENT_USER_CLIENT);

const { load: loadUser } = useLazyQuery<{
  loggedUser: IUser;
}>(LOGGED_USER);

onUpdateCurrentUserClientDone(async () => {
  try {
    const result = await loadUser();
    if (!result) return;
    const loggedUser = result.loggedUser;
    if (loggedUser.defaultActor) {
      await changeIdentity(loggedUser.defaultActor);
      await router.push({ name: RouteName.HOME });
    } else {
      // No need to push to CREATE_IDENTITY, the navbar will do it for us
    }
  } catch (e) {
    console.error(e);
  }
});

onMounted(async () => {
  try {
    console.log("OAuth callback: Starting authentication data retrieval");

    // Wait a bit for the page to fully load
    await new Promise((resolve) => setTimeout(resolve, 200));

    // Use enhanced meta tag reading with retry logic to handle OAuth callback timing
    const [
      accessToken,
      refreshToken,
      userId,
      userEmail,
      userRole,
      redirectUrl,
      userActorId,
    ] = await Promise.all([
      getValueFromMetaWithRetry("auth-access-token"),
      getValueFromMetaWithRetry("auth-refresh-token"),
      getValueFromMetaWithRetry("auth-user-id"),
      getValueFromMetaWithRetry("auth-user-email"),
      getValueFromMetaWithRetry("auth-user-role"),
      getValueFromMetaWithRetry("auth-redirect-url"),
      getValueFromMetaWithRetry("auth-user-actor-id"),
    ]);

    console.log("OAuth callback: Meta tag retrieval completed", {
      hasUserId: !!userId,
      hasUserEmail: !!userEmail,
      hasUserRole: !!userRole,
      hasAccessToken: !!accessToken,
      hasRefreshToken: !!refreshToken,
      redirectUrl: redirectUrl || "none",
      hasUserActorId: !!userActorId,
    });

    if (!(userId && userEmail && userRole && accessToken && refreshToken)) {
      console.error("OAuth callback: Missing required authentication data", {
        userId: userId || "MISSING",
        userEmail: userEmail || "MISSING",
        userRole: userRole || "MISSING",
        hasAccessToken: !!accessToken,
        hasRefreshToken: !!refreshToken,
        currentUrl: window.location.href,
        documentTitle: document.title,
      });

      // Check if this is actually an OAuth error redirect
      const urlParams = new URLSearchParams(window.location.search);
      const errorCode = urlParams.get("code");
      const provider = urlParams.get("provider");

      if (errorCode && provider) {
        console.error(
          `OAuth error detected: ${errorCode} for provider ${provider}`
        );
        await router.push({
          name: RouteName.LOGIN,
          query: {
            code: errorCode,
            provider: provider,
            error: "oauth_callback_failed",
          },
        });
      } else {
        await router.push({
          name: RouteName.LOGIN,
          query: { code: "oauth_callback_failed" },
        });
      }
      return;
    }

    console.log("OAuth callback: Successfully retrieved authentication data");

    // Clear any stored retry counts on successful OAuth
    // Try to detect provider from URL path (e.g., /auth/linkedin/callback)
    const pathSegments = window.location.pathname.split("/");
    const providerIndex = pathSegments.indexOf("auth");
    const provider =
      providerIndex !== -1 && pathSegments[providerIndex + 1]
        ? pathSegments[providerIndex + 1]
        : null;

    if (provider) {
      console.log(`Clearing retry count for successful ${provider} OAuth`);
      sessionStorage.removeItem(`oauth-retry-${provider}`);
    } else {
      // Fallback: clear all oauth retry counts on successful auth
      console.log(
        "Clearing all OAuth retry counts on successful authentication"
      );
      Object.keys(sessionStorage).forEach((key) => {
        if (key.startsWith("oauth-retry-")) {
          sessionStorage.removeItem(key);
        }
      });
    }

    const login = {
      user: {
        id: userId,
        email: userEmail,
        role: userRole as ICurrentUserRole,
        isLoggedIn: true,
        defaultActor: undefined,
        actors: [],
      },
      accessToken,
      refreshToken,
    };

    // Save authentication data
    saveUserData(login);

    // Verify token was properly stored in localStorage before making GraphQL queries
    const storedToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
    if (storedToken !== accessToken) {
      console.error("OAuth callback: Token storage verification failed!", {
        expectedTokenPresent: !!accessToken,
        storedTokenPresent: !!storedToken,
        tokensMatch: storedToken === accessToken,
      });
    } else {
      console.log("OAuth callback: Token successfully verified in localStorage");
    }

    console.log("OAuth callback: Updating Apollo currentUser cache", {
      id: userId,
      email: userEmail,
      isLoggedIn: true,
      role: userRole as ICurrentUserRole,
    });

    // Update Apollo cache
    await updateCurrentUserClient({
      id: userId,
      email: userEmail,
      isLoggedIn: true,
      role: userRole as ICurrentUserRole,
    });

    console.log("OAuth callback: currentUser cache update completed");

    // If user has an actor profile, fetch and set it as currentActor
    if (userActorId && userActorId !== "null" && userActorId !== "") {
      try {
        console.log("OAuth callback: Fetching user actor profile", {
          userActorId,
        });

        // Use Apollo client directly to fetch actor data
        const { data: actorData } = await apolloClient.query({
          query: GET_PERSON,
          variables: { actorId: userActorId },
          fetchPolicy: "network-only",
        });

        if (actorData?.person) {
          console.log(
            "OAuth callback: Setting currentActor from fetched profile",
            {
              actorId: actorData.person.id,
              name: actorData.person.name,
            }
          );

          // Use changeIdentity to properly set the currentActor
          await changeIdentity(actorData.person as IPerson);
        } else {
          console.warn(
            "OAuth callback: No actor data returned for actorId",
            userActorId
          );
        }
      } catch (error) {
        console.error(
          "OAuth callback: Failed to fetch and set user actor",
          error
        );
        // Don't block the authentication flow if actor fetching fails
      }
    } else {
      console.log(
        "OAuth callback: No user actor ID provided, skipping currentActor setup"
      );
    }

    console.log("OAuth callback: Authentication data saved successfully");

    // Redirect to profile settings if coming from LinkedIn, otherwise go to home
    // Use window.location for a hard navigation to ensure all Vue components
    // properly initialize with the new auth state from localStorage
    if (redirectUrl) {
      console.log(
        "OAuth callback: Redirecting to profile settings for LinkedIn data review"
      );
      window.location.href = redirectUrl;
    } else {
      console.log("OAuth callback: Redirecting to home page");
      window.location.href = "/";
    }
  } catch (error) {
    console.error("OAuth callback: Error processing authentication", error);
    await router.push({
      name: RouteName.LOGIN,
      query: { code: "oauth_processing_failed" },
    });
  }
});
</script>
