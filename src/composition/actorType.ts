import { computed } from "vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { ActorType } from "@/types/enums";

/**
 * Composition helper to check if the current actor is a group
 */
export function useCurrentActorType() {
  const { currentActor } = useCurrentActorClient();

  const isCurrentActorGroup = computed(() => {
    return currentActor.value?.type === ActorType.GROUP;
  });

  const isCurrentActorPerson = computed(() => {
    return currentActor.value?.type === ActorType.PERSON;
  });

  const currentActorType = computed(() => {
    return currentActor.value?.type;
  });

  return {
    currentActor,
    isCurrentActorGroup,
    isCurrentActorPerson,
    currentActorType,
  };
}
