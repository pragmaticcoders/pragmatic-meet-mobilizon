<template>
  <o-taginput
    :modelValue="modelValueWithDisplayName"
    @update:modelValue="updateTags"
    :data="availableActors"
    :allow-autocomplete="true"
    :allow-new="false"
    :open-on-focus="false"
    field="displayName"
    :placeholder="t('Add a recipient')"
    @input="getActors"
  >
    <template #default="props">
      <ActorInline :actor="props.option" />
    </template>
  </o-taginput>
</template>

<script setup lang="ts">
import { SEARCH_PERSON_AND_GROUPS, SEARCH_GROUPS } from "@/graphql/search";
import { IActor, IGroup, IPerson, displayName } from "@/types/actor";
import { Paginate } from "@/types/paginate";
import { useLazyQuery } from "@vue/apollo-composable";
import { computed, ref } from "vue";
import ActorInline from "./ActorInline.vue";
import { useI18n } from "vue-i18n";

const emit = defineEmits<{
  "update:modelValue": [value: IActor[]];
}>();

const updateTags = (val: IActor[]) => {
  emit("update:modelValue", val);
};

const props = defineProps<{
  modelValue: IActor[];
}>();

const modelValue = computed(() => props.modelValue);

const modelValueWithDisplayName = computed(() =>
  modelValue.value.map((actor) => ({
    ...actor,
    displayName: displayName(actor),
  }))
);

const { t } = useI18n({ useScope: "global" });

// Try to search both persons and groups (requires admin/moderator for persons)
const {
  load: loadSearchPersonsAndGroupsQuery,
  refetch: refetchSearchPersonsAndGroupsQuery,
} = useLazyQuery<
  { searchPersons: Paginate<IPerson>; searchGroups: Paginate<IGroup> },
  { searchText: string }
>(SEARCH_PERSON_AND_GROUPS);

// Fallback to search only groups (available to all users)
const {
  load: loadSearchGroupsQuery,
  refetch: refetchSearchGroupsQuery,
} = useLazyQuery<
  { searchGroups: Paginate<IGroup> },
  { term: string }
>(SEARCH_GROUPS);

const availableActors = ref<IActor[]>([]);
const canSearchPersons = ref(true); // Initially assume we can search persons

const getActors = async (text: string) => {
  availableActors.value = await fetchActors(text);
};

const fetchActors = async (text: string): Promise<IActor[]> => {
  if (text === "") return [];

  // First try to search both persons and groups if we think we have permission
  if (canSearchPersons.value) {
    try {
      const res =
        (await loadSearchPersonsAndGroupsQuery(SEARCH_PERSON_AND_GROUPS, {
          searchText: text,
        })) ||
        (
          await refetchSearchPersonsAndGroupsQuery({
            searchText: text,
          })
        )?.data;
      if (!res) return [];
      return [
        ...res.searchPersons.elements.map((person) => ({
          ...person,
          displayName: displayName(person),
        })),
        ...res.searchGroups.elements.map((group) => ({
          ...group,
          displayName: displayName(group),
        })),
      ];
    } catch (e) {
      console.warn("Cannot search persons (likely requires admin/moderator permissions), falling back to groups only");
      canSearchPersons.value = false; // Remember we can't search persons
      // Fall through to groups-only search
    }
  }

  // Fallback: search only groups (available to all users)
  try {
    const res =
      (await loadSearchGroupsQuery(SEARCH_GROUPS, {
        term: text,
      })) ||
      (
        await refetchSearchGroupsQuery({
          term: text,
        })
      )?.data;
    if (!res) return [];
    return res.searchGroups.elements.map((group) => ({
      ...group,
      displayName: displayName(group),
    }));
  } catch (e) {
    console.error("Failed to search groups:", e);
    return [];
  }
};
</script>
