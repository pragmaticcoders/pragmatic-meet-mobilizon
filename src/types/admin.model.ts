import type { IEvent } from "@/types/event.model";
import type { IMedia } from "@/types/media.model";
import type { IGroup } from "./actor";
import { InstancePrivacyType, InstanceTermsType } from "./enums";

export interface IDashboard {
  lastPublicEventPublished: IEvent;
  lastGroupCreated: IGroup;
  numberOfUsers: number;
  numberOfEvents: number;
  numberOfComments: number;
  numberOfReports: number;
  numberOfGroups: number;
  numberOfFollowers: number;
  numberOfFollowings: number;
  numberOfConfirmedParticipationsToLocalEvents: number;
}

export interface ILanguage {
  code: string;
  name: string;
}

export interface IMultilingualString {
  [languageCode: string]: string;
}

export interface ITranslationInput {
  language: string;
  content: string;
}

export interface IMultilingualStringInput {
  translations: ITranslationInput[];
}

export interface IAdminSettings {
  instanceName: string;
  instanceDescription: string;
  instanceSlogan: string;
  instanceLongDescription: string;
  contact: string;
  instanceLogo: IMedia | null;
  defaultPicture: IMedia | null;
  primaryColor: string;
  secondaryColor: string;
  instanceTerms: string | IMultilingualString;
  instanceTermsType: InstanceTermsType;
  instanceTermsUrl: string | null;
  instancePrivacyPolicy: string | IMultilingualString;
  instancePrivacyPolicyType: InstancePrivacyType;
  instancePrivacyPolicyUrl: string | null;
  instanceRules: string | IMultilingualString;
  registrationsOpen: boolean;
  instanceLanguages: string[];
}
