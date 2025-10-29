import { UPDATE_CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { AUTH_USER_ACTOR_ID } from "@/constants";
import { saveActorData } from "@/utils/auth";
import { provideApolloClient, useMutation } from "@vue/apollo-composable";
import { apolloClient } from "@/vue-apollo";

export class NoIdentitiesException extends Error {}

const {
  mutate: updateCurrentActorClient,
  onDone: onUpdateCurrentActorClientDone,
} = provideApolloClient(apolloClient)(() =>
  useMutation(UPDATE_CURRENT_ACTOR_CLIENT)
);

/**
 * Set the current actor to the specified identity
 * Use this when you have a single IPerson object (e.g., from defaultActor)
 */
export async function changeIdentity(identity: IPerson | undefined): Promise<void> {
  console.debug("Setting current actor", identity);

  if (!identity || !identity.id) {
    console.debug("Invalid identity provided", identity);
    return;
  }

  console.debug("Initializing current actor from identity", identity);

  // Update current actor in cache
  await updateCurrentActorClient(identity);

  console.debug("Saving actor data");
  saveActorData(identity);

  onUpdateCurrentActorClientDone(() => {
    console.debug("Current actor client updated successfully");
  });
}

/**
 * Initialize the current actor from user's single identity
 */
export async function initializeCurrentActor(
  identities: IPerson[] | undefined
): Promise<void> {
  console.debug("Initializing current actor");

  if (!identities) {
    console.debug("Failed to load user's identities", identities);
    return;
  }

  if (identities && identities.length < 1) {
    console.warn("Logged user has no identities!");
    throw new NoIdentitiesException();
  }

  // User should only have one identity, use it
  const identity = identities[0] as IPerson;

  if (!identity.id) return;
  console.debug("Setting current actor to user's single identity", identity);

  // Update current actor in cache
  await updateCurrentActorClient(identity);

  if (identity.id) {
    console.debug("Saving actor data");
    saveActorData(identity);
  }

  onUpdateCurrentActorClientDone(() => {
    console.debug("Current actor client updated successfully");
  });
}
