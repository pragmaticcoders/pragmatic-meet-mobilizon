# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mobilizon is a federated event organization and mobilization platform built with:
- **Backend**: Elixir/Phoenix framework with PostgreSQL database
- **Frontend**: Vue 3 with TypeScript, Tailwind CSS, and Oruga UI
- **API**: GraphQL using Absinthe (backend) and Apollo (frontend)
- **Federation**: ActivityPub protocol for decentralized social networking

## Development Commands

### Frontend (Vue/TypeScript)
```bash
# Install dependencies
npm ci

# Run development server
npm run dev

# Build for production
npm run build

# Run linting
npm run lint

# Format code
npm run format

# Run tests
npm run test

# Run tests with coverage
npm run coverage
```

### Backend (Elixir/Phoenix)
```bash
# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.create
mix ecto.migrate

# Run development server
mix phx.server

# Run tests
mix test

# Run specific test
mix test path/to/test.exs

# Format code
mix format

# Run code analysis
mix credo --strict

# Reset database
mix ecto.reset
```

### Docker Development
```bash
# Setup development environment
make setup

# Start services
make start

# Run database migrations
make migrate

# Run tests
make test

# Format code
make format

# View logs
make logs

# Stop services
make stop
```

## Architecture Overview

### Backend Structure (`lib/`)
- `federation/` - ActivityPub federation logic, activity handling, and signatures
- `graphql/` - GraphQL API layer
  - `schema/` - GraphQL schema definitions
  - `resolvers/` - Business logic for GraphQL queries/mutations
  - `api/` - High-level API functions
- `mobilizon/` - Core domain models and database queries
  - `actors/` - Users, groups, and bots
  - `events/` - Events, participants, and sessions
  - `discussions/` - Comments and discussions
  - `users/` - User accounts and authentication
- `service/` - Business services (geospatial, notifications, exports, etc.)
- `web/` - HTTP layer (controllers, views, authentication)
  - `controllers/` - REST and ActivityPub endpoints
  - `email/` - Email templates and mailer
  - `plugs/` - HTTP middleware

### Frontend Structure (`src/`)
- `components/` - Reusable Vue components organized by feature/domain
- `views/` - Page-level Vue components representing routes
- `graphql/` - GraphQL queries, mutations, and fragments
- `router/` - Vue Router configuration
- `composition/` - Vue 3 Composition API utilities
- `services/` - Frontend services and utilities
- `types/` - TypeScript type definitions
- `assets/` - Styling, images, and static assets
- `i18n/` - Internationalization files and translations
- `plugins/` - Vue plugins (notifications, etc.)
- `utils/` - Utility functions and helpers

### Key Concepts
- **Actors**: Unified model for users, groups, and bots
- **Events**: Core entity with participants, metadata, and federation support
- **Federation**: ActivityPub implementation for cross-instance communication
- **GraphQL**: Primary API interface with strong typing
- **Identities**: Users can have multiple actor identities

## Frontend Architecture

### Styling System

The frontend uses a custom design system built on Tailwind CSS with two core styling files:

#### `src/assets/tailwind.css`
- **Design System Foundation**: Defines CSS custom properties for the complete design system
- **Color Palette**: Primary (blue), secondary (pink), success (green), warning (orange), error (red), and gray scales
- **Typography**: Mulish font family with structured text sizes (xs/sm/md/lg/xl/2xl) and line heights
- **Spacing Scale**: Consistent spacing from 4px to 80px using CSS custom properties
- **Component Classes**: Pre-built button, card, form, and utility classes
- **No Rounded Corners**: Global override removes rounded corners app-wide (except avatar images)
- **Dark Mode Support**: CSS custom properties for dark theme variants

#### `src/assets/oruga-tailwindcss.css`
- **Oruga UI Integration**: Styles for Oruga UI components (buttons, inputs, dropdowns, etc.)
- **Component Theming**: Button variants (primary, danger, success, warning, outlined, text)
- **Form Controls**: Styled inputs, selects, checkboxes, radios with consistent design
- **Interactive Elements**: Modals, notifications, tooltips, pagination, tabs
- **Dark Mode**: Comprehensive dark theme support for all components

