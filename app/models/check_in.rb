class CheckIn < ApplicationRecord
  belongs_to :user
  validates :recorded_on, presence: true

  def self.for_user_and_date?(user, date)
    date = Date.parse(date) if date.is_a?(String)
    CheckIn.find_by(user: user, recorded_on: date) ? true : false
  end

  def self.recent_with_usernames(limit = 10)
    CheckIn.includes(:user)
           .joins(:user)
           .where.not(users: { name: [nil, ''] })
           .order(recorded_on: :desc)
           .limit(limit)
           .map do |check_in| 
            OpenStruct.new(
              date: check_in.recorded_on, 
              username: check_in.user.name,
              timestamp: check_in.created_at
              ) 
           end 
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
