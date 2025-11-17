# frozen_string_literal: true

class Statistics::TopGroupsComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(top_groups_data:)
    @top_groups_data = top_groups_data
  end

  private

  attr_reader :top_groups_data

  def has_groups?
    top_groups_data.any?
  end

  def group_count
    top_groups_data.length
  end

  def render_check_in_squares(completed, total)
    return "" if total.zero?

    # Render squares with empty squares on the left, filled on the right
    empty_count = total - completed
    squares = []

    # Add empty squares first
    empty_count.times do
      squares << "<div class=\"w-3 h-3 rounded-sm border-2 bg-transparent\" style=\"border-color: oklch(var(--su));\"></div>"
    end

    # Add filled squares
    completed.times do
      squares << "<div class=\"w-3 h-3 rounded-sm bg-success\"></div>"
    end

    squares.join.html_safe
  end
end
