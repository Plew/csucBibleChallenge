FactoryBot.define do
  factory :user_challenge_enrollment do
    user # Assumes a :user factory exists
    challenge # Assumes a :challenge factory exists

    trait :organizer do
      role { "organizer" }
    end
  end
end
