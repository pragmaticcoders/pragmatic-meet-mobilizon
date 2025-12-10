<template>
  <div class="max-w-screen-xl mx-auto px-4 md:px-16">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        { text: t('Instance settings') },
      ]"
    />

    <section v-if="settingsToWrite">
      <form @submit.prevent="updateSettings">
        <o-field :label="t('Instance Name')" label-for="instance-name">
          <o-input
            v-model="settingsToWrite.instanceName"
            id="instance-name"
            expanded
          />
        </o-field>
        <div class="field flex flex-col">
          <label class="" for="instance-description">{{
            t("Instance Short Description")
          }}</label>
          <small>
            {{
              t(
                "Displayed on homepage and meta tags. Describe what Pragmatic Meet is and what makes this instance special in a single paragraph."
              )
            }}
          </small>
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceDescription"
            rows="2"
            id="instance-description"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-slogan">{{
            t("Instance Slogan")
          }}</label>
          <small>
            {{
              t(
                'A short tagline for your instance homepage. Defaults to "Gather ⋅ Organize ⋅ Mobilize"'
              )
            }}
          </small>
          <o-input
            v-model="settingsToWrite.instanceSlogan"
            :placeholder="t('Gather ⋅ Organize ⋅ Mobilize')"
            id="instance-slogan"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-contact">{{ t("Contact") }}</label>
          <small>
            {{ t("Can be an email or a link, or just plain text.") }}
          </small>
          <o-input v-model="settingsToWrite.contact" id="instance-contact" />
        </div>
        <label class="field flex flex-col">
          <p>{{ t("Logo") }}</p>
          <small>
            {{
              t(
                "Logo of the instance. Defaults to the upstream Mobilizon logo."
              )
            }}
          </small>
          <picture-upload
            v-model:modelValue="instanceLogoFile"
            :defaultImage="settingsToWrite.instanceLogo"
            :textFallback="t('Logo')"
            :maxSize="maxSize"
          />
        </label>
        <label class="field flex flex-col">
          <p>{{ t("Favicon") }}</p>
          <small>
            {{
              t(
                "Browser tab icon and PWA icon of the instance. Defaults to the upstream Mobilizon icon."
              )
            }}
          </small>
          <picture-upload
            v-model:modelValue="instanceFaviconFile"
            :defaultImage="settingsToWrite.instanceFavicon"
            :textFallback="t('Favicon')"
            :maxSize="maxSize"
          />
        </label>
        <label class="field flex flex-col">
          <p>{{ t("Default Picture") }}</p>
          <small>
            {{ t("Default picture when an event or group doesn't have one.") }}
          </small>
          <picture-upload
            v-model:modelValue="defaultPictureFile"
            :defaultImage="settingsToWrite.defaultPicture"
            :textFallback="t('Default Picture')"
            :maxSize="maxSize"
          />
        </label>
        <!-- piece of code to manage instance colors
        <div class="field flex flex-col">
          <label class="" for="primary-color">{{ t("Primary Color") }}</label>
          <o-input
            type="color"
            v-model="settingsToWrite.primaryColor"
            id="primary-color"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="secondary-color">{{
            t("Secondary Color")
          }}</label>
          <o-input
            type="color"
            v-model="settingsToWrite.secondaryColor"
            id="secondary-color"
          />
        </div>
        -->
        <o-field :label="t('Allow registrations')">
          <o-switch v-model="settingsToWrite.registrationsOpen">
            <p
              class="prose dark:prose-invert"
              v-if="settingsToWrite.registrationsOpen"
            >
              {{ t("Registration is allowed, anyone can register.") }}
            </p>
            <p class="prose dark:prose-invert" v-else>
              {{ t("Registration is closed.") }}
            </p>
          </o-switch>
        </o-field>
        <div class="field flex flex-col">
          <label class="" for="instance-languages">{{
            t("Instance languages")
          }}</label>
          <small>
            {{ t("Main languages you/your moderators speak") }}
          </small>
          <o-taginput
            v-model="selectedLanguages"
            :data="filteredLanguages"
            allow-autocomplete
            :open-on-focus="true"
            :remove-on-keys="[]"
            icon="label"
            :placeholder="t('Select languages')"
            field="name"
            id="instance-languages"
            @typing="languageSearchText = $event"
          />
        </div>
        <div class="field flex flex-col">
          <label class="" for="instance-long-description">{{
            t("Instance Long Description")
          }}</label>
          <small>
            {{
              t(
                "A place to explain who you are and the things that set your instance apart. You can use HTML tags."
              )
            }}
          </small>
          <o-input
            type="textarea"
            v-model="settingsToWrite.instanceLongDescription"
            rows="4"
            id="instance-long-description"
          />
        </div>
        <div class="field flex flex-col w-full">
          <label class="" for="instance-rules">{{ t("Instance Rules") }}</label>
          <small>
            {{
              t(
                "A place for your code of conduct, rules or guidelines. You can use HTML tags."
              )
            }}
          </small>
          <div class="w-full">
            <MultilingualTextarea
              v-model="settingsToWrite.instanceRules"
               :instanceLanguages="instanceLanguageCodes"
              :defaultLanguage="defaultLanguageCode"
              fieldId="instance-rules"
              :placeholder="t('Enter your instance rules...')"
              :rows="10"
            />
          </div>
        </div>
        <o-field :label="t('Instance Terms Source')">
          <div class="">
            <div class="">
              <fieldset>
                <legend>
                  {{ t("Choose the source of the instance's Terms") }}
                </legend>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.DEFAULT"
                    >{{ t("Default Mobilizon terms") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.URL"
                    >{{ t("Custom URL") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instanceTermsType"
                    name="instanceTermsType"
                    :native-value="InstanceTermsType.CUSTOM"
                    >{{ t("Custom text") }}</o-radio
                  >
                </o-field>
              </fieldset>
            </div>
            <div class="">
              <o-notification
                class="bg-slate-700"
                v-if="
                  settingsToWrite.instanceTermsType ===
                  InstanceTermsType.DEFAULT
                "
              >
                <b>{{ t("Default") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="The {default_terms} will be used. They will be translated in the user's language."
                >
                  <template #default_terms>
                    <a
                      href="https://demo.mobilizon.org/terms"
                      target="_blank"
                      rel="noopener"
                      >{{ t("default Mobilizon terms") }}</a
                    >
                  </template>
                </i18n-t>
                <b>{{
                  t(
                    "NOTE! The default terms have not been checked over by a lawyer and thus are unlikely to provide full legal protection for all situations for an instance admin using them. They are also not specific to all countries and jurisdictions. If you are unsure, please check with a lawyer."
                  )
                }}</b>
              </o-notification>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.URL
                "
              >
                <b>{{ t("URL") }}</b>
                <p class="prose dark:prose-invert">
                  {{ t("Set an URL to a page with your own terms.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM
                "
              >
                <b>{{ t("Custom") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="Enter your own terms. HTML tags allowed. The {mobilizon_terms} are provided as template."
                >
                  <template #mobilizon_terms>
                    <a
                      href="https://demo.mobilizon.org/terms"
                      target="_blank"
                      rel="noopener"
                    >
                      {{ t("default Mobilizon terms") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
            </div>
          </div>
        </o-field>
        <o-field
          :label="t('Instance Terms URL')"
          label-for="instanceTermsUrl"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.URL"
        >
          <o-input
            type="URL"
            v-model="settingsToWrite.instanceTermsUrl"
            id="instanceTermsUrl"
          />
        </o-field>
        <o-field
          :label="t('Instance Terms')"
          label-for="instanceTerms"
          v-if="settingsToWrite.instanceTermsType === InstanceTermsType.CUSTOM"
        >
          <div class="w-full">
            <MultilingualTextarea
              v-model="settingsToWrite.instanceTerms"
              :instanceLanguages="instanceLanguageCodes"
              :defaultLanguage="defaultLanguageCode"
              fieldId="instanceTerms"
              :placeholder="t('Enter your instance terms...')"
              :rows="15"
            />
          </div>
        </o-field>
        <o-field :label="t('Instance Privacy Policy Source')">
          <div class="">
            <div class="">
              <fieldset>
                <legend>
                  {{ t("Choose the source of the instance's Privacy Policy") }}
                </legend>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.DEFAULT"
                    >{{ t("Default Mobilizon privacy policy") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.URL"
                    >{{ t("Custom URL") }}</o-radio
                  >
                </o-field>
                <o-field>
                  <o-radio
                    v-model="settingsToWrite.instancePrivacyPolicyType"
                    name="instancePrivacyType"
                    :native-value="InstancePrivacyType.CUSTOM"
                    >{{ t("Custom text") }}</o-radio
                  >
                </o-field>
              </fieldset>
            </div>
            <div class="">
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.DEFAULT
                "
              >
                <b>{{ t("Default") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="The {default_privacy_policy} will be used. They will be translated in the user's language."
                >
                  <template #default_privacy_policy>
                    <a
                      href="https://demo.mobilizon.org/privacy"
                      target="_blank"
                      rel="noopener"
                      >{{ t("default Mobilizon privacy policy") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.URL
                "
              >
                <b>{{ t("URL") }}</b>
                <p class="prose dark:prose-invert">
                  {{ t("Set an URL to a page with your own privacy policy.") }}
                </p>
              </div>
              <div
                class="notification"
                v-if="
                  settingsToWrite.instancePrivacyPolicyType ===
                  InstancePrivacyType.CUSTOM
                "
              >
                <b>{{ t("Custom") }}</b>
                <i18n-t
                  tag="p"
                  class="prose dark:prose-invert"
                  keypath="Enter your own privacy policy. HTML tags allowed. The {mobilizon_privacy_policy} is provided as template."
                >
                  <template #mobilizon_privacy_policy>
                    <a
                      href="https://demo.mobilizon.org/privacy"
                      target="_blank"
                      rel="noopener"
                    >
                      {{ t("default Mobilizon privacy policy") }}</a
                    >
                  </template>
                </i18n-t>
              </div>
            </div>
          </div>
        </o-field>
        <o-field
          :label="t('Instance Privacy Policy URL')"
          label-for="instancePrivacyPolicyUrl"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.URL
          "
        >
          <o-input
            type="URL"
            v-model="settingsToWrite.instancePrivacyPolicyUrl"
            id="instancePrivacyPolicyUrl"
          />
        </o-field>
        <o-field
          :label="t('Instance Privacy Policy')"
          label-for="instancePrivacyPolicy"
          v-if="
            settingsToWrite.instancePrivacyPolicyType ===
            InstancePrivacyType.CUSTOM
          "
        >
          <div class="w-full">
            <MultilingualTextarea
              v-model="settingsToWrite.instancePrivacyPolicy"
              :instanceLanguages="instanceLanguageCodes"
              :defaultLanguage="defaultLanguageCode"
              fieldId="instancePrivacyPolicy"
              :placeholder="t('Enter your instance privacy policy...')"
              :rows="15"
            />
          </div>
        </o-field>
        <o-button native-type="submit" variant="primary">{{
          t("Save")
        }}</o-button>
      </form>
    </section>
  </div>
</template>
<script lang="ts" setup>
import {
  ADMIN_SETTINGS,
  SAVE_ADMIN_SETTINGS,
  LANGUAGES,
} from "@/graphql/admin";
import { InstancePrivacyType, InstanceTermsType } from "@/types/enums";
import { IAdminSettings, ILanguage } from "@/types/admin.model";
import RouteName from "@/router/name";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { ref, computed, watch, inject } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";
import type { Notifier } from "@/plugins/notifier";

// Media upload related
import PictureUpload from "@/components/PictureUpload.vue";
import MultilingualTextarea from "@/components/Admin/MultilingualTextarea.vue";
import {
  initWrappedMedia,
  loadWrappedMedia,
  asMediaInput,
} from "@/utils/image";
import { useDefaultMaxSize } from "@/composition/config";
import type { IMultilingualString, IMultilingualStringInput } from "@/types/admin.model";

const defaultAdminSettings: IAdminSettings = {
  instanceName: "",
  instanceDescription: "",
  instanceSlogan: "",
  instanceLongDescription: "",
  contact: "",
  instanceLogo: null,
  instanceFavicon: null,
  defaultPicture: null,
  primaryColor: "",
  secondaryColor: "",
  instanceTerms: "",
  instanceTermsType: InstanceTermsType.DEFAULT,
  instanceTermsUrl: null,
  instancePrivacyPolicy: "",
  instancePrivacyPolicyType: InstancePrivacyType.DEFAULT,
  instancePrivacyPolicyUrl: null,
  instanceRules: "",
  registrationsOpen: false,
  instanceLanguages: [],
};

const { onResult: onAdminSettingsResult } = useQuery<{
  adminSettings: IAdminSettings;
}>(ADMIN_SETTINGS);

const adminSettings = ref<IAdminSettings>();

onAdminSettingsResult(async ({ data }) => {
  if (!data) return;
  
  console.log("Raw data from server:", data.adminSettings);
  
  // Parse JSON strings back to objects for multilingual fields
  const parseMultilingualField = (value: string | IMultilingualString | null): string | IMultilingualString | null => {
    if (!value) return value;
    console.log("Parsing field, value type:", typeof value, "value:", value);
    if (typeof value === "string") {
      try {
        const parsed = JSON.parse(value);
        console.log("Parsed to:", parsed);
        // If it parses to an object with multiple keys, it's multilingual
        if (typeof parsed === "object" && parsed !== null && Object.keys(parsed).length > 0) {
          return parsed;
        }
      } catch (e) {
        console.log("Parse error:", e);
        // Not JSON, return as-is
      }
    }
    return value;
  };
  
  adminSettings.value = {
    ...data.adminSettings,
    instanceTerms: parseMultilingualField(data.adminSettings.instanceTerms),
    instancePrivacyPolicy: parseMultilingualField(data.adminSettings.instancePrivacyPolicy),
    instanceRules: parseMultilingualField(data.adminSettings.instanceRules),
  } ?? defaultAdminSettings;

  console.log("Parsed adminSettings:", adminSettings.value);

  loadWrappedMedia(instanceLogo, adminSettings.value.instanceLogo);
  loadWrappedMedia(instanceFavicon, adminSettings.value.instanceFavicon);
  loadWrappedMedia(defaultPicture, adminSettings.value.defaultPicture);
});

const instanceLogo = initWrappedMedia();
const { file: instanceLogoFile } = instanceLogo;
const instanceFavicon = initWrappedMedia();
const { file: instanceFaviconFile } = instanceFavicon;
const defaultPicture = initWrappedMedia();
const { file: defaultPictureFile } = defaultPicture;

const { result: languageResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES
);
const languages = computed(() => {
  const langs = languageResult.value?.languages || [];
  // Sort languages alphabetically by name
  return [...langs].sort((a, b) => a.name.localeCompare(b.name));
});

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Settings")),
});

const settingsToWrite = ref<IAdminSettings>(defaultAdminSettings);

watch(adminSettings, () => {
  settingsToWrite.value = {
    ...defaultAdminSettings,
    ...adminSettings.value,
  };
  // if languages are already loaded, map codes to objects; otherwise keep codes until languages arrive
  if (languages.value?.length) {
    selectedLanguages.value =
      adminSettings.value?.instanceLanguages
        ?.map((code) => languages.value?.find((l) => l.code === code))
        .filter((l): l is ILanguage => !!l) ?? [];
  } else {
    selectedLanguages.value =
      adminSettings.value?.instanceLanguages?.map((code) => ({ code, name: code })) ??
      [];
  }
});

const selectedLanguages = ref<ILanguage[]>([]);
const languageSearchText = ref<string>("");

// Filtered languages for autocomplete
const filteredLanguages = computed(() => {
  if (!languageSearchText.value) {
    return languages.value || [];
  }
  const search = languageSearchText.value.toLowerCase();
  return (languages.value || []).filter(({ name }) =>
    name.toLowerCase().includes(search)
  );
});

// Initialize language list when loaded
watch(
  languages,
  (langs) => {
    if (langs && settingsToWrite.value.instanceLanguages?.length) {
      selectedLanguages.value =
        settingsToWrite.value.instanceLanguages
          .map((code) => langs.find((l) => l.code === code))
          .filter((l): l is ILanguage => !!l) ?? [];
    }
  },
  { immediate: true }
);

const notifier = inject<Notifier>("notifier");

const {
  mutate: saveAdminSettings,
  onDone: saveAdminSettingsDone,
  onError: saveAdminSettingsError,
} = useMutation(SAVE_ADMIN_SETTINGS);

saveAdminSettingsDone(() => {
  instanceLogo.firstHash = instanceLogo.hash;
  instanceFavicon.firstHash = instanceFavicon.hash;
  defaultPicture.firstHash = defaultPicture.hash;
  notifier?.success(t("Admin settings successfully saved.") as string);
});

saveAdminSettingsError((e) => {
  console.error(e);
  notifier?.error(t("Failed to save admin settings") as string);
});

const updateSettings = async (): Promise<void> => {
  // Convert multilingual strings to the format expected by GraphQL
  const convertToMultilingualInput = (
    value: string | IMultilingualString
  ): IMultilingualStringInput | undefined => {
    if (typeof value === "object" && value !== null) {
      return {
        translations: Object.entries(value).map(([language, content]) => ({
          language,
          content,
        })),
      };
    }
    return undefined;
  };

  // Remove multilingual fields from settingsToWrite before spreading
  const { instanceTerms, instancePrivacyPolicy, instanceRules, ...restSettings } = settingsToWrite.value;

  console.log("Before save - instanceRules:", instanceRules, "type:", typeof instanceRules);
  console.log("Before save - instanceTerms:", instanceTerms, "type:", typeof instanceTerms);
  console.log("Before save - instancePrivacyPolicy:", instancePrivacyPolicy, "type:", typeof instancePrivacyPolicy);

  const variables = {
    ...restSettings,
    instanceLanguages: selectedLanguages.value.map((lang) => lang.code),
    // Send either the string field OR the i18n field, never both
    instanceTerms: typeof instanceTerms === "string" 
      ? instanceTerms 
      : undefined,
    instanceTermsI18n: convertToMultilingualInput(instanceTerms),
    instancePrivacyPolicy: typeof instancePrivacyPolicy === "string"
      ? instancePrivacyPolicy
      : undefined,
    instancePrivacyPolicyI18n: convertToMultilingualInput(instancePrivacyPolicy),
    instanceRules: typeof instanceRules === "string"
      ? instanceRules
      : undefined,
    instanceRulesI18n: convertToMultilingualInput(instanceRules),
    ...asMediaInput(
      instanceLogo,
      "instanceLogo",
      adminSettings.value?.instanceLogo?.id
    ),
    ...asMediaInput(
      instanceFavicon,
      "instanceFavicon",
      adminSettings.value?.instanceFavicon?.id
    ),
    ...asMediaInput(
      defaultPicture,
      "defaultPicture",
      adminSettings.value?.defaultPicture?.id
    ),
  };
  console.log("Sending variables to GraphQL:", variables);
  console.log("instanceRulesI18n:", variables.instanceRulesI18n);
  console.log("instanceTermsI18n:", variables.instanceTermsI18n);
  saveAdminSettings(variables);
};

const maxSize = useDefaultMaxSize();

const instanceLanguageCodes = computed(() =>
  selectedLanguages.value.map((lang) => lang.code)
);

const defaultLanguageCode = computed(() => {
  return instanceLanguageCodes.value?.[0] || "en";
});
</script>
<style lang="scss" scoped>
label.label.has-help {
  margin-bottom: 0;
}
</style>
