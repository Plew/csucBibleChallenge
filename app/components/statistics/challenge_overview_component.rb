# frozen_string_literal: true

class Statistics::ChallengeOverviewComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(statistics:, challenge:, recent_readers:)
    @statistics = statistics
    @challenge = challenge
    @recent_readers = recent_readers || []
  end

  private

  attr_reader :statistics, :challenge, :recent_readers

  def first_reader_username
    statistics.first_reader_today&.username || "None yet"
  end

  def first_reader_time_formatted
    if statistics.respond_to?(:first_reader_today_time) && statistics.first_reader_today_time
      time = statistics.first_reader_today_time
      formatted_time = time.in_time_zone(challenge.timezone).strftime("%H:%M")
      "(#{formatted_time})"
    else
      ""
    end
  end
end
