<template>
  <div class="bg-white">
    <!-- Language Section -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Language") }}
      </h2>

      <div class="max-w-md">
        <o-select
          :loading="loadingTimezones || loadingUserSettings"
          v-model="$i18n.locale"
          @update:modelValue="updateLanguage"
          :placeholder="t('Select a language')"
          id="setting-language"
          class="w-full"
        >
          <option value="en" key="en">
            🇬🇧 English
          </option>
          <option value="pl" key="pl">
            🇵🇱 Polski
          </option>
        </o-select>
      </div>
    </section>

    <!-- Timezone Section -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("Timezone") }}
      </h2>

      <div class="max-w-md">
        <o-select
          v-if="selectedTimezone"
          :placeholder="t('Select a timezone')"
          :loading="loadingTimezones || loadingUserSettings"
          v-model="selectedTimezone"
          id="setting-timezone"
          class="w-full mb-3"
        >
          <optgroup
            :label="group"
            v-for="(groupTimezones, group) in timezones"
            :key="group"
          >
            <option
              v-for="timezone in groupTimezones"
              :value="`${group}/${timezone}`"
              :key="timezone"
            >
              {{ sanitize(timezone) }}
            </option>
          </optgroup>
        </o-select>

        <div class="flex items-center gap-2 text-gray-600">
          <o-icon icon="information-outline" size="small" />
          <em
            v-if="Intl.DateTimeFormat().resolvedOptions().timeZone"
            class="text-[14px]"
          >
            {{
              t("Timezone detected as {timezone}.", {
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
              })
            }}
          </em>
          <span v-else class="text-[14px] text-red-600">
            {{ t("Unable to detect timezone.") }}
          </span>
        </div>
      </div>
    </section>

    <!-- Location Section -->
    <section class="mb-8">
      <h2 class="text-[20px] leading-[30px] text-[#1c1b1f] mb-4">
        {{ t("City or region") }}
      </h2>

      <div class="space-y-4">
        <div class="flex gap-4 flex flex-col md:flex-row">
          <div class="flex-1 max-w-md min-w-[200px]">
            <label class="block font-medium text-[15px] text-[#1c1b1f] pb-2">
              {{ t("City") }}
            </label>
            <full-address-auto-complete
              :resultType="AddressSearchType.ADMINISTRATIVE"
              v-model="address"
              :default-text="address?.description"
              id="setting-city"
              class="w-full"
              :hideMap="true"
              :hideSelected="true"
              labelClass="sr-only"
              :placeholder="t('e.g. Nantes, Berlin, Cork, …')"
            />
          </div>

          <div class="w-42">
            <label class="block font-medium text-[15px] text-[#1c1b1f] mb-2">
              {{ t("Radius") }}
            </label>
            <o-select
              :placeholder="t('Select a radius')"
              v-model="locationRange"
              id="setting-radius"
              class="w-full"
            >
              <option
                v-for="index in [1, 5, 10, 25, 50, 100]"
                :key="index"
                :value="index"
              >
                {{ t("{count} km", { count: index }, index) }}
              </option>
            </o-select>
          </div>

          <button
            v-if="address"
            @click="resetArea"
            class="self-end mb-2 p-2 text-gray-500 hover:text-gray-700 transition-colors"
            :aria-label="t('Reset')"
          >
            <o-icon icon="close" />
          </button>
        </div>

        <div class="bg-blue-50 p-4 rounded-lg max-w-2xl">
          <div class="flex gap-2">
            <o-icon
              icon="information-outline"
              class="text-blue-600 mt-0.5"
              size="small"
            />
            <p class="text-[14px] text-gray-700">
              {{
                t(
                  "Your city or region and the radius will only be used to suggest you events nearby. The event radius will consider the administrative center of the area."
                )
              }}
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
import ngeohash from "ngeohash";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import RouteName from "../../router/name";
import { AddressSearchType } from "@/types/enums";
import { Address, IAddress } from "@/types/address.model";
import { useTimezones } from "@/composition/apollo/config";
import { useLoggedUser, updateLocale } from "@/composition/apollo/user";
import { useHead } from "@/utils/head";
import { computed, defineAsyncComponent, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useMutation } from "@vue/apollo-composable";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const { timezones: serverTimezones, loading: loadingTimezones } =
  useTimezones();
