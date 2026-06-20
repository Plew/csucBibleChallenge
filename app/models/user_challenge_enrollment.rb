class UserChallengeEnrollment < ApplicationRecord
  ROLES = [ "member", "organizer" ].freeze

  belongs_to :user
  belongs_to :challenge

  validates :user_id, uniqueness: { scope: :challenge_id, message: "already enrolled in this challenge" }
  validates :role, inclusion: { in: ROLES }

  def organizer?
    role == "organizer"
  end
end
