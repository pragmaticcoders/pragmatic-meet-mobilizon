<template>
  <div class="bg-white dark:bg-gray-900">
    <h1
      class="text-[30px] font-bold text-gray-900 dark:text-gray-100 mb-8 leading-[40px]"
    >
      {{ t("Terms of Service") }}
    </h1>

    <div class="space-y-8 text-gray-900 dark:text-gray-300 max-w-[592px]">
      <section class="space-y-4">
        <div class="space-y-2">
          <h2
            class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
          >
            {{ t("Short version") }}
          </h2>
          <ul class="list-disc ml-6 space-y-1 text-[17px] leading-[26px]">
            <li>{{ t("Your content belongs to you") }}</li>
            <li>
              <span class="font-bold">Pragmatic Meet</span>
              {{ t("will not use, forward or sell your personal data") }}
            </li>
            <li>
              {{ t("You must follow the law when using") }}
              <span class="font-bold">Pragmatic Meet</span>
            </li>
            <li>
              {{
                t(
                  "When using the service, you must respect other users and the rules of"
                )
              }}
              <span class="font-bold">Pragmatic Meet</span>
            </li>
            <li>
              {{
                t(
                  "The service is provided without warranty and these terms may change in the future"
                )
              }}
            </li>
          </ul>
          <p class="text-[17px] leading-[26px]">
            {{
              t(
                "Some terms, technical or otherwise, used in the text below may cover concepts that are difficult to understand."
              )
            }}
            {{ t("We have provided a") }}
            <router-link
              :to="{ name: RouteName.GLOSSARY }"
              class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >
              {{ t("glossary") }}
            </router-link>
            {{ t("to help you understand them better.") }}
          </p>
          <p class="text-[17px] leading-[26px]">
            {{
              t(
                "Here is important information about accessing and using the Pragmatic Meet website and service"
              )
            }}
            <span class="font-bold"> Pragmatic Meet </span>
            (<a
              :href="siteUrl"
              class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
              >{{ siteDomain }}</a
            >)
            {{
              t(
                "(collectively referred to as the 'Service'). These are our terms of service ('Terms'). Please read them carefully."
              )
            }}
          </p>
          <p class="text-[17px] leading-[26px]">
            {{
              t(
                "When we say 'we', 'our' or 'us' in this document, we mean the owners, operators and administrators of this Pragmatic Meet instance. The Pragmatic Meet software is provided by the Pragmatic Meet team of contributors, supported by"
              )
            }}
            <a
              href="https://framasoft.org/"
              class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
              >Framasoft</a
            >,
            {{
              t(
                "a French non-profit organization working for free/libre software. Unless explicitly stated, this Pragmatic Meet instance is an independent service using Pragmatic Meet source code."
              )
            }}
          </p>
        </div>
      </section>

      <section class="space-y-4">
        <div class="space-y-2">
          <h2
            class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
          >
            {{ t("Acceptance of these terms") }}
          </h2>
          <p class="text-[17px] leading-[26px]">
            {{
              t(
                "Accessing or using the Service means agreeing to abide by all the terms below. If these terms are unclear in any way, please let us know by contacting"
              )
            }}
            <a
              href="mailto:contact@pragmaticcoders.com"
              class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
              >contact@pragmaticcoders.com</a
            >.
          </p>
        </div>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Changes to these terms") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "We reserve the right to change these Terms at any time. For example, we may be required to change these Terms if we introduce a new feature."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "If we make significant changes, we will notify our users in a clear and visible manner. Minor changes may only be highlighted in the footer of our website. It is the user's responsibility to regularly check the website for changes to these Terms."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Continued use of the Service after the amended Terms come into effect means acceptance of the amended Terms."
            )
          }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Privacy Policy") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "For information on how we collect and use information about users of the Service, please refer to our"
            )
          }}
          <router-link
            :to="{ name: RouteName.PRIVACY }"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
          >
            {{ t("privacy policy") }} </router-link
          >.
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Your content and behavior") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Our Service allows you and other users to publish, link and share content in other ways. You are responsible for the content you share on the Service, including its legality, reliability and appropriateness."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "By publishing, linking or otherwise sharing content on the Service, you grant us the right and license to display and distribute your content on or through the Service (including through applications). We may format your content for display within the Service, but we will not edit or change the substance of the content itself. The display and distribution of your content is done solely in accordance with the visibility rules you have set for that content. We will not modify the visibility of content you have set."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "We are not responsible if a programming or administrative error causes your content to be visible to a larger audience than intended. Beyond our limited right to your content, you retain all your rights to content you publish, link and otherwise share on or through the Service."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "You may delete content you have published by deleting it. Once content is deleted, it will not appear on the Service, but copies of deleted content may remain in our system or backups for some time. Web server access logs may also be stored in the system for some time."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Since Pragmatic Meet is a distributed network, it is possible, depending on the visibility rules set for the content, that the content has been distributed to other Pragmatic Meet instances. When you delete your content, we will ask these other instances to delete it as well. Our responsibility for deleting content from these other instances ends there. If for some reason another instance does not delete the content, we are not responsible for it."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "To make Pragmatic Meet a friendly place for all of us, please do not publish, link, or share any of the following on the platform:"
            )
          }}
        </p>
        <ul class="list-disc ml-6 space-y-1 text-[17px] leading-[26px]">
          <li>
            {{
              t(
                "Content that is illegal or unlawful that would result in liability"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Content that may infringe any patents, trademarks, trade secrets, copyrights, privacy rights, publicity rights or other intellectual or other rights of any party"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Private information of any third party (e.g. addresses, phone numbers, email addresses, credit card numbers)"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Viruses, corrupted data or other harmful, disruptive or destructive files or code"
              )
            }}
          </li>
        </ul>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "You also agree that you will not take any of the following actions in connection with the Service or other users:"
            )
          }}
        </p>
        <ul class="list-disc ml-6 space-y-1 text-[17px] leading-[26px]">
          <li>
            {{
              t(
                "Use the Service in a way that could interfere with, disrupt, negatively affect or prevent other users from fully enjoying the Service or that could damage, disable, overburden or impair the functioning of the Service"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Impersonate or publish on behalf of any person or entity or otherwise misrepresent your affiliation with such person or entity"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Collect any personal data of other users or intimidate, threaten, harass or otherwise harass other users of the Service"
              )
            }}
          </li>
          <li>
            {{
              t(
                "Circumvent or attempt to circumvent any filtering, security measures, rate limits or other features designed to protect the Service, users of the Service or third parties"
              )
            }}
          </li>
        </ul>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Finally, use of the Service is also subject to acceptance of the instance's own"
            )
          }}
          <router-link
            :to="{ name: RouteName.RULES }"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
          >
            {{ t("rules") }}
          </router-link>
          {{
            t(
              "regarding code of conduct and moderation rules. Violation of these rules may also result in blocking or suspension of the user account."
            )
          }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Our responsibility") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Instance administration (and community moderators with appropriate access) are responsible for monitoring and responding to flagged content and other user reports and have the right and are responsible for removing or editing content that does not comply with this set of instance rules, or for suspending, blocking or banning (temporarily or permanently) any account, community or instance for violating these terms or for other behavior they deem inappropriate, threatening, offensive or harmful."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Instance administration should ensure that each community served by the instance is properly moderated according to defined rules."
            )
          }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Source code") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "This service runs on a Pragmatic Meet instance. Its source code is licensed under"
            )
          }}
          <a
            href="https://tldrlegal.com/license/gnu-affero-general-public-license-v3-(agpl-3.0)"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >AGPLv3</a
          >,
          {{
            t(
              "which means you can and are even encouraged to download the source code, modify it and use it."
            )
          }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{ t("To see more information about Pragmatic Meet software,") }}
          <a
            href="https://joinmobilizon.org/"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >{{ t("look here") }}</a
          >.
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Hyperlinks and third party content") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          <span class="font-bold">Pragmatic Meet</span>
          {{
            t(
              "makes no representations or warranties regarding third party websites accessible through hyperlinks from the Service or websites containing links to the Service and is not responsible for them. When leaving the Service, please be aware that these Terms and our policies no longer apply. The inclusion of any link does not imply endorsement by"
            )
          }}
          <span class="font-bold"> Pragmatic Meet</span>
          {{ t("of the site. You use such site at your own risk.") }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Much of the content on the Service comes from you and others, and we do not review, verify or authenticate it, and it may contain inaccuracies or false information. We make no representations, warranties or guarantees regarding the quality, suitability, truth, accuracy or completeness of any content contained in the Service. You are solely responsible for any risk arising from using or relying on any content."
            )
          }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Termination") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "If you violate any of these Terms, we have the right to suspend or prevent your access to or use of the Service."
            )
          }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Entire Agreement") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{ t("These Terms constitute the entire agreement between you and") }}
          <span class="font-bold"> Pragmatic Meet </span>
          {{
            t(
              "regarding the use of the Service, superseding any prior agreements between you and"
            )
          }}
          <span class="font-bold"> Pragmatic Meet </span>
          {{ t("regarding the use of the Service.") }}
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Feedback") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "We love feedback. Let us know what you think about the service, these Terms and in general,"
            )
          }}
          <span class="font-bold"> Pragmatic Meet</span>.
        </p>
      </section>

      <section class="space-y-2">
        <h2
          class="text-xl font-bold text-gray-900 dark:text-gray-100 leading-[30px]"
        >
          {{ t("Questions and contact information") }}
        </h2>
        <p class="text-[17px] leading-[26px]">
          {{
            t(
              "Questions and feedback about our platform can be directed to us at"
            )
          }}
          <a
            href="mailto:contact@pragmaticcoders.com"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >contact@pragmaticcoders.com</a
          >.
        </p>
        <p class="text-[17px] leading-[26px]">
          {{ t("This document was published under the") }}
          <a
            href="https://creativecommons.org/licenses/by-sa/4.0/"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >CC-BY-SA</a
          >
          {{ t("license. It was last updated on June 22, 2020.") }}
        </p>
        <p class="text-[17px] leading-[26px]">
          {{ t("Originally based on the privacy policy texts of") }}
          <a
            href="https://joindiaspora.com/terms"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >Diaspora*</a
          >
          {{ t("and") }}
          <a
            href="https://github.com/appdotnet/terms-of-service"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >App.net</a
          >,
          {{ t("also published under the") }}
          <a
            href="https://creativecommons.org/licenses/by-sa/4.0/"
            class="font-bold underline text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
            >CC BY-SA</a
          >
          {{ t("license.") }}
        </p>
      </section>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useHead } from "@/utils/head";
import { useI18n } from "vue-i18n";
import { computed } from "vue";
import RouteName from "@/router/name";

const { t } = useI18n({ useScope: "global" });

const siteUrl = computed(() => window.location.origin);
const siteDomain = computed(() => window.location.host);

useHead({
  title: t("Terms of Service"),
});
</script>
