FactoryBot.define do
  factory :verse_message do
    verse { nil }
    user { nil }
    content { "MyText" }
  end
end
