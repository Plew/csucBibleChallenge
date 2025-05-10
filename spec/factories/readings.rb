FactoryBot.define do
  factory :reading do
    challenge # Assumes a :challenge factory exists
    sequence(:title) { |n| "Reading Title #{n}" }
    scheduled_date { Date.today }
  end
end
