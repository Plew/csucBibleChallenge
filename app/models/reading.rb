class Reading < ApplicationRecord
  belongs_to :challenge
  has_many :user_readings, dependent: :destroy
  has_many :completed_by_users, through: :user_readings, source: :user

  validates :title, presence: true
  validates :scheduled_date, presence: true
end
