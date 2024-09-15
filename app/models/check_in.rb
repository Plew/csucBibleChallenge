class CheckIn < ApplicationRecord
  belongs_to :user
  validates :recorded_on, presence: true

  def self.for_user_and_date?(user, date)
    date = Date.parse(date) if date.is_a?(String)
    CheckIn.find_by(user: user, recorded_on: date) ? true : false
  end

end
