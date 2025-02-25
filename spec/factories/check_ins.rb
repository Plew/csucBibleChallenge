FactoryBot.define do
  factory :check_in do
    association :user
    recorded_on { Date.current }
    # Add any other attributes that the CheckIn model requires
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
