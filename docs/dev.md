# Documentation for Developers

## Technologies

Mobilizon is a federated event platform using a modern full-stack architecture:

*   **Backend**: [Elixir](https://elixir-lang.org/) with the [Phoenix Framework](https://www.phoenixframework.org/).
*   **Frontend**: [Vue.js 3](https://vuejs.org/) (Composition API) with [TypeScript](https://www.typescriptlang.org/).
*   **API**: [GraphQL](https://graphql.org/) via [Absinthe](https://absinthe-graphql.org/) (backend) and [Apollo](https://apollo.vuejs.org/) (frontend).
*   **Database**: [PostgreSQL](https://www.postgresql.org/) with [PostGIS](https://postgis.net/) for geospatial data.
*   **Styling**: [Tailwind CSS](https://tailwindcss.com/) and [Oruga UI](https://oruga-ui.com/).
*   **Federation**: [ActivityPub](https://www.w3.org/TR/activitypub/) protocol for decentralized social networking.

## Architecture & Data Flow

Understanding how a request moves through the system:

1.  **Frontend**: Vue components in `src/components` or `src/views` use Apollo to send GraphQL queries/mutations.
2.  **API Layer**: 
    *   `lib/graphql/schema` defines the GraphQL types and fields.
    *   `lib/graphql/resolvers` handles the incoming requests and calls the appropriate business logic.
3.  **Business Logic**:
    *   `lib/mobilizon` contains the core domain logic, Ecto schemas, and database queries.
    *   `lib/service` contains specialized services (e.g., geospatial, notifications).
4.  **Federation**: When an event is created or updated, `lib/federation` handles the conversion to ActivityStreams and signs/sends activities to other instances.

## Directory Structure

*   `config/`: Backend configuration (compile-time and runtime).
*   `lib/`:
    *   `federation/`: ActivityPub logic (sending/receiving activities, signatures).
    *   `graphql/`: GraphQL API layer (schema declarations and resolvers).
    *   `mobilizon/`: Domain models (Actors, Events, Users, etc.) and database context logic.
    *   `service/`: Internal services (Geospatial, Email, Exports).
    *   `web/`: HTTP layer (controllers, plugs, and the Phoenix endpoint).
*   `src/`: Frontend source code (Vue components, assets, i18n).
*   `test/`: Backend test suite.
*   `docker/`: Docker configuration and environment setup.

## Key Concepts

### Actors
In Mobilizon, everything that can perform actions is an **Actor**. This includes:
*   **Users**: Individual accounts.
*   **Profiles/Identities**: A user can have multiple identities.
*   **Groups**: Organizations or collectives.

### Federation
Mobilizon instances communicate via ActivityPub. When you interact with an event on a remote instance, your local instance sends an Activity (like `Follow`, `Join`, or `Create`) to the remote actor's inbox.

## Further Reading
*   [Upstream Contribution Guide](https://docs.joinmobilizon.org/contribute/)
*   [Production Deployment](PRODUCTION_DEPLOYMENT.md)
*   [OAuth Setup](OAUTH_SETUP.md)
