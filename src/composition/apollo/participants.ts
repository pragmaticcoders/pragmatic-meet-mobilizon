import { PARTICIPANTS } from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import { useQuery } from "@vue/apollo-composable";
import { computed, Ref, unref } from "vue";

type useEventParticipantsOptions = {
  page?: number;
  limit?: number;
  roles?: string;
};

export function useEventParticipants(
  eventUuid: string | undefined | Ref<string | undefined>,
  options: useEventParticipantsOptions = {}
) {
  const { result, error, loading, onResult, onError, refetch } = useQuery<
    {
      event: IEvent;
    },
    {
      uuid: string;
      page?: number;
      limit?: number;
      roles?: string;
    }
  >(
    PARTICIPANTS,
    () => ({
      uuid: unref(eventUuid) as string,
      page: options.page ?? 1,
      limit: options.limit ?? 10,
      roles: options.roles ?? "",
    }),
    () => ({
      enabled: unref(eventUuid) !== undefined && unref(eventUuid) !== "",
      fetchPolicy: "cache-and-network",
      notifyOnNetworkStatusChange: false,
    })
  );

  const event = computed(() => result.value?.event);
  const participants = computed(
    () => result.value?.event?.participants?.elements ?? []
  );
  const participantStats = computed(
    () => result.value?.event?.participantStats
  );

  const participantsTotal = computed(
    () => result.value?.event?.participants?.total ?? 0
  );

  return {
    event,
    participants,
    participantsTotal,
    participantStats,
    error,
    loading,
    onResult,
    onError,
    refetch,
  };
}
