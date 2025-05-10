class UserChallengeEnrollment < ApplicationRecord
  belongs_to :user
  belongs_to :challenge
  belongs_to :group, optional: true

  validates :user_id, uniqueness: { scope: :challenge_id, message: "already enrolled in this challenge" }
  # Add validation to ensure group belongs to the same challenge as the enrollment? (More complex, for later if needed)
end
