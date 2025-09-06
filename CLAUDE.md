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

### Deployment

- Uses Kamal for deployment to `reverse.eleven89.org`
- `kamal deploy` - Deploy to production
- `kamal logs` - View production logs

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

### Testing

- RSpec for all tests with FactoryBot for fixtures
- Shoulda matchers for model validations
- Request specs for API endpoints
- Model specs cover validations, associations, and business logic

### Component Development

- Use ViewComponent for reusable UI components
- Lookbook available at `/lookbook` in development
- Components include: CheckIn, PieChart, UserStats, etc.

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

- Test account: Use `pdbradley@gmail.com` with password `nargh000` for development testing

## Playwright Testing

- Any time you are previewing components in lookbook and using playwright, make sure the browser is full width (desktop)

## Mobile Responsiveness

- All pages need to primarily look right in mobile responsive mode. Desktop is not important
- always when designing anything make sure there are not big margins or padding.  the content should go almost all the way to the left and right.
- in app/controllers/profile are all the controllers managing aspects of a users profile that they can edit.  if anything is added to a users profile, you can look at these controllers and repeat what they have done and how they have done it.