class CheckIn < ApplicationRecord
  belongs_to :user
  validates :recorded_on, presence: true
end
