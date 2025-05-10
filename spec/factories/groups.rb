FactoryBot.define do
  factory :group do
    challenge # Assumes a :challenge factory exists
    sequence(:name) { |n| "Group #{n}" }
  end
end
