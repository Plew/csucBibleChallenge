class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge
  belongs_to :challenge

  validates :user_id, uniqueness: { scope: [ :badge_id, :challenge_id ], message: "already has this badge for this challenge" }
end
