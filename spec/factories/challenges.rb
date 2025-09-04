FactoryBot.define do
  factory :challenge do
    sequence(:name) { |n| "Challenge \\#{n}" }
    start_date { Date.today }
    end_date { Date.today + 1.month }
    timezone { 'UTC' }
    association :creator, factory: :user, admin: true
  end
end
