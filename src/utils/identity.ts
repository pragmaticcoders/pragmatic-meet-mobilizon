import { UPDATE_CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { AUTH_USER_ACTOR_ID } from "@/constants";
import { saveActorData } from "@/utils/auth";
import { provideApolloClient, useMutation } from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";
import { PROFILE_CONVERSATIONS } from "@/graphql/event";

export class NoIdentitiesException extends Error {}

const {
  mutate: updateCurrentActorClient,
  onDone: onUpdateCurrentActorClientDone,
} = provideApolloClient(apolloClient)(() =>
  useMutation(UPDATE_CURRENT_ACTOR_CLIENT)
);

export async function changeIdentity(identity: IPerson | undefined): Promise<void> {
  if (!identity || !identity.id) {
    console.debug("Invalid identity provided", identity);
    return;
  }
  console.debug("Changing identity", identity);

  // Update current actor in cache
  await updateCurrentActorClient(identity);

  console.debug("Saving actor data");
  saveActorData(identity);

  // Clear profile-specific cache data and refetch for new profile
  try {
    // Clear conversation cache for clean state
    apolloClient.cache.evict({
      fieldName: "loggedPerson",
    });

    // Clear specific conversation-related cache entries
    apolloClient.cache.evict({
      fieldName: "conversations",
    });

    // Force garbage collection of evicted cache entries
    apolloClient.cache.gc();

    console.debug("Cache cleared for profile switch");

    // Refetch profile-specific data for the new identity
    // This ensures conversations and other profile data are loaded fresh
    await apolloClient
      .query({
        query: PROFILE_CONVERSATIONS,
        variables: { page: 1, limit: 10 },
        fetchPolicy: "network-only", // Force fresh fetch from server
      })
      .catch((error) => {
        console.debug(
          "Could not refetch conversations after profile switch:",
          error
        );
        // Don't throw - this is not critical for the profile switch to succeed
      });

    console.debug("Profile-specific data refetched");
  } catch (error) {
    console.warn(
      "Error during cache cleanup/refetch after profile switch:",
      error
    );
    // Don't throw - profile switch should still succeed
  }

  onUpdateCurrentActorClientDone(() => {
    console.debug("Current actor client updated successfully");
  });
}

/**
 * We fetch from localStorage the latest actor ID used,
 * then fetch the current identities to set in cache
 * the current identity used
 */
export async function initializeCurrentActor(
  identities: IPerson[] | undefined
): Promise<void> {
  const actorId = localStorage.getItem(AUTH_USER_ACTOR_ID);
  console.debug("Initializing current actor", actorId);

  if (!identities) {
    console.debug("Failed to load user's identities", identities);
    return;
  }

  if (identities && identities.length < 1) {
    console.warn("Logged user has no identities!");
    throw new NoIdentitiesException();
  }
  const activeIdentity =
    (identities || []).find(
      (identity: IPerson | undefined) => identity?.id === actorId
    ) || ((identities || [])[0] as IPerson);

  if (activeIdentity) {
    await changeIdentity(activeIdentity);
  }
}
