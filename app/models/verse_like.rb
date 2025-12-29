class VerseLike < ApplicationRecord
  belongs_to :reading
  belongs_to :user

  validates :verse_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :user_id, uniqueness: { scope: [ :reading_id, :verse_number ], message: "has already liked this verse" }

  scope :for_verse, ->(reading_id, verse_number) { where(reading_id: reading_id, verse_number: verse_number) }
  scope :by_user, ->(user) { where(user: user) }
end
