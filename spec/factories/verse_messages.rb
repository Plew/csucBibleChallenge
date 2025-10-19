FactoryBot.define do
  factory :verse_message do
    reading
    user
    verse_number { 1 }
    content { "This is a test comment on a verse." }
  end
end
