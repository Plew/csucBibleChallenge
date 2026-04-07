source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft", "~> 1.3.1"
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 2.9"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", "~> 2.2.3"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0.20"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
# gem "tailwindcss-rails"
gem "cssbundling-rails", "~> 1.4.3"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Background job processing
gem "solid_queue"

# Solid Cable for Action Cable without Redis
gem "solid_cable"

gem "swearjar"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem "factory_bot_rails"
gem "view_component"
gem "faker", "~> 3.5.3"
gem "inline_svg"
gem "chartkick", "~> 5.2.1"
gem "redcarpet"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "avatarro"

gem "exception_notification"

# Web Push notifications for PWA
gem "web-push"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", "~> 1.11.1", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "pry", "~> 0.15.2"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "shoulda-matchers", "~> 7.0"
  gem "rails-controller-testing"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "listen"
  gem "actioncable"
  gem "lookbook", "~> 2.3.13"
  gem "hotwire-livereload", "~> 2.1"
  gem "letter_opener"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "cuprite", "~> 0.17"
  gem "selenium-webdriver", "~> 4.39.0"
end
