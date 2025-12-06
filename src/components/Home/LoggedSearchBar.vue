<template>
  <section class="mx-auto mt-8 mb-12">
    <!-- Catchy header -->
    <h1 class="text-3xl font-bold text-gray-900 text-center mb-8">
      {{ t("What will you discover today?") }}
    </h1>

    <!-- Custom search form with inline button -->
    <form
      id="home-search-form"
      class="container mx-auto flex flex-col items-stretch gap-3 justify-center px-4 py-3"
      role="search"
      @submit.prevent="handleSearch"
    >
      <div
        class="flex flex-col gap-3 sm:flex-row sm:gap-2 justify-center items-stretch sm:items-center"
      >
        <label class="sr-only" for="home_search_field_input">{{
          t("Keyword, event title, group name, etc.")
        }}</label>
        <div class="flex-1 min-w-0">
          <o-input
            class="w-full h-11 sm:h-10"
            v-model="searchQuery"
            :placeholder="t('Keyword, event title, group name, etc.')"
            id="home_search_field_input"
            autocapitalize="off"
            autocomplete="off"
            autocorrect="off"
            maxlength="1024"
            expanded
          />
        </div>
        <div class="flex flex-col sm:flex-row gap-2 sm:gap-1 flex-shrink-0">
          <div class="flex-1 sm:flex-initial min-w-0">
            <full-address-auto-complete
              :resultType="AddressSearchType.ADMINISTRATIVE"
              v-model="address"
              :hide-map="true"
              :hide-selected="true"
              :default-text="addressDefaultText"
              labelClass="sr-only"
              :placeholder="t('Entire Poland and remote')"
              class="w-full"
              @update:modelValue="handleAddressChange"
            />
          </div>
          <o-dropdown
            v-model="distance"
            position="bottom-right"
            v-if="address && distance"
            class="flex-shrink-0"
          >
            <template #trigger="{ active }">
              <o-button
                class="w-full sm:w-auto px-3 text-sm"
                style="height: 48px"
                :title="t('Select distance')"
                :icon-right="active ? 'menu-up' : 'menu-down'"
              >
                {{ distanceText }}
              </o-button>
            </template>
            <o-dropdown-item
              v-for="distance_item in distanceList"
              :value="distance_item.distance"
              :label="distance_item.label"
              :key="distance_item.distance"
            />
          </o-dropdown>
        </div>
        
        <!-- Search button inline -->
        <o-button
          type="submit"
          variant="primary"
          class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded transition-colors flex-shrink-0"
          style="height: 48px"
        >
          {{ t("Search") }}
        </o-button>
      </div>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { ref, computed, defineAsyncComponent, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import { IAddress } from "@/types/address.model";
import { AddressSearchType } from "@/types/enums";
import { addressToLocation, getAddressFromLocal, storeAddressInLocal } from "@/utils/location";
import RouteName from "@/router/name";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const { t } = useI18n({ useScope: "global" });
const router = useRouter();

const searchQuery = ref<string>("");
const address = ref<IAddress | null>(null);
const distance = ref<number | null>(null);
const addressDefaultText = ref<string | null>(null);

// Initialize address from localStorage on mount
onMounted(() => {
  const localAddress = getAddressFromLocal();
  if (localAddress) {
    address.value = localAddress;
    addressDefaultText.value = localAddress.description;
    // Set default distance when location is loaded
    distance.value = 10;
  }
});

const distanceText = computed(() => {
  return distance.value + " km";
});

const distanceList = computed(() => {
  const distances: { distance: number; label: string }[] = [];
  [5, 10, 25, 50, 100, 150].forEach((value) => {
    distances.push({
      distance: value,
      label: t(
        "{number} kilometers",
        {
          number: value,
        },
        value
      ),
    });
  });
  return distances;
});

// Handle address changes
const handleAddressChange = (newAddress: IAddress | null) => {
  if (newAddress) {
    // Set default distance when an address is selected
    if (distance.value === null) {
      distance.value = 10;
    }
    // Store address in localStorage
    storeAddressInLocal(newAddress);
  } else {
    // Clear distance when address is cleared
    distance.value = null;
    // Clear address from localStorage
    storeAddressInLocal(null);
  }
};

const handleSearch = () => {
  const searchQueryParams: {
    search?: string;
    locationName?: string;
    lat?: number;
    lon?: number;
    distance?: string;
    onlineFilter?: string;
  } = {};

  // Add search query if present
  if (searchQuery.value && searchQuery.value.trim() !== "") {
    searchQueryParams.search = searchQuery.value;
  }

  // Add location and distance if address is set
  if (address.value) {
    const location = addressToLocation(address.value);
    searchQueryParams.locationName =
      address.value.locality ?? address.value.region;
    if (location) {
      searchQueryParams.lat = location.lat;
      searchQueryParams.lon = location.lon;
    }
    if (distance.value != null) {
      searchQueryParams.distance = distance.value.toString() + "_km";
    }
  } else {
    // If no location is selected, automatically include online events
    searchQueryParams.onlineFilter = "include_online";
  }

  // Navigate to search page with query params
  router.push({
    name: RouteName.SEARCH,
    query: searchQueryParams,
  });
};
</script>

