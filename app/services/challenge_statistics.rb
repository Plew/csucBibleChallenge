# frozen_string_literal: true

class ChallengeStatistics
  attr_reader :challenge

  def initialize(challenge)
    @challenge = challenge
  end

  def total_chapters_read
    UserReading.joins(:reading).where(readings: { challenge_id: challenge.id }).count
  end

  def number_of_participants
    challenge.users.count
  end

  def top_participants_by_completion(limit = 10)
    challenge.users
      .map { |user| [ user, UserStatistics.new(user, challenge).completion_rate ] }
      .sort_by { |_, rate| -rate }
      .first(limit)
  end

  def top_participants_by_streak(limit = 10)
    challenge.users
      .map { |user| [ user, UserStatistics.new(user, challenge).longest_streak ] }
      .sort_by { |_, streak| -streak }
      .first(limit)
  end
end
