# frozen_string_literal: true

class Statistics::RecentReadersComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(readers:)
    @readers = readers || []
  end

  def render?
    readers.any?
  end

  private

  attr_reader :readers

  def abbreviated_time(time_ago_str)
    time_ago_str
      .gsub("about ", "")
      .gsub(" minutes", "m")
      .gsub(" minute", "m")
      .gsub(" hours", "h")
      .gsub(" hour", "h")
      .gsub(" days", "d")
      .gsub(" day", "d")
      .gsub("less than a1m", "<1m")
      .gsub("less than 1m", "<1m")
  end
end
