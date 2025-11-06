# frozen_string_literal: true

# Ensure CSS is built before assets are precompiled
# This is critical for production Docker builds where Tailwind CSS
# needs to scan all component files and generate the CSS before
# Propshaft copies assets to public/assets
Rake::Task["assets:precompile"].enhance([ "css:build" ])
