# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(challenge:, challenge_summary_stats:, personal_stats:, top_readers_data:, participant_count:, top_groups_data:, seven_day_leaderboard_data:, perfect_record_data: nil, current_sprint: nil, sprint_stats: nil, challenge_graph_data: nil, sprint_graph_data: nil, most_liked_verse: nil, most_liked_verse_today: nil)
    @challenge = challenge
    @challenge_summary_stats = challenge_summary_stats
    @personal_stats = personal_stats
    @top_readers_data = top_readers_data
    @participant_count = participant_count
    @top_groups_data = top_groups_data
    @seven_day_leaderboard_data = seven_day_leaderboard_data
    @perfect_record_data = perfect_record_data
    @current_sprint = current_sprint
    @sprint_stats = sprint_stats
    @challenge_graph_data = challenge_graph_data
    @sprint_graph_data = sprint_graph_data
    @most_liked_verse = most_liked_verse
    @most_liked_verse_today = most_liked_verse_today
  end

  private

  attr_reader :challenge, :challenge_summary_stats, :personal_stats, :top_readers_data, :participant_count, :top_groups_data, :seven_day_leaderboard_data, :perfect_record_data, :current_sprint, :sprint_stats, :challenge_graph_data, :sprint_graph_data, :most_liked_verse, :most_liked_verse_today
end
