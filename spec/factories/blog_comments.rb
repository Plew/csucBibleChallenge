FactoryBot.define do
  factory :blog_comment do
    association :blog_post
    association :user
    sequence(:content) { |n| "This is comment #{n}" }
  end
end
