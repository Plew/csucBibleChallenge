class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges
  has_many :challenges, through: :user_badges

  validates :name, presence: true
  validates :description, presence: true
  validates :icon, presence: true
end
