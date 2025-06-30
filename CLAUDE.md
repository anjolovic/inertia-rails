# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

inertia-rails is the official Ruby on Rails adapter for Inertia.js, enabling developers to build modern single-page applications (SPAs) using React, Vue, or Svelte while maintaining Rails' server-side routing and controllers.

## Development Commands

```bash
# Setup dependencies
bin/setup

# Run tests
bundle exec rspec
bundle exec rspec spec/path/to/specific_spec.rb  # Run single test file
bundle exec rspec spec/path/to/spec.rb:42       # Run test at specific line

# Run linter
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix issues

# Run both tests and linting (default task)
bundle exec rake

# Interactive console with gem loaded
bin/console

# Build gem
bundle exec rake build

# Release gem (maintainers only)
bundle exec rake release
```

## Architecture

### Core Components

1. **Controller Module** (`lib/inertia_rails/controller.rb`): Provides the `render inertia:` method and shared data functionality
2. **Renderer** (`lib/inertia_rails/renderer.rb`): Handles Inertia response generation
3. **Middleware** (`lib/inertia_rails/middleware.rb`): Processes Inertia-specific requests
4. **Props System**: Various prop types for different loading strategies:
   - Regular props: Always included
   - Lazy props (`lazy_prop.rb`): Loaded on demand
   - Deferred props (`defer_prop.rb`): Loaded after initial render
   - Optional props (`optional_prop.rb`): Only on partial reloads
   - Merge props (`merge_prop.rb`): For merging data

### Key Patterns

- **Rails Engine**: Integrates seamlessly with Rails applications
- **Configuration**: Flexible system with defaults and per-controller overrides
- **Generators**: Comprehensive scaffolding for React/Vue/Svelte components
- **Instance Props**: Rails instance variables can be automatically used as props

### Testing Structure

- Tests located in `/spec/`
- Dummy Rails app in `/spec/dummy/` for integration testing
- RSpec helpers in `lib/inertia_rails/rspec.rb`
- Generator tests use `generator_spec` gem

## Important Implementation Details

1. **Component Resolution**: Components are resolved from the `pages/` directory by default
2. **Shared Data**: Set via `inertia_share` in controllers, available across all responses
3. **CSRF Protection**: Automatic XSRF-TOKEN cookie handling
4. **Asset Versioning**: Detects client/server version mismatches
5. **Partial Reloads**: Only requested props are sent on subsequent requests
6. **SSR Support**: Experimental server-side rendering capabilities

## Generator Templates

The gem includes extensive generator templates in `/lib/generators/`:
- Installation generator sets up Inertia in Rails apps
- Controller and scaffold generators create full CRUD interfaces
- Templates support React, Vue, Svelte (v4 and v5) with TypeScript variants
- Separate templates for Tailwind CSS integration

## Code Style

- Ruby 3.0+ required
- RuboCop enforced (see `.rubocop.yml`)
- Follow existing patterns in the codebase
- Instance variables in controllers automatically become props when `use_inertia_instance_props` is enabled

## Common Development Tasks

1. **Adding New Prop Types**: Extend `BaseProp` class in `lib/inertia_rails/props/`
2. **Modifying Generators**: Templates in `lib/generators/inertia_templates/`
3. **Testing Middleware**: Use dummy app requests in specs
4. **Debugging Rendering**: Check `InertiaRails::Renderer#render` method

## Documentation

- Public documentation site source in `/docs/` directory
- API documentation comments throughout codebase
- Examples in generator templates show best practices