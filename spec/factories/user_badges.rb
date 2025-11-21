FactoryBot.define do
  factory :user_badge do
    association :user
    association :badge
    association :challenge
  end
end
