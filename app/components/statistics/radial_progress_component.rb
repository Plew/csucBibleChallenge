# frozen_string_literal: true

class Statistics::RadialProgressComponent < ViewComponent::Base
  def initialize(percentage:, label:, chapters_completed: nil, chapters_scheduled: nil, color: "accent")
    @percentage = percentage
    @label = label
    @chapters_completed = chapters_completed
    @chapters_scheduled = chapters_scheduled
    @color = color
  end

  private

  attr_reader :percentage, :label, :chapters_completed, :chapters_scheduled, :color

  def color_class
    case color
    when "accent"
      "text-accent"
    when "info"
      "text-info"
    else
      "text-accent"
    end
  end
end
