import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { ADDRESS_FRAGMENT } from "./address";
import { EVENT_OPTIONS_FRAGMENT } from "./event_options";
import { TAG_FRAGMENT } from "./tags";

export const LOGGED_USER_PARTICIPATIONS = gql`
  query LoggedUserParticipations(
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $page: Int
    $limit: Int
  ) {
    loggedUser {
      id
      participations(
        afterDatetime: $afterDateTime
        beforeDatetime: $beforeDateTime
        page: $page
        limit: $limit
      ) {
        total
        elements {
          event {
            id
            uuid
            url
            title
            picture {
              uuid
              url
              alt
            }
            beginsOn
            status
            visibility
            organizerActor {
              ...ActorFragment
            }
            attributedTo {
              ...ActorFragment
            }
            participantStats {
              going
              notApproved
              participant
            }
            options {
              ...EventOptions
            }
            tags {
              id
              slug
              title
            }
            physicalAddress {
              ...AdressFragment
            }
          }
          id
          role
          actor {
            ...ActorFragment
          }
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
`;

export const LOGGED_USER_UPCOMING_EVENTS = gql`
  query LoggedUserUpcomingEvents(
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $page: Int
    $limit: Int
  ) {
    loggedUser {
      id
      participations(
        afterDatetime: $afterDateTime
        beforeDatetime: $beforeDateTime
        page: $page
        limit: $limit
      ) {
        total
        elements {
          event {
            id
            uuid
            url
            title
            picture {
              uuid
              url
            }
            beginsOn
            endsOn
            status
            organizerActor {
              ...ActorFragment
            }
            attributedTo {
              ...ActorFragment
            }
            options {
              ...EventOptions
            }
            tags {
              ...TagFragment
            }
            physicalAddress {
              ...AdressFragment
            }
          }
          id
          role
        }
      }
      groupEvents(afterDatetime: $afterDateTime, page: $page, limit: $limit) {
        total
        elements {
          profile {
            id
          }
          group {
            ...ActorFragment
          }
          event {
            id
            uuid
            url
            title
            picture {
              uuid
              url
            }
            beginsOn
            endsOn
            status
            organizerActor {
              ...ActorFragment
            }
            attributedTo {
              ...ActorFragment
            }
            options {
              ...EventOptions
            }
            tags {
              ...TagFragment
            }
            physicalAddress {
              ...AdressFragment
            }
          }
        }
      }
    }
    loggedPerson {
      id
      organizedEvents(
        page: $page
        limit: $limit
      ) {
        total
        elements {
          id
          uuid
          url
          title
          picture {
            uuid
            url
          }
          beginsOn
          endsOn
          status
          organizerActor {
            ...ActorFragment
          }
          attributedTo {
            ...ActorFragment
          }
          options {
            ...EventOptions
          }
          tags {
            ...TagFragment
          }
          physicalAddress {
            ...AdressFragment
          }
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
  ${ADDRESS_FRAGMENT}
  ${EVENT_OPTIONS_FRAGMENT}
  ${TAG_FRAGMENT}
`;

export const PARTICIPANT_QUERY_FRAGMENT = gql`
  fragment ParticipantQuery on Participant {
    role
    id
    actor {
      ...ActorFragment
    }
    event {
      id
      uuid
    }
    metadata {
      cancellationToken
      message
    }
    insertedAt
  }
  ${ACTOR_FRAGMENT}
`;

export const PARTICIPANTS_QUERY_FRAGMENT = gql`
  fragment ParticipantsQuery on PaginatedParticipantList {
    total
    elements {
      ...ParticipantQuery
    }
  }
  ${PARTICIPANT_QUERY_FRAGMENT}
`;
