require "capybara/rspec"
require "capybara/cuprite"

# Rails' `driven_by :cuprite` overwrites any prior Capybara.register_driver
# block (see actionpack/.../system_testing/driver.rb#register_cuprite), so the
# only way to pass options like :process_timeout or :browser_path through is
# via the `options:` argument on driven_by itself.
CUPRITE_PROCESS_TIMEOUT = ENV.fetch("CUPRITE_PROCESS_TIMEOUT", 60).to_i
CUPRITE_TIMEOUT = ENV.fetch("CUPRITE_TIMEOUT", 30).to_i

def cuprite_browser_options
  {
    "no-sandbox" => nil,
    "disable-gpu" => nil,
    "disable-dev-shm-usage" => nil,
    "disable-features" => "VizDisplayCompositor",
    "disable-background-networking" => nil,
    "disable-default-apps" => nil,
    "disable-sync" => nil,
    "no-first-run" => nil,
    "disable-translate" => nil,
    "metrics-recording-only" => nil
  }
end

CUPRITE_DRIVEN_BY_OPTIONS = {
  headless: true,
  browser_path: ENV["CHROME_BIN"] || ENV["CHROMIUM_BIN"] || "/usr/bin/chromium",
  browser_options: cuprite_browser_options,
  process_timeout: CUPRITE_PROCESS_TIMEOUT,
  timeout: CUPRITE_TIMEOUT,
  inspector: ENV["CUPRITE_INSPECTOR"].present?,
  js_errors: true
}

Capybara.server = :puma, { Silent: true }
Capybara.disable_animation = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite, screen_size: [ 390, 844 ], options: CUPRITE_DRIVEN_BY_OPTIONS
  end

  config.before(:each, type: :system, desktop: true) do
    driven_by :cuprite, screen_size: [ 1400, 1000 ], options: CUPRITE_DRIVEN_BY_OPTIONS
  end
end
