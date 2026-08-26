# frozen_string_literal: true

class ReadingStatusBadgeComponent < ViewComponent::Base
  def initialize(challenge: nil, status: nil, user: nil, variant: :compact)
    @challenge = challenge
    @status = status
    @user = user
    @variant = variant.to_sym
  end

  def status
    @status ||= begin
      user = @user || helpers.current_user
      if @challenge && user
        @challenge.daily_reading_status(user)
      else
        { has_reading: false, read_today: false, read_count: 0, total_count: 0, reading_title: nil }
      end
    end
  end

  def variant
    @variant
  end
end
