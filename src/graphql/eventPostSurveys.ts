import gql from "graphql-tag";

const EVENT_POST_SURVEY_FRAGMENT = gql`
  fragment EventPostSurvey on EventPostSurvey {
    id
    title
    description
    schema
    status
    contextId
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
  mutation UpdateEventPostSurvey($eventId: ID!, $surveyId: String!, $title: String!, $description: String, $schema: JSON!) {
    updateEventPostSurvey(eventId: $eventId, surveyId: $surveyId, title: $title, description: $description, schema: $schema) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const PUBLISH_EVENT_POST_SURVEY = gql`
  mutation PublishEventPostSurvey($eventId: ID!, $surveyId: String!) {
    publishEventPostSurvey(eventId: $eventId, surveyId: $surveyId) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const CLOSE_EVENT_POST_SURVEY = gql`
  mutation CloseEventPostSurvey($eventId: ID!, $surveyId: String!) {
    closeEventPostSurvey(eventId: $eventId, surveyId: $surveyId) {
      ...EventPostSurvey
    }
  }
  ${EVENT_POST_SURVEY_FRAGMENT}
`;

export const EVENT_POST_SURVEY_RESPONSES = gql`
  query EventPostSurveyResponses($eventId: ID!, $surveyId: String!) {
    eventPostSurveyResponses(eventId: $eventId, surveyId: $surveyId) {
      respondentId
      respondentName
      respondentUsername
      respondentEmail
      submittedAt
      data
    }
  }
`;
