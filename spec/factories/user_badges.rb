FactoryBot.define do
  factory :user_badge do
    user
    challenge
    badge_key { "chapters_50" }
  end
end
