class GroupMessage < ApplicationRecord
  belongs_to :group
  belongs_to :user

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
