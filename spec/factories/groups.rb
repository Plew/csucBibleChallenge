FactoryBot.define do
  factory :group do
    challenge # Assumes a :challenge factory exists
    association :creator, factory: :user
    sequence(:name) { |n| "Group #{n}" }
  end
end
