class VerseMessage < ApplicationRecord
  belongs_to :verse
  belongs_to :user

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