const { loggedUser, loading: loadingUserSettings } = useLoggedUser();

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Preferences")),
});

const theme = ref(localStorage.getItem("theme"));
const systemTheme = ref(!("theme" in localStorage));

const { mutate: doUpdateLocale } = updateLocale();

const updateLanguage = (newLocale: string) => {
  doUpdateLocale({ locale: newLocale });
};

watch(systemTheme, (newSystemTheme) => {
  console.debug("changing system theme", newSystemTheme);
  if (newSystemTheme) {
    theme.value = null;
    localStorage.removeItem("theme");
  } else {
    theme.value = "light";
    localStorage.setItem("theme", theme.value);
  }
  changeTheme();
});

watch(theme, (newTheme) => {
  console.debug("changing theme value", newTheme);
  if (newTheme) {
    localStorage.setItem("theme", newTheme);
  }
  changeTheme();
});

const changeTheme = () => {
  console.debug("changing theme to apply");
  if (
    localStorage.getItem("theme") === "dark" ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    console.debug("applying dark theme");
    document.documentElement.classList.add("dark");
  } else {
    console.debug("removing dark theme");
    document.documentElement.classList.remove("dark");
  }
};

const selectedTimezone = computed({
  get() {
    if (loggedUser.value?.settings?.timezone) {
      return loggedUser.value.settings.timezone;
    }
    const detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (loggedUser.value?.settings?.timezone === null) {
      updateUserSettings({ timezone: detectedTimezone });
    }
    return detectedTimezone;
  },
  set(newSelectedTimezone: string) {
    if (newSelectedTimezone !== loggedUser.value?.settings?.timezone) {
      updateUserSettings({ timezone: newSelectedTimezone });
    }
  },
});

const sanitize = (timezone: string): string => {
  return timezone
    .split("_")
    .join(" ")
    .replace("St ", "St. ")
    .split("/")
    .join(" - ");
};

const timezones = computed((): Record<string, string[]> => {
  if (!serverTimezones.value) return {};
  return serverTimezones.value.reduce(
    (acc: { [key: string]: Array<string> }, val: string) => {
      const components = val.split("/");
      const [prefix, suffix] = [
        components.shift() as string,
        components.join("/"),
      ];
      const pushOrCreate = (
        acc2: { [key: string]: Array<string> },
        prefix2: string,
        suffix2: string
      ) => {
        // eslint-disable-next-line no-param-reassign
        (acc2[prefix2] = acc2[prefix2] || []).push(suffix2);
        return acc2;
      };
      if (suffix) {
        return pushOrCreate(acc, prefix, suffix);
      }
      return pushOrCreate(acc, t("Other") as string, prefix);
    },
    {}
  );
});

const address = computed({
  get(): IAddress | null {
    if (
      loggedUser.value?.settings?.location?.name &&
      loggedUser.value?.settings?.location?.geohash
    ) {
      const { latitude, longitude } = ngeohash.decode(
        loggedUser.value?.settings?.location?.geohash
      );
      const name = loggedUser.value?.settings?.location?.name;
      return {
        description: name,
        locality: "",
        type: "administrative",
        geom: `${longitude};${latitude}`,
        street: "",
        postalCode: "",
        region: "",
        country: "",
      };
    }
    return null;
  },
  set(newAddress: IAddress | null) {
    if (newAddress?.geom) {
      const { geom } = newAddress;
      const addressObject = new Address(newAddress);
      const queryText = addressObject.poiInfos.name;
      const [lon, lat] = geom.split(";");
      const geohash = ngeohash.encode(lat, lon, 6);
      if (queryText && geom) {
        updateUserSettings({
          location: {
            geohash,
            name: queryText,
          },
        });
      }
    }
  },
});

const locationRange = computed({
  get(): number | undefined | null {
    return loggedUser.value?.settings?.location?.range;
  },
  set(newLocationRange: number | undefined | null) {
    if (newLocationRange) {
      updateUserSettings({
        location: {
          range: newLocationRange,
        },
      });
    }
  },
});

const resetArea = (): void => {
  updateUserSettings({
    location: {
      geohash: null,
      name: null,
      range: null,
    },
  });
};

const { mutate: updateUserSettings } = useMutation<{ setUserSetting: string }>(
  SET_USER_SETTINGS,
  () => ({
    refetchQueries: [{ query: USER_SETTINGS }],
  })
);
</script>
