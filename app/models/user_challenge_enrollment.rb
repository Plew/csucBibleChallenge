class UserChallengeEnrollment < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  validates :user_id, uniqueness: { scope: :challenge_id, message: "already enrolled in this challenge" }
end
