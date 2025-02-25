FactoryBot.define do
  factory :group_membership do
    association :user
    association :group
  end
end
