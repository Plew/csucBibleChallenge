# frozen_string_literal: true

if defined?(Lookbook)
  Lookbook.configure do |config|
    config.preview_layout = "view_component_preview"
    config.preview_paths = [ Rails.root.join("spec/components/previews").to_s ]
  end
end
