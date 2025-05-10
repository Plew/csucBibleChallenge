FactoryBot.define do
  factory :challenge do
    sequence(:name) { |n| "Challenge #{n}" }
    start_date { Date.today }
    end_date { Date.today + 1.month }
  end
end
