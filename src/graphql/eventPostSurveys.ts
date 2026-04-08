import gql from "graphql-tag";

const EVENT_POST_SURVEY_FRAGMENT = gql`
  fragment EventPostSurvey on EventPostSurvey {
    id
    uuid
    title
    description
    schema
    status
    contextId
    eventId
  }
`;

export const EVENT_POST_SURVEYS = gql`
  query EventPostSurveys($eventId: ID!) {
    eventPostSurveys(eventId: $eventId) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const CREATE_EVENT_POST_SURVEY = gql`
  mutation CreateEventPostSurvey($eventId: ID!, $title: String!, $description: String, $schema: JSON!) {
    createEventPostSurvey(eventId: $eventId, title: $title, description: $description, schema: $schema) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const UPDATE_EVENT_POST_SURVEY = gql`
  mutation UpdateEventPostSurvey($surveyId: ID!, $title: String!, $description: String, $schema: JSON!) {
    updateEventPostSurvey(surveyId: $surveyId, title: $title, description: $description, schema: $schema) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const PUBLISH_EVENT_POST_SURVEY = gql`
  mutation PublishEventPostSurvey($surveyId: ID!) {
    publishEventPostSurvey(surveyId: $surveyId) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const CLOSE_EVENT_POST_SURVEY = gql`
  mutation CloseEventPostSurvey($surveyId: ID!) {
    closeEventPostSurvey(surveyId: $surveyId) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const EVENT_POST_SURVEY_RESPONSES = gql`
  query EventPostSurveyResponses($surveyId: ID!) {
    eventPostSurveyResponses(surveyId: $surveyId) {
      respondentId
      respondentName
      respondentUsername
      respondentEmail
      submittedAt
      schema
      data
    }
  }
`;
