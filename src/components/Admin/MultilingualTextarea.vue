<template>
  <div class="multilingual-textarea">
    <!-- Language tabs -->
    <div class="language-tabs mb-4 flex flex-wrap gap-2 items-center">
      <button
        v-for="lang in activeLanguages"
        :key="lang"
        @click="currentLanguage = lang"
        :class="[
          'px-4 py-2 rounded-t border-b-2 font-medium transition-colors',
          currentLanguage === lang
            ? 'border-blue-600 text-blue-600 bg-blue-50 dark:bg-blue-900/20'
            : 'border-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200',
        ]"
        type="button"
      >
        {{ getLanguageName(lang) }}
        <span
          v-if="lang === defaultLanguage"
          class="ml-1 text-xs text-gray-500"
        >
          ({{ t("default") }})
        </span>
      </button>

      <!-- Add language dropdown -->
      <div class="relative" v-if="availableLanguagesToAdd.length > 0">
        <button
          @click="showAddLanguage = !showAddLanguage"
          class="px-4 py-2 rounded border border-dashed border-gray-400 text-gray-600 dark:text-gray-400 hover:border-gray-600 dark:hover:border-gray-300 transition-colors"
          type="button"
        >
          + {{ t("Add Language") }}
        </button>
        <div
          v-if="showAddLanguage"
          class="absolute z-10 mt-2 w-48 rounded-md shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5"
        >
          <div class="py-1">
            <button
              v-for="lang in availableLanguagesToAdd"
              :key="lang"
              @click="addLanguage(lang)"
              class="block w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
              type="button"
            >
              {{ getLanguageName(lang) }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Textarea for current language -->
    <div class="relative">
      <o-input
        type="textarea"
        :modelValue="translations[currentLanguage] || ''"
        @update:modelValue="updateTranslation(currentLanguage, $event)"
        :id="fieldId"
        :placeholder="placeholder"
        :rows="rows"
      />

      <!-- Remove language button (only for non-default languages) -->
      <button
        v-if="currentLanguage !== defaultLanguage && activeLanguages.length > 1"
        @click="removeLanguage(currentLanguage)"
        class="absolute top-2 right-2 px-3 py-1 text-sm text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300 bg-white dark:bg-gray-800 rounded border border-red-300 dark:border-red-700 hover:bg-red-50 dark:hover:bg-red-900/20"
        type="button"
        :title="t('Remove this translation')"
      >
        {{ t("Remove") }}
      </button>
    </div>

    <!-- Translation status indicator -->
    <div class="mt-2 text-sm text-gray-600 dark:text-gray-400">
      {{
        t("{count} language(s) configured", {
          count: activeLanguages.length,
        })
      }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, watch } from "vue";
import { useI18n } from "vue-i18n";
import type { IMultilingualString } from "@/types/admin.model";

const { t } = useI18n({ useScope: "global" });

interface Props {
  modelValue: string | IMultilingualString | null | undefined;
  instanceLanguages: string[];
  defaultLanguage?: string;
  fieldId?: string;
  placeholder?: string;
  rows?: number;
}

const props = withDefaults(defineProps<Props>(), {
  defaultLanguage: "en",
  fieldId: "multilingual-textarea",
  placeholder: "",
  rows: 10,
});

const emit = defineEmits<{
  (e: "update:modelValue", value: IMultilingualString): void;
}>();

// State
const currentLanguage = ref(props.defaultLanguage);
const showAddLanguage = ref(false);
const translations = ref<IMultilingualString>({});

// Initialize translations from modelValue
watch(
  () => props.modelValue,
  (newValue) => {
    if (typeof newValue === "string") {
      // Convert legacy string to multilingual format
      translations.value = { [props.defaultLanguage]: newValue };
    } else if (newValue && typeof newValue === "object") {
      translations.value = { ...newValue };
    } else {
      translations.value = { [props.defaultLanguage]: "" };
    }
    
    // Ensure default language exists
    if (!translations.value[props.defaultLanguage]) {
      translations.value[props.defaultLanguage] = "";
    }
  },
  { immediate: true }
);

// Computed
const activeLanguages = computed(() => {
  return Object.keys(translations.value).sort((a, b) => {
    // Default language first
    if (a === props.defaultLanguage) return -1;
    if (b === props.defaultLanguage) return 1;
    return a.localeCompare(b);
  });
});

const availableLanguagesToAdd = computed(() => {
  return props.instanceLanguages.filter(
    (lang) => !activeLanguages.value.includes(lang)
  );
});

// Methods
const updateTranslation = (lang: string, value: string) => {
  translations.value[lang] = value;
  emit("update:modelValue", { ...translations.value });
};

const addLanguage = (lang: string) => {
  translations.value[lang] = "";
  currentLanguage.value = lang;
  showAddLanguage.value = false;
  emit("update:modelValue", { ...translations.value });
};

const removeLanguage = (lang: string) => {
  const newTranslations = { ...translations.value };
  delete newTranslations[lang];
  translations.value = newTranslations;
  
  // Switch to default language after removal
  currentLanguage.value = props.defaultLanguage;
  emit("update:modelValue", { ...translations.value });
};

const getLanguageName = (code: string): string => {
  // Map of common language codes to names
  const languageNames: Record<string, string> = {
    en: "English",
    pl: "Polski",
    fr: "Français",
    de: "Deutsch",
    es: "Español",
    it: "Italiano",
    pt: "Português",
    ru: "Русский",
    ja: "日本語",
    zh: "中文",
    ar: "العربية",
    nl: "Nederlands",
    sv: "Svenska",
    da: "Dansk",
    fi: "Suomi",
    no: "Norsk",
    cs: "Čeština",
    hu: "Magyar",
    ro: "Română",
    tr: "Türkçe",
    el: "Ελληνικά",
    uk: "Українська",
  };
  
  return languageNames[code] || code.toUpperCase();
};

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement;
  if (!target.closest(".relative")) {
    showAddLanguage.value = false;
  }
};

// Add click outside listener
if (typeof window !== "undefined") {
  document.addEventListener("click", handleClickOutside);
}
</script>

<style scoped>
.multilingual-textarea {
  width: 100%;
}

.language-tabs {
  border-bottom: 1px solid #e5e7eb;
}

.dark .language-tabs {
  border-bottom-color: #374151;
}
</style>

