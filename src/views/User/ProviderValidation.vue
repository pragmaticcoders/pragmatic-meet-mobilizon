<template>
  <p>{{ t("Redirecting in progress…") }}</p>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import { GET_PERSON } from "../../graphql/actor";
import { HOME_USER_QUERIES } from "../../graphql/home";
import RouteName from "../../router/name";
import { saveUserData } from "../../utils/auth";
import { changeIdentity } from "../../utils/identity";
import { ICurrentUser, IUser } from "../../types/current-user.model";
import { IPerson } from "../../types/actor";
import { useRouter } from "vue-router";
import { useLazyQuery, useMutation, useQuery, useApolloClient } from "@vue/apollo-composable";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { computed, onMounted } from "vue";
import { getValueFromMetaWithRetry } from "@/utils/html";

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
    await new Promise(resolve => setTimeout(resolve, 200));
    
    // Use enhanced meta tag reading with retry logic to handle OAuth callback timing
    const [accessToken, refreshToken, userId, userEmail, userRole, redirectUrl, userActorId] =
      await Promise.all([
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
      const errorCode = urlParams.get('code');
      const provider = urlParams.get('provider');
      
      if (errorCode && provider) {
        console.error(`OAuth error detected: ${errorCode} for provider ${provider}`);
        await router.push({
          name: RouteName.LOGIN,
          query: { 
            code: errorCode,
            provider: provider,
            error: "oauth_callback_failed" 
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
    const pathSegments = window.location.pathname.split('/');
    const providerIndex = pathSegments.indexOf('auth');
    const provider = providerIndex !== -1 && pathSegments[providerIndex + 1] 
      ? pathSegments[providerIndex + 1] 
      : null;
    
    if (provider) {
      console.log(`Clearing retry count for successful ${provider} OAuth`);
      sessionStorage.removeItem(`oauth-retry-${provider}`);
    } else {
      // Fallback: clear all oauth retry counts on successful auth
      console.log("Clearing all OAuth retry counts on successful authentication");
      Object.keys(sessionStorage).forEach(key => {
        if (key.startsWith('oauth-retry-')) {
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
        console.log("OAuth callback: Fetching user actor profile", { userActorId });
        
        // Use Apollo client directly to fetch actor data
        const { data: actorData } = await apolloClient.query({
          query: GET_PERSON,
          variables: { actorId: userActorId },
          fetchPolicy: 'network-only'
        });
        
        if (actorData?.person) {
          console.log("OAuth callback: Setting currentActor from fetched profile", { 
            actorId: actorData.person.id,
            name: actorData.person.name 
          });
          
          // Use changeIdentity to properly set the currentActor
          await changeIdentity(actorData.person as IPerson);
        } else {
          console.warn("OAuth callback: No actor data returned for actorId", userActorId);
        }
      } catch (error) {
        console.error("OAuth callback: Failed to fetch and set user actor", error);
        // Don't block the authentication flow if actor fetching fails
      }
    } else {
      console.log("OAuth callback: No user actor ID provided, skipping currentActor setup");
    }
    
    // Wait a bit to ensure cache updates are processed
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Verify that currentUser is now populated in the cache
    const { currentUser: verifyCurrentUser } = useCurrentUserClient();
    console.log("OAuth callback: Verifying currentUser cache state", {
      hasCurrentUser: !!verifyCurrentUser.value,
      currentUserId: verifyCurrentUser.value?.id,
      isLoggedIn: verifyCurrentUser.value?.isLoggedIn
    });
    
    if (!verifyCurrentUser.value?.id) {
      console.warn("OAuth callback: currentUser not found in cache after first update, retrying...");
      
      // Retry the cache update
      try {
        await updateCurrentUserClient({
          id: userId,
          email: userEmail,
          isLoggedIn: true,
          role: userRole as ICurrentUserRole,
        });
        
        await new Promise(resolve => setTimeout(resolve, 200));
        
        console.log("OAuth callback: After retry - currentUser cache state", {
          hasCurrentUser: !!verifyCurrentUser.value,
          currentUserId: verifyCurrentUser.value?.id,
          isLoggedIn: verifyCurrentUser.value?.isLoggedIn
        });
        
        if (!verifyCurrentUser.value?.id) {
          console.error("OAuth callback: currentUser still not in cache after retry, events may not load properly");
        }
      } catch (retryError) {
        console.error("OAuth callback: Failed to retry currentUser cache update", retryError);
      }
    }
    
    console.log("OAuth callback: Authentication completed successfully");
    
    // Trigger a refetch of user queries to ensure events are loaded
    // This helps in case there are any remaining cache timing issues
    if (verifyCurrentUser.value?.id) {
      console.log("OAuth callback: Triggering HOME_USER_QUERIES refetch to ensure events are loaded");
      try {
        await apolloClient.query({
          query: HOME_USER_QUERIES,
          variables: { afterDateTime: new Date().toISOString() },
          fetchPolicy: 'network-only'
        });
        console.log("OAuth callback: HOME_USER_QUERIES refetch completed");
      } catch (refetchError) {
        console.warn("OAuth callback: Failed to refetch HOME_USER_QUERIES, events may need manual refresh", refetchError);
      }
    }
    
    // Redirect to profile settings if coming from LinkedIn, otherwise go to home
    if (redirectUrl) {
      console.log("OAuth callback: Redirecting to profile settings for LinkedIn data review");
      await router.push(redirectUrl);
    } else {
      console.log("OAuth callback: Redirecting to home page");
      await router.push({ name: RouteName.HOME });
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
