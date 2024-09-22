FactoryBot.define do
  factory :check_in do
    recorded_on { "2024-09-10" }
    user { nil }
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
