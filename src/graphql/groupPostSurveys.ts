import gql from "graphql-tag";

const GROUP_POST_SURVEY_FRAGMENT = gql`
  fragment GroupPostSurvey on GroupPostSurvey {
    id
    uuid
    title
    description
    schema
    status
    contextId
    groupId
  }
`;

export const GROUP_POST_SURVEYS = gql`
  query GroupPostSurveys($groupId: ID!) {
    groupPostSurveys(groupId: $groupId) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const CREATE_GROUP_POST_SURVEY = gql`
  mutation CreateGroupPostSurvey($groupId: ID!, $title: String!, $description: String, $schema: JSON!) {
    createGroupPostSurvey(groupId: $groupId, title: $title, description: $description, schema: $schema) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const UPDATE_GROUP_POST_SURVEY = gql`
  mutation UpdateGroupPostSurvey($surveyId: ID!, $title: String!, $description: String, $schema: JSON!) {
    updateGroupPostSurvey(surveyId: $surveyId, title: $title, description: $description, schema: $schema) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const PUBLISH_GROUP_POST_SURVEY = gql`
  mutation PublishGroupPostSurvey($surveyId: ID!) {
    publishGroupPostSurvey(surveyId: $surveyId) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const CLOSE_GROUP_POST_SURVEY = gql`
  mutation CloseGroupPostSurvey($surveyId: ID!) {
    closeGroupPostSurvey(surveyId: $surveyId) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const GROUP_POST_SURVEY_RESPONSES = gql`
  query GroupPostSurveyResponses($surveyId: ID!) {
    groupPostSurveyResponses(surveyId: $surveyId) {
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
