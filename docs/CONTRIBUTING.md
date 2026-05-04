# Contributing to Pragmatic Meet

Thank you for contributing! To ensure a smooth onboarding process, please follow these guidelines.

## Getting Started

1.  **Environment Setup**: Follow the [Quick Start in the README](../README.md#quick-start).
2.  **Architecture**: Familiarize yourself with the project structure in [docs/dev.md](dev.md).

## Development Workflow

### 1. Branching & PRs
- Create a branch from `main`.
- Use descriptive branch names: `feat/add-notification-system`, `fix/broken-event-link`.
- Keep pull requests focused on a single change or feature.

### 2. Local Verification (Required)
Before submitting a PR, ensure your changes pass all local checks. This minimizes CI failures and speeds up review.

```bash
# From the repository root (Docker)
make format    # Runs Elixir formatter, Credo, and Frontend linting
make test      # Runs backend and frontend tests
```

### 3. Commit Messages
- Use clear, concise commit messages.
- Reference issue numbers if applicable.

## Coding Standards

- **Elixir**: Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide). Ensure `mix credo --strict` passes.
- **Frontend**: Follow Vue 3 Composition API best practices. Use TypeScript for all new components.
- **Styles**: Use Tailwind CSS utility classes. Avoid custom CSS in `<style>` blocks unless absolutely necessary.

## Reporting Bugs
Use the issue tracker to report bugs. Please include:
- A clear description of the issue.
- Steps to reproduce.
- Expected vs. actual behavior.
- Environment details (Docker vs. Native, OS).
