# frozen_string_literal: true

class SevenDayLobby < ApplicationRecord
  belongs_to :challenge
  belongs_to :user

  validates :challenge_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :challenge_id }

  # Get all users currently in the lobby for a challenge
  def self.participants_for_challenge(challenge)
    where(challenge: challenge).includes(:user).map(&:user)
  end

  # Check if a user is in the lobby for a challenge
  def self.user_in_lobby?(user, challenge)
    exists?(user: user, challenge: challenge)
  end
end
