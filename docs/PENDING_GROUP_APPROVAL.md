# Pending group approval (moderator workflow)

When a new **group** must be approved by instance staff before it is fully public, this optional feature lets **group creators, moderators, and administrators** keep working while the group is in `pending_approval`—with special rules for **events**.

## Enabling

Set the environment variable to the string `true` and **restart** the application (configuration is read at startup; GraphQL config may be cached).

```bash
MOBILIZON_RESTRICTIONS_ALLOW_MODERATOR_ACTIVITY_FOR_PENDING_GROUPS=true
```

- **Default:** disabled (`false` or unset), except local Docker Compose can default it to `true`; see `docker/development/docker-compose.yml` and `.env.template`.
- **Config key:** `config :mobilizon, :restrictions, allow_moderator_activity_for_pending_groups` (see `config/config.exs`, `config/dev.exs`, `config/docker.exs`, `config/prod.exs`).
- **SPA:** The flag is exposed as GraphQL `restrictions.allowModeratorActivityForPendingGroups` so the UI does not need a separate Vite env for behavior.

## Behavior summary

| Area | When the flag is **on** |
|------|-------------------------|
| Group UI | Moderators can manage members, start discussions, announcements, and open event creation while the group is pending approval (banner copy reflects this). |
| New group events | Server sets `pending_group_approval` on the event. The event is **not** public, **not** indexed for public search, **not** federated, and **not** given “new event” notifications until the group is approved. |
| Create flow | Organizers see a confirmation dialog before the first publish/create action. |
| Visibility | Moderators see a badge (e.g. “Awaiting group approval”) on held events where applicable. |
| Group approved | `approveGroup` clears `pending_group_approval` on those events, then runs release side effects (search, notifications where appropriate, federation). |

Rejected or suspended groups do **not** auto-release held events.

## Implementation pointers

- **Release / approve:** `lib/mobilizon/events/pending_group_approval.ex` (uses `Ecto.Changeset.change/2` for the flag update to avoid touching unloaded associations).
- **Resolver:** `lib/graphql/resolvers/group.ex` (`approve_group` passes the group’s integer `id` into release).
- **Create path:** `lib/graphql/resolvers/event.ex` (`maybe_put_pending_group_approval_on_create`).
- **Public visibility:** `lib/mobilizon/events/events.ex` (`filter_not_pending_group_approval`, public event queries).
- **UI:** `src/views/Group/GroupView.vue`, `GroupMembers.vue`, `src/views/Event/EditView.vue` (modal), event cards / `EventView.vue`.

## Operations note

If changing this setting in production, plan for a **restart** after updating the environment. See also the **Instance restrictions** table in the repository `README.md`.
