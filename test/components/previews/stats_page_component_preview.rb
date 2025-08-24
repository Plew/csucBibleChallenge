# frozen_string_literal: true

class StatsPageComponentPreview < ViewComponent::Preview
  # Default stats page
  def default
    render(StatsPageComponent.new)
  end
end