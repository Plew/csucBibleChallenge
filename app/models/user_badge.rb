# frozen_string_literal: true

class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  validates :badge_key, presence: true,
                        inclusion: { in: ->(_) { BadgeCatalog.keys } },
                        uniqueness: { scope: [ :user_id, :challenge_id ] }

  def badge
    BadgeCatalog.find(badge_key)
  end
end
