import { UPDATE_CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
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

/**
 * Change the current actor to a specific identity
 */
export async function changeIdentity(identity: IPerson): Promise<void> {
  console.debug("Changing current actor to identity", identity);

  if (!identity.id) {
    console.warn("Cannot change to identity without id");
    return;
  }

  // Update current actor in cache
  await updateCurrentActorClient(identity);

  console.debug("Saving actor data");
  saveActorData(identity);

  onUpdateCurrentActorClientDone(() => {
    console.debug("Current actor changed successfully");
  });
}
