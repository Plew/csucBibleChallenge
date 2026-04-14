FactoryBot.define do
  factory :poke do
    association :poker, factory: :user
    association :pokee, factory: :user
    challenge
    poked_on { Date.current }
  end
end
