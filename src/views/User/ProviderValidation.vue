<template>
  <p>{{ t("Redirecting in progress…") }}</p>
</template>

<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import { UPDATE_CURRENT_USER_CLIENT, LOGGED_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { saveUserData } from "../../utils/auth";
import { changeIdentity } from "../../utils/identity";
import { ICurrentUser, IUser } from "../../types/current-user.model";
import { useRouter } from "vue-router";
import { useLazyQuery, useMutation } from "@vue/apollo-composable";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import { computed, onMounted } from "vue";
import { getValueFromMetaWithRetry } from "@/utils/html";

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Redirecting to Mobilizon")),
});

const router = useRouter();

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
    const [accessToken, refreshToken, userId, userEmail, userRole, redirectUrl] =
      await Promise.all([
        getValueFromMetaWithRetry("auth-access-token"),
        getValueFromMetaWithRetry("auth-refresh-token"),
        getValueFromMetaWithRetry("auth-user-id"),
        getValueFromMetaWithRetry("auth-user-email"),
        getValueFromMetaWithRetry("auth-user-role"),
        getValueFromMetaWithRetry("auth-redirect-url"),
      ]);

    console.log("OAuth callback: Meta tag retrieval completed", {
      hasUserId: !!userId,
      hasUserEmail: !!userEmail,
      hasUserRole: !!userRole,
      hasAccessToken: !!accessToken,
      hasRefreshToken: !!refreshToken,
      redirectUrl: redirectUrl || "none",
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

    // Update Apollo cache
    updateCurrentUserClient({
      id: userId,
      email: userEmail,
      isLoggedIn: true,
      role: userRole as ICurrentUserRole,
    });
    
    console.log("OAuth callback: Authentication completed successfully");
    
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
