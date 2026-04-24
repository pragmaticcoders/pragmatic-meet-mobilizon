import gql from "graphql-tag";

const GROUP_POST_SURVEY_FRAGMENT = gql`
  fragment GroupPostSurvey on GroupPostSurvey {
    id
    title
    description
    schema
    status
    contextId
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
  mutation CreateGroupPostSurvey(
    $groupId: ID!
    $title: String!
    $description: String
    $schema: JSON!
  ) {
    createGroupPostSurvey(
      groupId: $groupId
      title: $title
      description: $description
      schema: $schema
    ) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const UPDATE_GROUP_POST_SURVEY = gql`
  mutation UpdateGroupPostSurvey(
    $groupId: ID!
    $surveyId: String!
    $title: String!
    $description: String
    $schema: JSON!
  ) {
    updateGroupPostSurvey(
      groupId: $groupId
      surveyId: $surveyId
      title: $title
      description: $description
      schema: $schema
    ) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const PUBLISH_GROUP_POST_SURVEY = gql`
  mutation PublishGroupPostSurvey($groupId: ID!, $surveyId: String!) {
    publishGroupPostSurvey(groupId: $groupId, surveyId: $surveyId) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const CLOSE_GROUP_POST_SURVEY = gql`
  mutation CloseGroupPostSurvey($groupId: ID!, $surveyId: String!) {
    closeGroupPostSurvey(groupId: $groupId, surveyId: $surveyId) {
      ...GroupPostSurvey
    }
  }
  ${GROUP_POST_SURVEY_FRAGMENT}
`;

export const GROUP_POST_SURVEY_RESPONSES = gql`
  query GroupPostSurveyResponses($groupId: ID!, $surveyId: String!) {
    groupPostSurveyResponses(groupId: $groupId, surveyId: $surveyId) {
      respondentId
      respondentName
      respondentUsername
      respondentEmail
      submittedAt
      data
    }
  }
`;
