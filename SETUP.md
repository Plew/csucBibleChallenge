# Setup Instructions

Complete guide for setting up the Bible Reading Challenge application after cloning.

## Requirements

### Native Development
- **Ruby** 3.x or higher
- **Node.js** and npm
- **SQLite3** (usually pre-installed on macOS/Linux)
- **Git**

### Docker Development
- **Docker Desktop** (includes Docker Compose)
- **Git**

## Docker Setup (Recommended for New Contributors)

If you don't have Ruby/Node.js installed locally, use Docker:

```bash
# Clone the repository
git clone <repository-url>
cd nargh

# Build the Docker image
bin/docker-dev build

# Initialize the database
bin/docker-dev setup

# Start development server
bin/docker-dev up
```

The app will be available at `http://localhost:3000`

### Docker Commands

| Command | Description |
|---------|-------------|
| `bin/docker-dev up` | Start development environment |
| `bin/docker-dev down` | Stop the environment |
| `bin/docker-dev shell` | Open bash in container |
| `bin/docker-dev console` | Rails console |
| `bin/docker-dev test` | Run RSpec tests |
| `bin/docker-dev reset` | Full rebuild (removes all data) |

### Docker Notes

- **Database:** SQLite files are stored in `storage/` and persist between container restarts
- **Production scripts:** `bin/pull_prod_db` works from the host - the container sees changes immediately
- **Code changes:** Mounted live - edit files normally, changes appear on refresh
- **Gems/npm:** Cached in Docker volumes for fast subsequent starts

## Native Setup

The fastest way to get started (if you have Ruby/Node.js installed) is using the automated setup script:

```bash
# Clone the repository
git clone <repository-url>
cd nargh

# Run automated setup
bin/setup

# Start the development server
bin/dev
```

The app will be available at `http://localhost:3000`

### What `bin/setup` Does

The setup script is **idempotent** (safe to run multiple times) and performs these steps:

1. ✅ Installs Bundler and Ruby gem dependencies
2. ✅ Installs Node.js dependencies (Tailwind CSS, DaisyUI, Playwright)
3. ✅ Creates SQLite database files
4. ✅ Runs all database migrations
5. ✅ Imports Bible verse data (KJV and Elberfelder versions from `db/texts/`)
6. ✅ Clears old logs and temp files
7. ✅ Attempts to restart the application server

## Manual Setup (Step by Step)

If you prefer to run each step individually or if `bin/setup` fails:

### 1. Install Ruby Dependencies

```bash
gem install bundler
bundle install
```

### 2. Install JavaScript Dependencies

```bash
npm install
```

This installs:
- Tailwind CSS (utility-first CSS framework)
- DaisyUI (component library)
- Playwright (browser automation for testing)

### 3. Setup Database

```bash
# Create database, run migrations, and seed data (all in one)
bin/rails db:setup

# Or run steps separately:
bin/rails db:create   # Create database files
bin/rails db:migrate  # Run migrations
bin/rails db:seed     # Import Bible verses from db/texts/
```

**Note:** The seed task automatically imports Bible text from CSV files in `db/texts/`. This may take 30-60 seconds.

### 4. Build CSS Assets

```bash
npm run build:css
```

### 5. Start the Server

```bash
# Recommended: Starts Rails + CSS file watching
bin/dev

# Or Rails only (CSS won't auto-rebuild)
bin/rails server
```

## Test Data

### Using the Test Account

A test account is available for immediate use:

- **Email:** `pdbradley@gmail.com`
- **Password:** `nargh111`

### Generating Fake Munich Challenge

To populate the app with realistic test data (challenge, groups, users, and reading progress):

```bash
bin/rails fake_munich:generate
```

This task:
- Creates a "Munich Fall Reading Challenge"
- Generates 4 groups (Sauerkraut, Bratwurst, Pretzel, Schnitzel)
- Creates ~20 fake users with German names
- Enrolls users in groups
- Simulates reading completion data

**Note:** This task deletes and recreates the Munich challenge each time you run it.

## Verifying Your Setup

After setup, verify everything works:

```bash
# Check database has data
bin/rails runner "puts \"Users: #{User.count}, Verses: #{Verse.count}\""

# Run tests
bundle exec rspec

# Check CSS builds
npm run build:css

# Start the app
bin/dev
```

You should see:
- Users count (at least 1 for the test account)
- Verses count (31,000+ verses after seed)
- All tests passing
- CSS built successfully
- Server running on port 3000

## Common Issues

### Server won't start - "PID file exists"

```bash
rm tmp/pids/server.pid
bin/dev
```

### No Bible verses in database

```bash
# Re-run the seed task
bin/rails db:seed
```

The seed task imports from `db/texts/lubbock_texts.csv` and `db/texts/elberfelder_2006.csv`.

### CSS not loading

```bash
# Rebuild CSS
npm install
npm run build:css

# Then restart server
bin/dev
```

### Bundle install fails

```bash
# Update Bundler
gem install bundler
bundle update --bundler
bundle install
```

### Database already exists error

```bash
# Reset the database (WARNING: deletes all data)
bin/rails db:drop db:create db:migrate db:seed
```

### Node modules issues

```bash
# Clear and reinstall
rm -rf node_modules package-lock.json
npm install
```

## Production Setup

### Credentials

The app uses Rails encrypted credentials for production configuration (AWS SES email settings).

- **Development:** Credentials are **optional** - the app runs without them
- **Production:** Requires `config/master.key` to decrypt `config/credentials.yml.enc`

To set up credentials for production:

```bash
# Edit credentials (requires master.key)
EDITOR=nano bin/rails credentials:edit
```

Expected structure:
```yaml
aws:
  ses:
    region: us-east-1
    smtp_username: YOUR_USERNAME
    smtp_password: YOUR_PASSWORD
```

### Deployment

The app deploys to production using Kamal:

```bash
# Deploy to reverse.eleven89.org
kamal deploy

# View logs
kamal logs

# Execute commands on production
kamal app exec 'bin/rails runner "puts User.count"'
```

## Development Workflow

Once setup is complete:

```bash
# Start development (Rails + CSS watching)
bin/dev

# Run tests
bundle exec rspec

# Generate test data
bin/rails fake_munich:generate

# View component library
bin/rails lookbook
# Then visit http://localhost:3000/lookbook

# Run linters
bundle exec rubocop
bundle exec brakeman
```

## Next Steps

- Log in with test account: `pdbradley@gmail.com` / `nargh111`
- Generate test data: `bin/rails fake_munich:generate`
- Read the API docs: `docs/prd.md`
- Review development guidelines: `CLAUDE.md`
- Check code style rules: `.cursor/rules/`

## Getting Help

If you encounter issues not covered here:

1. Check the troubleshooting section above
2. Review `CLAUDE.md` for project-specific conventions
3. Check GitHub issues
4. Verify you have all requirements installed (Ruby, Node.js, SQLite3)
