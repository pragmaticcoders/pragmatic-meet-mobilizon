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
    // Use enhanced meta tag reading with retry logic to handle OAuth callback timing
    const [accessToken, refreshToken, userId, userEmail, userRole] =
      await Promise.all([
        getValueFromMetaWithRetry("auth-access-token"),
        getValueFromMetaWithRetry("auth-refresh-token"),
        getValueFromMetaWithRetry("auth-user-id"),
        getValueFromMetaWithRetry("auth-user-email"),
        getValueFromMetaWithRetry("auth-user-role"),
      ]);

    if (!(userId && userEmail && userRole && accessToken && refreshToken)) {
      console.error("OAuth callback: Missing required authentication data", {
        hasUserId: !!userId,
        hasUserEmail: !!userEmail,
        hasUserRole: !!userRole,
        hasAccessToken: !!accessToken,
        hasRefreshToken: !!refreshToken,
      });
      await router.push({
        name: RouteName.LOGIN,
        query: { code: "oauth_callback_failed" },
      });
      return;
    }

    console.debug("OAuth callback: Successfully retrieved authentication data");

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
  } catch (error) {
    console.error("OAuth callback: Error processing authentication", error);
    await router.push({
      name: RouteName.LOGIN,
      query: { code: "oauth_processing_failed" },
    });
  }
});
</script>
