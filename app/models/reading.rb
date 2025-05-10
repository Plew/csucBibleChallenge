class Reading < ApplicationRecord
  belongs_to :challenge
  has_many :user_readings, dependent: :destroy
  has_many :completed_by_users, through: :user_readings, source: :user

  validates :title, presence: true
  validates :scheduled_date, presence: true
  validates :book_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :chapter_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
