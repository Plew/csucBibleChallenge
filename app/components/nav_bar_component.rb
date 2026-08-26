# frozen_string_literal: true

class NavBarComponent < ViewComponent::Base
  delegate :current_user, :logged_in?, to: :helpers

  def initialize(active_challenge: nil, enrolled_challenges: nil)
    @active_challenge = active_challenge
    @enrolled_challenges = enrolled_challenges
  end

  def active_challenge
    @active_challenge || helpers.active_challenge_for_nav
  end

  def enrolled_challenges
    @enrolled_challenges || helpers.enrolled_challenges_for_nav
  end

  def can_create_challenges?
    current_user&.can_create_challenges?
  end

  def challenge_statuses
    @challenge_statuses ||= begin
      return {} unless current_user && enrolled_challenges.any?

      statuses = {}
      enrolled_challenges.each do |challenge|
        statuses[challenge.id] = helpers.reading_status_for_challenge(challenge, current_user)
      end
      statuses
    end
  end

  def status_for(challenge)
    challenge_statuses[challenge.id] || { has_reading: false, read_today: false }
  end
end
