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

    # Render squares similar to reading history graph
    squares = (0...total).map do |i|
      filled = i < completed
      square_class = filled ? "w-3 h-3 rounded-sm bg-success" : "w-3 h-3 rounded-sm border border-success"
      "<div class=\"#{square_class}\"></div>"
    end

    squares.join.html_safe
  end
end
