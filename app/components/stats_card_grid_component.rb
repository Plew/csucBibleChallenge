# frozen_string_literal: true

class StatsCardGridComponent < ViewComponent::Base
  def initialize(today_reading:, challenge_members:, chapters_read:, chapters_today:, top_readers:)
    @today_reading = today_reading
    @challenge_members = challenge_members
    @chapters_read = chapters_read
    @chapters_today = chapters_today
    @top_readers = top_readers
  end

  private

  attr_reader :today_reading, :challenge_members, :chapters_read, :chapters_today, :top_readers
end