<template>
  <div class="relative">
    <o-taginput
      :modelValue="modelValueWithDisplayName"
      @update:modelValue="updateTags"
      :data="availableActors"
      :loading="searchLoading"
      :allow-autocomplete="true"
      :allow-new="false"
      :open-on-focus="false"
      field="displayName"
      :placeholder="searchLoading ? t('Searching...') : t('Add a recipient')"
      @input="getActors"
    >
      <template #default="props">
        <ActorInline :actor="props.option" />
      </template>

      <template #empty>
        <div v-if="searchLoading" class="p-3 text-center text-gray-500">
          <div class="flex items-center justify-center gap-2">
            <svg
              class="animate-spin h-4 w-4 text-gray-400"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              ></circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              ></path>
            </svg>
            {{ t("Searching for recipients...") }}
          </div>
        </div>
        <div
          v-else-if="
            currentSearchTerm && !searchLoading && availableActors.length === 0
          "
          class="p-3 text-center text-gray-500"
        >
          {{ t("No users or groups found") }}
        </div>
      </template>
    </o-taginput>

    <!-- Additional loading indicator overlay -->
    <div
      v-if="searchLoading"
      class="absolute inset-y-0 right-3 flex items-center pointer-events-none"
    >
      <svg
        class="animate-spin h-4 w-4 text-gray-400"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle
          class="opacity-25"
          cx="12"
          cy="12"
          r="10"
          stroke="currentColor"
          stroke-width="4"
        ></circle>
        <path
          class="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        ></path>
      </svg>
    </div>
  </div>
</template>

<script setup lang="ts">
import { SEARCH_PERSON_AND_GROUPS } from "@/graphql/search";
import { IActor, IGroup, IPerson, displayName } from "@/types/actor";
import { Paginate } from "@/types/paginate";
import { useLazyQuery } from "@vue/apollo-composable";
import { computed, ref } from "vue";
import ActorInline from "./ActorInline.vue";
import { useI18n } from "vue-i18n";
import { debounce } from "lodash";

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

const availableActors = ref<IActor[]>([]);
const searchLoading = ref(false);
const currentSearchTerm = ref("");

// Search both persons and groups (now available to all users)
const {
  load: loadSearchPersonsAndGroupsQuery,
  onResult: onSearchPersonsAndGroupsResult,
  onError: onSearchPersonsAndGroupsError,
} = useLazyQuery<
  { searchPersons: Paginate<IPerson>; searchGroups: Paginate<IGroup> },
  { searchText: string }
>(SEARCH_PERSON_AND_GROUPS);

// Handle successful search results for persons and groups
onSearchPersonsAndGroupsResult((result) => {
  // Always stop loading when we get any result, even if it's outdated
  searchLoading.value = false;
  
  if (result.data) {
    const persons = result.data.searchPersons?.elements || [];
    const groups = result.data.searchGroups?.elements || [];

    const actors: IActor[] = [
      ...persons.map((person) => ({
        ...person,
        displayName: displayName(person),
      })),
      ...groups.map((group) => ({
        ...group,
        displayName: displayName(group),
      })),
    ];
    availableActors.value = actors;
  } else {
    availableActors.value = [];
  }
});

// Handle search errors
onSearchPersonsAndGroupsError((error) => {
  console.error("Failed to search persons and groups:", error);
  searchLoading.value = false;
  availableActors.value = [];
});

const performSearch = (text: string) => {
  if (text.trim() === "") {
    availableActors.value = [];
    searchLoading.value = false;
    currentSearchTerm.value = "";
    return;
  }

  // Always update the search term and set loading
  currentSearchTerm.value = text;
  searchLoading.value = true;

  // Search both persons and groups (available to all users now)
  loadSearchPersonsAndGroupsQuery(SEARCH_PERSON_AND_GROUPS, {
    searchText: text,
  });
};

// Debounce the search to avoid too many requests
const debouncedSearch = debounce(performSearch, 300);

const getActors = (text: string) => {
  debouncedSearch(text);
};
</script>
