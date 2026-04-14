class Poke < ApplicationRecord
  belongs_to :poker, class_name: "User"
  belongs_to :pokee, class_name: "User"
  belongs_to :challenge

  validates :poked_on, presence: true
  validates :poker_id, uniqueness: { scope: [ :pokee_id, :challenge_id, :poked_on ], message: "already poked this person today" }
  validate :cannot_poke_self

  private

  def cannot_poke_self
    errors.add(:base, "Cannot poke yourself") if poker_id == pokee_id
  end
end
