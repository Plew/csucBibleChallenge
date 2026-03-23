# frozen_string_literal: true

class Statistics::SprintsComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(sprints:, current_sprint: nil)
    @sprints = sprints
    @current_sprint = current_sprint
  end

  private

  attr_reader :sprints, :current_sprint

  def format_date(date)
    date.strftime("%b %-d")
  end

  def completed_count
    sprints.count { |s| s.winners_calculated? }
  end

  def active?(sprint)
    current_sprint && sprint.id == current_sprint.id
  end
end
