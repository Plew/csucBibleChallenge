class UserReading < ApplicationRecord
  belongs_to :user
  belongs_to :reading

  validates :user_id, uniqueness: { scope: :reading_id, message: "has already marked this reading" }
  validates :completed_on, presence: true
end
