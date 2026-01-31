# Bible Reading Challenge App

A Rails 8 application for managing Bible reading challenges. Users can join challenges, track their reading progress, and participate in groups.

## Quick Start

### Option A: Native (requires Ruby, Node.js)

```bash
git clone <repository-url>
cd nargh
bin/setup
bin/dev
```

### Option B: Docker (no local dependencies)

```bash
git clone <repository-url>
cd nargh
bin/docker-dev build
bin/docker-dev setup
bin/docker-dev up
```

**📖 For detailed setup instructions, see [SETUP.md](SETUP.md)**

The app will be available at `http://localhost:3000`

**Test Account:** `pdbradley@gmail.com` / `nargh111`

## Requirements

### Native Development
- Ruby 3.x
- Node.js and npm
- SQLite3

### Docker Development
- Docker Desktop

## What is This?

This is a Bible reading challenge app where users can:
- Join reading challenges with scheduled daily readings
- Track progress through Bible chapters
- Participate in groups within challenges
- View personal and group statistics
- Read Bible verses in multiple versions (KJV, Elberfelder)

## Project Structure

### Key Models

- `User` - Authentication with secure password, avatar support
- `Challenge` - Reading challenges with timezone support
- `Reading` - Individual Bible chapters within challenges
- `Group` - Optional groups within challenges
- `UserReading` - Progress tracking (completed readings)
- `Verse` - Bible text storage (KJV and other versions)

### Tech Stack

**Backend:**
- Rails 8
- SQLite3 (development/test)
- Session-based authentication
- REST API at `/api/v1/`

**Frontend:**
- Tailwind CSS + DaisyUI components
- Hotwire (Turbo + Stimulus)
- ViewComponent for reusable UI
- Mobile-first responsive design

## Development

### Common Commands

```bash
# Start development server
bin/dev

# Run tests
bundle exec rspec

# Generate test data (Munich challenge with groups/users)
bin/rails fake_munich:generate

# Build CSS
npm run build:css

# View component library
bin/rails lookbook

# Code quality
bundle exec rubocop   # Linter
bundle exec brakeman  # Security scanner
```

### Database

```bash
bin/rails db:migrate          # Run migrations
bin/rails db:seed             # Import Bible verses
bin/rails fake_munich:generate # Generate test challenge data
```

## Production

Deployed to `reverse.eleven89.org` using Kamal.

```bash
kamal deploy  # Deploy to production
kamal logs    # View logs
```

Production credentials (AWS SES for email) are encrypted in `config/credentials.yml.enc`. Development doesn't require credentials.

## Documentation

- **[SETUP.md](SETUP.md)** - Complete setup and troubleshooting guide
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines for AI assistance
- **[docs/prd.md](docs/prd.md)** - Product requirements and API specs
- **[.cursor/rules/](.cursor/rules/)** - Code style and development protocols

## Troubleshooting

See [SETUP.md](SETUP.md) for detailed troubleshooting.

Quick fixes:

```bash
# Server won't start
rm tmp/pids/server.pid && bin/dev

# Missing Bible data
bin/rails db:seed

# CSS not building
npm install && npm run build:css
```

## License

[Add your license here]
