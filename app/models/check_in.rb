class CheckIn < ApplicationRecord
  belongs_to :user
  validates :recorded_on, presence: true

  def self.for_user_and_date?(user, date)
    date = Date.parse(date) if date.is_a?(String)
    CheckIn.find_by(user: user, recorded_on: date) ? true : false
  end

end

# == Schema Information
#
# Table name: check_ins
#
#  id          :integer          not null, primary key
#  recorded_on :date
#  user_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
