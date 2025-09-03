<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <h1 class="mb-4">{{ t("Settings") }}</h1>
    <div class="flex flex-col lg:flex-row gap-4">
      <aside class="lg:max-w-xs lg:flex-1 w-full">
        <ul>
          <SettingMenuSection
            :title="t('Settings')"
            :to="{ name: RouteName.GROUP_SETTINGS }"
          >
            <SettingMenuItem
              :title="t('Public')"
              :to="{ name: RouteName.GROUP_PUBLIC_SETTINGS }"
            />
            <SettingMenuItem
              :title="t('Members')"
              :to="{ name: RouteName.GROUP_MEMBERS_SETTINGS }"
            />
            <SettingMenuItem
              :title="t('Followers')"
              :to="{ name: RouteName.GROUP_FOLLOWERS_SETTINGS }"
            />
          </SettingMenuSection>
        </ul>
      </aside>
      <div class="flex-1 min-w-0">
        <router-view />
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import RouteName from "@/router/name";
import SettingMenuSection from "@/components/Settings/SettingMenuSection.vue";
import SettingMenuItem from "@/components/Settings/SettingMenuItem.vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group settings")),
});
</script>
