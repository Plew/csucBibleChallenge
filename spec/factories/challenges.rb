FactoryBot.define do
  factory :challenge do
    sequence(:name) { |n| "Challenge \\#{n}" }
    start_date { Date.current }
    end_date { Date.current + 1.month }
    timezone { Time.zone.name }
    association :creator, factory: :user, admin: true
  end
end
