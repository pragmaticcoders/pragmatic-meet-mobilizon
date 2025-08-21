<template>
  <footer class="bg-white border-t border-gray-200" ref="footer">
    <div
      class="container mx-auto px-4 md:px-16 py-12 flex flex-col items-center text-center gap-6"
    >
      <!-- Brand -->
      <img
        src="/img/pragmatic_logo.svg"
        alt="Pragmatic Meet"
        width="176"
        height="32"
        class="w-[176px] h-8"
      />

      <!-- Language selector -->
      <div>
        <label class="sr-only" for="footer-language">{{ t("Language") }}</label>
        <o-select
          id="footer-language"
          class="min-w-[220px] text-gray-900 border border-gray-300 px-4 py-3 bg-white"
          :aria-label="t('Language')"
          v-model="locale"
          :placeholder="t('Select a language')"
        >
          <option
            v-for="(language, lang) in langs"
            :value="lang"
            :key="lang"
            :selected="isLangSelected(lang)"
          >
            {{ flagForLocale(lang) }} {{ language }}
          </option>
        </o-select>
      </div>

      <!-- Primary links -->
      <nav>
        <ul class="flex items-center gap-6 text-base text-blue-700">
          <li>
            <router-link
              class="hover:underline"
              :to="{ name: RouteName.TERMS }"
            >
              O Pragmatic Meet
            </router-link>
          </li>
          <li class="text-gray-300">|</li>
          <li>
            <a class="hover:underline" href="#navbar">Powrót do góry</a>
          </li>
        </ul>
      </nav>

      <!-- Secondary links -->
      <div class="flex items-center gap-3 text-sm text-gray-700">
        <span class="text-green-600">💚</span>
        <span>Powstało dzięki</span>
        <a
          class="underline"
          href="https://www.pragmaticcoders.com"
          rel="external"
          >Pragmatic Coders</a
        >
        <span class="text-gray-300">|</span>
        <router-link class="underline" :to="{ name: RouteName.TERMS }"
          >Polityka prywatności</router-link
        >
      </div>
    </div>
    <div class="border-t border-gray-200">
      <div
        class="container mx-auto px-4 md:px-16 py-6 text-gray-500 text-xs text-center"
      >
        © {{ new Date().getFullYear() }} Pragmatic Meet. Wszelkie prawa
        zastrzeżone.
      </div>
    </div>
  </footer>
</template>
<script setup lang="ts">
import { saveLocaleData } from "@/utils/auth";
import { loadLanguageAsync } from "@/utils/i18n";
import RouteName from "../router/name";
import langs from "../i18n/langs.json";
import { watch } from "vue";
import { flagForLocale } from "@/utils/locale";
import { useI18n } from "vue-i18n";

const { locale, t } = useI18n({ useScope: "global" });

watch(locale, async () => {
  if (locale) {
    console.debug("Setting locale from footer");
    await loadLanguageAsync(locale.value as string);
    saveLocaleData(locale.value as string);
  }
});

const isLangSelected = (lang: string): boolean => {
  return lang === locale.value;
};

// flagForLocale now imported from utils
</script>

<style lang="scss">
footer > ul > li {
  margin: auto 0;
}
</style>
