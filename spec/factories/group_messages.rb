FactoryBot.define do
  factory :group_message do
    group { nil }
    user { nil }
    content { "MyText" }
  end
end
