FactoryBot.define do
  factory :badge do
    sequence(:name) { |n| "Badge #{n}" }
    description { "This badge is awarded for completing specific achievements." }
    icon { "🏆" }
  end
end
