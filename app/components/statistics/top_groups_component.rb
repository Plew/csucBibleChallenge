# frozen_string_literal: true

class Statistics::TopGroupsComponent < ViewComponent::Base
  def initialize(top_groups_data:)
    @top_groups_data = top_groups_data
  end

  private

  attr_reader :top_groups_data

  def has_groups?
    top_groups_data.any?
  end

  def avatar_fallback_initials(member)
    member[:username].first.upcase
  end
end