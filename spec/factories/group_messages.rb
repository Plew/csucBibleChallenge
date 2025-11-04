FactoryBot.define do
  factory :group_message do
    group
    user
    sequence(:content) { |n| "This is group message number #{n}" }

    trait :encouraging do
      content { "Great job everyone! Keep up the good work." }
    end

    trait :question do
      content { "What did everyone think about today's reading?" }
    end

    trait :long do
      content do
        "I really enjoyed today's passage. It reminded me of how important it is to stay connected " \
        "with our faith community. Looking forward to discussing this more with the group!"
      end
    end
  end
end