**Styling Approach**:
- CSS custom properties for consistency and theming
- Utility-first with semantic component classes
- Design tokens for colors, typography, spacing
- Zero border-radius policy for sharp, modern aesthetic
- Responsive design with mobile-first approach

### Internationalization (i18n)

#### `src/utils/i18n.ts`
- **Vue i18n Integration**: Uses Vue 3 i18n with composition API
- **Dynamic Loading**: Language files loaded asynchronously on demand
- **Locale Detection**: Automatic detection from localStorage, DOM lang attribute, or browser language
- **Fallback Strategy**: Falls back to English (en_US) if language not available
- **RTL Support**: Automatic direction detection for Arabic, Hebrew, Persian, etc.
- **Pluralization**: Custom pluralization rules for different languages

**Language Support**:
- Primary: English (en_US), French (fr_FR)
- Multi-locale: Supports language variants (e.g., fr_FR vs fr_CA)
- File Structure: JSON files in `src/i18n/` directory
- Format: Nested JSON with dot notation for complex translations

### Notifications System

#### `src/plugins/notifier.ts`
- **Vue Plugin**: Global notification system using Oruga UI
- **Methods**: `success()`, `error()`, `info()` for different notification types
- **Configuration**: 5-second duration, bottom-right positioning
- **HTML Escaping**: Automatic escaping for security
- **Global Access**: Available as `$notifier` on Vue instances

**Usage**:
```javascript
this.$notifier.success("Event created successfully!");
this.$notifier.error("Failed to save changes");
this.$notifier.info("New message received");
```

### Icons and Assets

#### `public/img/` Directory
**Pragmatic Icons** (Most Important):
- `pragmatic_logo.svg` - Main application logo
- `pragmatic_logo_small.svg` - Compact version for headers/favicons
- `pragmatic_social_media.svg` - Social media sharing image
- `pragmatic_apple_touch.svg` - iOS touch icon

**Feature Icons**:
- `fediverse_monochrome.svg` - Federation/ActivityPub representation
- `peertube_monochrome.svg` - PeerTube integration
- `owncast_monochrome.svg` - Owncast streaming platform
- `sign_language_monochrome.svg` - Accessibility features
- `wordpress-logo.svg` - WordPress integration

**UI Elements**:
- `shape-1.svg`, `shape-2.svg`, `shape-3.svg` - Decorative shapes
- `undraw_*.svg` - Illustration assets for empty states and onboarding
- `categories/` - Event category icons
- `icons/` - General UI icons
- `pics/` - Photography and image assets

### Views (Page Components)

#### Core Application Views
- **`HomeView.vue`** (19KB) - Landing page with event discovery, search, and featured content
- **`SearchView.vue`** (35KB) - Advanced search interface with filters, maps, and results
- **`AboutView.vue`** - Instance information, terms, and community guidelines
- **`CategoriesView.vue`** - Event category browser and organization
- **`SettingsView.vue`** - User preferences and account settings
- **`InteractView.vue`** - Cross-instance interaction handling
- **`PageNotFound.vue`** - 404 error page
- **`ErrorView.vue`** - General error handling

#### Feature-Specific View Directories
- **`Event/`** - Event creation, editing, details, and participation
- **`Group/`** - Group management, member administration, and discovery
- **`User/`** - Profile management, identity switching, and user settings
- **`Admin/`** - Instance administration interface (moderation, settings)
- **`Account/`** - Authentication flows (login, register, email validation)
- **`Posts/`** - Content publishing and timeline management
- **`Discussions/`** - Comment threads and conversation management
- **`Resources/`** - File sharing and resource management
- **`Settings/`** - Granular user and instance configuration
- **`Moderation/`** - Content moderation tools and reports
- **`OAuth/`** - Third-party authentication integration
- **`Conversations/`** - Private messaging and direct communication
- **`Todos/`** - Task management and organization features

