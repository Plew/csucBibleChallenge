# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8 application for managing Bible reading challenges. Users can join challenges, track their reading progress, and participate in groups. The app features both a web UI and REST API endpoints.

**Key Models:**

- `User` - Authentication with secure password, avatar support
- `Challenge` - Reading challenges with timezone support
- `Reading` - Individual Bible chapters within challenges
- `Group` - Optional groups within challenges
- `UserReading` - Progress tracking (completed readings)
- `Verse` - Bible text storage (KJV and other versions)

## Development Commands

### Database

- `bin/rails db:create` - Create databases
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Load seed data

### Testing

- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/models/` - Run model tests only
- `bundle exec rspec spec/controllers/` - Run controller tests only
- `bundle exec rspec spec/requests/` - Run request tests only

**Docker testing notes:**
- If the development DB was pulled from production (`bin/pull_prod_db`), its `ar_internal_metadata` has `environment=production`. This causes `db:test:prepare` to fail with `ProtectedEnvironmentError`. Fix: `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:test:prepare` and run specs with the same env var.
- The Docker container runs with `RAILS_ENV=development` by default. Always run specs with `RAILS_ENV=test` explicitly, otherwise CSRF protection is active and all POST/PATCH/DELETE request specs will fail with `ActionController::InvalidAuthenticityToken`. Correct command: `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 docker compose exec -e RAILS_ENV=test app bundle exec rspec`

### Assets & Styling

- `npm run build:css` - Build Tailwind CSS
- `bin/rails css:build` - Alternative CSS build command
- `bin/rails assets:precompile` - Precompile assets for production

### Development Tasks

- `bin/rails fake_munich:generate` - Generate fake data for testing
- `bin/rails lookbook` - Run component library (dev only)
- `bin/rails server` - Start development server

### Code Quality

- `bundle exec rubocop` - Run Ruby linter
- `bundle exec brakeman` - Security vulnerability scanner

### Docker Development (Primary Method)

**Always use Docker for local development.** This ensures a consistent environment.

```bash
# First time setup
bin/docker-dev build     # Build the Docker image
bin/docker-dev setup     # Create and seed database
bin/docker-dev up        # Start development server (http://localhost:3000)

# Daily development
bin/docker-dev up        # Start the environment

