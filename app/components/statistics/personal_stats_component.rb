# frozen_string_literal: true

class Statistics::PersonalStatsComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(user_stats:, sprint_stats: nil, current_sprint: nil, challenge_graph_data: nil, sprint_graph_data: nil)
    @user_stats = user_stats
    @sprint_stats = sprint_stats
    @current_sprint = current_sprint
    @challenge_graph_data = challenge_graph_data
    @sprint_graph_data = sprint_graph_data
  end

  private

  attr_reader :user_stats, :sprint_stats, :current_sprint, :challenge_graph_data, :sprint_graph_data

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

  def has_active_sprint?
    current_sprint.present? && sprint_stats.present?
  end

  def sprint_completion_percentage
    sprint_stats[:completion_percentage] || 0
  end

  def sprint_on_schedule_percentage
    sprint_stats[:on_schedule_percentage] || 0
  end

  def sprint_chapters_completed
    sprint_stats[:chapters_completed] || 0
  end

  def sprint_chapters_scheduled
    sprint_stats[:chapters_scheduled] || 0
  end
end
