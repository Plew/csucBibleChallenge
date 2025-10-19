class VerseMessage < ApplicationRecord
  belongs_to :reading
  belongs_to :user

  validates :content, presence: true
  validates :verse_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_verse, ->(reading_id, verse_number) { where(reading_id: reading_id, verse_number: verse_number) }
end