# Other commands
bin/docker-dev shell     # Open bash in container
bin/docker-dev console   # Rails console
bin/docker-dev test      # Run RSpec tests
bin/docker-dev down      # Stop the environment
bin/docker-dev reset     # Full rebuild (removes volumes)
```

**Key files:**
- `Dockerfile.dev` - Development container (Ruby 3.2.3, Node 20, Chromium)
- `docker-compose.yml` - Service orchestration (app + Redis)
- `bin/docker-dev` - Helper script

**Note:** The `storage/` directory is bind-mounted, so `bin/pull_prod_db` works from the host and the container sees the updated database immediately.

**CRITICAL: Never run `bin/rails runner`, `bin/rails console`, or any Rails command that touches the database directly on the host.** Always run these inside the Docker container using `docker compose exec app bin/rails runner "..."` or `bin/docker-dev shell`. Running Rails commands on the host while the Docker container is also accessing the same SQLite database causes WAL corruption and disk I/O errors. Similarly, never use `bin/rails db:migrate` on the host — use `docker compose exec app bin/rails db:migrate`.

**Note:** Docker development does NOT affect Kamal deploys - production uses the separate `Dockerfile`.

### Deployment

- Uses Kamal for deployment to `reverse.eleven89.org`
- `kamal deploy` - Deploy to production
- `kamal logs` - View production logs

### Production Management

- **Change user password in production:**
  ```bash
  kamal app exec 'bin/rails runner "user = User.find_by(email: \"EMAIL\"); user.update_attribute(:password, \"NEW_PASSWORD\")"'
  ```
  Note: Use `update_attribute` to bypass validations that require current password

- **Run jobs in production:**
  ```bash
  kamal app exec --roles=web 'bin/rails runner "JobClassName.perform_now"'
  ```
  Important: `kamal app exec` runs on both web and job containers by default, which can cause duplicate execution (e.g., sending duplicate emails). Always specify `--roles=web` or `--roles=job` to run the command only once.

## Architecture

### API Structure

- **Namespace:** `/api/v1/`
- **Authentication:** Session-based (not token-based)
- **Timezone handling:** Challenge-specific timezones for reading validation

### Frontend Stack

- **CSS Framework:** Tailwind CSS + DaisyUI components
- **JavaScript:** Hotwire (Turbo + Stimulus)
- **Design:** Mobile-first responsive design
- **Components:** ViewComponent with Lookbook for development

### Database

- **Development/Test:** SQLite3
- **File Storage:** Active Storage for user avatars
- **Associations:** Complex many-to-many relationships via enrollment models

### Key Business Logic

- Users can only mark readings complete on the scheduled date (respecting challenge timezone)
- Groups are optional within challenges
- Bible text is stored in `Verse` model with version/book/chapter/verse structure

## Development Guidelines

### Code Style

- Follow Rails conventions and Ruby Style Guide
- Use `.cursorrules` for comprehensive Ruby/Rails standards
- Mobile-first design approach
- Use DaisyUI components for UI consistency
- **Array brackets must have spaces inside:** `[ item1, item2 ]` not `[item1, item2]` (RuboCop: Layout/SpaceInsideArrayLiteralBrackets)

### Internationalization (i18n)

**IMPORTANT: This application supports multiple languages (English and German). All user-facing text MUST use Rails i18n.**

- **Never hardcode user-facing text** - Always use `t()` helper in views or `I18n.t()` in Ruby code
- **Translation keys** are organized by section in `config/locales/en.yml` and `config/locales/de.yml`
- **Locale management:**
  - Default locale: English (`en`)
  - Available locales: English (`en`), German (`de`)
  - Locale is set via cookie (`locale`) and persists across sessions
  - Language selector in navigation triggers server-side locale change and page reload
- **Translation key structure:**
  - Common UI: `common.back`, `common.cancel`, `common.save`, etc.
  - Navigation: `navigation.log_in`, `navigation.settings`, etc.
  - Page-specific: `home.tagline`, `challenges.join_challenge`, `profile.account_settings`, etc.
  - Use descriptive, hierarchical keys: `section.subsection.key`
- **What NOT to translate:**
  - Bible verses from database (stored in Verse model)
  - User-generated content (usernames, group names, challenge titles, etc.)
  - Code comments and variable names
  - HTML attributes (class, id, data-*)
- **Adding new text:**
  1. Add translation key to both `config/locales/en.yml` AND `config/locales/de.yml`
  2. Use descriptive key names that indicate context
  3. In views: `<%= t('key.path') %>`
  4. For pluralization: use Rails' built-in pluralization (`_one`, `_other` suffixes)
  5. For interpolation: `t('key', name: user.name)`
- **Example:**
  ```erb
  <%# BAD - hardcoded text %>
  <h1>Welcome</h1>
  <button>Save Changes</button>

  <%# GOOD - using i18n %>
  <h1><%= t('welcome.title') %></h1>
  <button><%= t('common.save_changes') %></button>
  ```

### Testing

- RSpec for all tests with FactoryBot for fixtures
- Shoulda matchers for model validations
- Request specs for API endpoints
- Model specs cover validations, associations, and business logic

### Component Development

- Use ViewComponent for reusable UI components
- Lookbook available at `/lookbook` in development
- Components include: CheckIn, PieChart, UserStats, etc.
- **IMPORTANT:** In ViewComponent templates, Rails view helpers like `turbo_frame_tag`, `link_to`, `form_with`, etc. must be called via the `helpers.` prefix (e.g., `helpers.turbo_frame_tag` not `turbo_frame_tag`)

### Important Files

- `config/routes.rb` - API and UI routing
- `docs/prd.md` - Product requirements and API specifications
- `.cursor/rules/` - Development guidelines and protocols
- `lib/fake_munich.rb` - Test data generation

### Testing Guidelines

- Always use mobile mode on playwright when testing; this application will always be in responsive mode, unless testing component in lookbook. If using lookbook, use desktop mode

## Notes

- To see what versions of the Bible are available, look in the 'version' column of the Verse model

## Dev Credentials

- Test account: Use `pdbradley@gmail.com` with password `nargh111` for development testing

## Playwright Testing

- Any time you are previewing components in lookbook and using playwright, make sure the browser is full width (desktop)

## Mobile Responsiveness

- All pages need to primarily look right in mobile responsive mode. Desktop is not important
- always when designing anything make sure there are not big margins or padding.  the content should go almost all the way to the left and right.
- in app/controllers/profile are all the controllers managing aspects of a users profile that they can edit.  if anything is added to a users profile, you can look at these controllers and repeat what they have done and how they have done it.
- don't ever deploy to production using kamal without being asked to do so
- Deploys to production happen automatically via GitHub Actions CI when tests pass on main. Do not manually run kamal deploy.
- whenever you need to start a rails server, use `bin/docker-dev up`
- when you are using playwright and need to take screenshots, store them in context/screenshots/latest.png, and you can keep overwriting latest.png with each successive screenshot
- no, the playwright screenshots should be saved in context/screenshots off of the app folder, not within .playwright-mcp
- actually it is fine to save it in the .playwright-mcp folder, please remove the instructions that said contrary
- any info about recurring jobs is in config/recurring.yml
- do not run the rails server directly, always use `bin/docker-dev up` for development
- any time i want to show an avatar, use avatar_image_tag in application_helper.rb
- I would prefer you don't do a kamal deploy ever unless explicitly asked to do so.
- whenever i say check this in production or do something in production, I mean the running production app that you would access via kamal commands.
- don't test any work with playwright unless I specifically mention it
- before you start a rails server to test something you should always check to see if one is running already and if it is, just use that
- make sure to always include ApplicationHelper in any view component so that we have access to helper methods in the views for that component
- the seven day winner page is located at app/controllers/admin/seven_day_winner_controller.rb
- whenever we want to render avatars we use the AvatarComponent
- if we have issues with classes being missing in production deploys, make sure to consider the safelist in tailwind.config.js because they may have been used in a ruby class
- We are using Sqlite for our database, NOT postgresql
- any time you interact with linear mcp, creating or finding tickets, they will always be in the "CSM Bible Challenge" project