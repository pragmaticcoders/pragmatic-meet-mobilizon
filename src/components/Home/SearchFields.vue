<template>
  <form
    id="search-anchor"
    class="container mx-auto flex flex-col items-stretch gap-3 justify-center dark:text-slate-100 px-4 py-3 min-h-[60px]"
    role="search"
    @submit.prevent="submit"
  >
    <div
      class="flex flex-col gap-3 sm:flex-row sm:gap-2 justify-center items-stretch sm:items-center"
    >
      <label class="sr-only" for="search_field_input">{{
        t("Keyword, event title, group name, etc.")
      }}</label>
      <div class="flex-1 min-w-0">
        <o-input
          class="w-full h-11 sm:h-10"
          v-if="search != null"
          v-model="search"
          :placeholder="t('Keyword, event title, group name, etc.')"
          id="search_field_input"
          autofocus
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
            :placeholder="t('e.g. Nantes, Berlin, Cork, …')"
            v-on:update:modelValue="modelValueUpdate"
            class="w-full"
          />
        </div>
        <o-dropdown
          v-model="distance"
          position="bottom-right"
          v-if="distance"
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
    </div>
  </form>
</template>

<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { AddressSearchType, ContentType } from "@/types/enums";
import {
  addressToLocation,
  getAddressFromLocal,
  storeAddressInLocal,
} from "@/utils/location";
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter, useRoute } from "vue-router";
import RouteName from "@/router/name";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const props = defineProps<{
  address: IAddress | null;
  addressDefaultText?: string | null;
  search: string | null;
  distance: number | null;
  fromLocalStorage?: boolean | false;
  numberOfSearch: object | null;
}>();

const router = useRouter();
const route = useRoute();

const emit = defineEmits<{
  (event: "update:address", address: IAddress | null): void;
  (event: "update:search", newSearch: string): void;
  (event: "update:distance", newDistance: number): void;
  (event: "submit"): void;
}>();

const address = computed({
  get(): IAddress | null {
    console.debug("-- get address --", props);
    if (props.address) {
      return props.address;
    }
    if (props.fromLocalStorage) {
      return getAddressFromLocal();
    }
    return null;
  },
  set(newAddress: IAddress | null) {
    emit("update:address", newAddress);
    if (props.fromLocalStorage) {
      storeAddressInLocal(newAddress);
    }
  },
});

const search = computed({
  get(): string {
    return props.search ?? "";
  },
  set(newSearch: string) {
    emit("update:search", newSearch);
  },
});

const distance = computed({
  get(): number {
    return props.distance ?? 0;
  },
  set(newDistance: number) {
    emit("update:distance", newDistance);
  },
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

console.debug("initial", distance.value, search.value, address.value);

const modelValueUpdate = (newaddress: IAddress | null) => {
  emit("update:address", newaddress);
};

const submit = (event: Event) => {
  emit("submit");
  const btn_classes =
    (event as SubmitEvent).submitter?.getAttribute("class")?.split(" ") || [];
  const search_query: {
    locationName?: string;
    lat?: number;
    lon?: number;
    search?: string;
    distance?: string;
    contentType?: string;
    onlineFilter?: string;
  } = {};
  if (search.value != "") {
    search_query.search = search.value;
  }
  if (address.value) {
    const location = addressToLocation(address.value);
    search_query.locationName = address.value.locality ?? address.value.region;
    if (location) {
      search_query.lat = location.lat;
      search_query.lon = location.lon;
    }
    if (distance.value != null) {
      search_query.distance = distance.value.toString() + "_km";
    }
  } else {
    // If no location is selected, automatically include online events
    search_query.onlineFilter = "include_online";
  }
  if (btn_classes.includes("search-Event")) {
    search_query.contentType = ContentType.EVENTS;
  }
  if (btn_classes.includes("search-Activity")) {
    search_query.contentType = ContentType.LONGEVENTS;
  }
  if (btn_classes.includes("search-Group")) {
    search_query.contentType = ContentType.GROUPS;
  }
  router.push({
    name: RouteName.SEARCH,
    query: {
      ...route.query,
      ...search_query,
    },
  });
};

const { t } = useI18n({ useScope: "global" });
</script>
<style scoped>
#search-anchor :deep(.o-input__wrapper) {
  flex: 1;
}
.active {
  text-decoration: underline;
  font-weight: bold;
}
.disactive {
  color: #eee;
  font-weight: 300;
}
</style>
