FactoryBot.define do
  factory :verse do
    version { "MyString" }
    book_number { 1 }
    chapter_number { 1 }
    verse_number { 1 }
    verse_text { "MyText" }
  end
end
