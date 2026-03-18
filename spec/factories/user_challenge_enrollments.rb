FactoryBot.define do
  factory :user_challenge_enrollment do
    user # Assumes a :user factory exists
    challenge # Assumes a :challenge factory exists

    trait :admin do
      role { "admin" }
    end
  end
end
