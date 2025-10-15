# frozen_string_literal: true

class Statistics::PersonalStatsComponent < ViewComponent::Base
  def initialize(user_stats:)
    @user_stats = user_stats
  end

  private

  attr_reader :user_stats

  def completion_percentage
    user_stats[:completion_percentage] || 0
  end

  def on_schedule_percentage
    user_stats[:on_schedule_percentage] || 0
  end

  def chapters_completed
    user_stats[:chapters_completed] || 0
  end

  def chapters_scheduled
    user_stats[:chapters_scheduled] || 0
  end
end
