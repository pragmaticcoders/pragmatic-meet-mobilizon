export type EventRegistrationQuestionType =
  | "SHORT_TEXT"
  | "LONG_TEXT"
  | "SINGLE_CHOICE"
  | "MULTIPLE_CHOICE";

export interface IEventRegistrationQuestionOption {
  id?: string;
  position: number;
  label: string;
}

export interface IEventRegistrationQuestion {
  id?: string;
  position: number;
  questionType: EventRegistrationQuestionType;
  title: string;
  required: boolean;
  options?: IEventRegistrationQuestionOption[];
}

export interface IParticipantRegistrationAnswer {
  id?: string;
  questionId: string;
  value: string;
}
