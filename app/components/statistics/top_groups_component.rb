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
end