### Components (Reusable Elements)

#### Navigation and Layout
- **`NavBar.vue`** (18KB) - Main navigation with user menu, search, and mobile responsive design
- **`PageFooter.vue`** - Site footer with links and instance information
- **`ErrorComponent.vue`** - Reusable error display with retry functionality

#### Core UI Components
- **`TextEditor.vue`** (17KB) - Rich text editor with formatting, media upload, and mention support
- **`SearchField.vue`** - Unified search input with autocomplete
- **`TagElement.vue`** - Tag display and interaction component
- **`PictureUpload.vue`** - Image upload with preview and cropping
- **`LeafletMap.vue`** (5.6KB) - Interactive maps for location selection and display

#### Feature-Specific Component Directories
- **`Event/`** - Event cards, forms, participant lists, QR codes
- **`Group/`** - Group cards, member management, invitation system
- **`User/`** - Profile components, avatar management, identity switching
- **`Comment/`** - Threaded discussions, reply forms, moderation tools
- **`Share/`** - Social sharing buttons and federation options
- **`Map/`** - Location services and geographic components
- **`Address/`** - Location input and geocoding integration
- **`Activity/`** - ActivityPub federation and timeline components
- **`Dashboard/`** - Analytics and administrative overview widgets
- **`Settings/`** - Configuration forms and preference management
- **`Report/`** - Content reporting and moderation interface
- **`Resource/`** - File management and sharing components
- **`Post/`** - Content creation and display components
- **`Participation/`** - Event attendance and RSVP management
- **`Feedback/`** - User feedback forms and rating systems
- **`Search/`** - Search result display and filtering components
- **`Todo/`** - Task creation and management interface
- **`Image/`** - Image processing and gallery components
- **`Categories/`** - Event categorization and taxonomy
- **`About/`** - Instance information and documentation
- **`Local/`** - Instance-specific customizations
- **`FullCalendar/`** - Calendar integration and event scheduling
- **`Home/`** - Homepage content blocks and featured sections
- **`OAuth/`** - Third-party authentication components
- **`Utils/`** - Utility components and common patterns
- **`Editor/`** - Text editing utilities and extensions
- **`Conversations/`** - Direct messaging and private communication

**Component Organization Principles**:
- **Domain-driven**: Components grouped by feature area
- **Reusability**: Shared components in root, specific ones in subdirectories
- **Composition**: Large components broken into smaller, focused pieces
- **TypeScript**: Full type safety with Vue 3 Composition API
- **Accessibility**: ARIA labels, keyboard navigation, screen reader support

## Testing Approach

- **Backend**: Use `mix test` for Elixir tests. Tests use ExMachina for factories
- **Frontend**: Use `npm run test` for Vue component tests with Vitest
- **E2E**: Playwright tests in `tests/e2e/`
- **Coverage**: `mix coveralls.html` (backend) and `npm run coverage` (frontend)

## Database

PostgreSQL with PostGIS extension for geospatial features. Key migrations are in `priv/repo/migrations/`.

## Important Configuration

- Backend config: `config/` directory (dev.exs, test.exs, prod.exs)
- Frontend environment: `.env` files and `vite.config.js`
- Docker setup: `docker/development/` for local development

## Federation

Mobilizon implements ActivityPub for federation. Key modules:
- `Federation.ActivityPub` - Core ActivityPub logic
- `Federation.ActivityStream` - Activity serialization
- `Web.ActivityPubController` - Federation endpoints

## Common Development Tasks

### Creating a new GraphQL query/mutation
1. Define schema in `lib/graphql/schema/`
2. Implement resolver in `lib/graphql/resolvers/`
3. Add GraphQL query/mutation in `src/graphql/`
4. Update Vue components to use the new API

### Adding a new model
1. Create Ecto schema in `lib/mobilizon/`
2. Add database migration with `mix ecto.gen.migration`
3. Create GraphQL schema and resolver if needed
4. Update frontend types in `src/types/`