FactoryBot.define do
  factory :group do
    challenge # Assumes a :challenge factory exists
    association :creator, factory: :user
    sequence(:name) { |n| "Group #{n}" }

    trait :with_messages do
      transient do
        message_count { 5 }
      end

      after(:create) do |group, evaluator|
        create_list(:group_message, evaluator.message_count, group: group, user: group.creator)
      end
    end

    trait :large do
      transient do
        member_count { 10 }
      end

      after(:create) do |group, evaluator|
        create_list(:user_group_enrollment, evaluator.member_count, group: group)
      end
    end
  end
end
