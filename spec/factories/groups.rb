FactoryBot.define do
  factory :group do
    creator_id { create(:user).id }
    sequence(:name) { |n| "Group #{n}" }
  end
end
