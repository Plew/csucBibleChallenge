class Reading < ApplicationRecord
  belongs_to :challenge

  validates :title, presence: true
  validates :scheduled_date, presence: true
end
