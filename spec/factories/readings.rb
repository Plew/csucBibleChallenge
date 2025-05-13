FactoryBot.define do
  factory :reading do
    challenge # Assumes a :challenge factory exists
    scheduled_date { Date.today }
    book_number { 1 } # Default book_number
    chapter_number { 1 } # Default chapter_number
  end
end
