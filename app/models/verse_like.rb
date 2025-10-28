class VerseLike < ApplicationRecord
  belongs_to :user
  belongs_to :reading

  validates :verse_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :user_id, uniqueness: { scope: [ :reading_id, :verse_number ] }
end
