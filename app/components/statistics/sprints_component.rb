# frozen_string_literal: true

class Statistics::SprintsComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(sprints:)
    @sprints = sprints
  end

  private

  attr_reader :sprints

  def format_date(date)
    date.strftime("%b %-d")
  end
end
