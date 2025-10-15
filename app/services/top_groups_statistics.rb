# frozen_string_literal: true

class TopGroupsStatistics
  def self.call(challenge: nil)
    new(challenge).call
  end

  def initialize(challenge = nil)
    @challenge = challenge
  end

  def call
    groups_scope = @challenge ? @challenge.groups : Group.joins(:challenge)
    
    groups_scope.includes(:users, challenge: :readings).map do |group|
      group_stats = GroupStatistics.new(group)
      {
        group: group,
        completion_percentage: group_stats.completion_percentage,
        on_schedule_percentage: group_stats.on_schedule_percentage,
        group_size: group_stats.group_size,
        total_chapters_read: group_stats.total_chapters_read
      }
    end.sort_by { |group_data| -group_data[:completion_percentage] }
       .first(20)
  end

  private

  attr_reader :challenge
end