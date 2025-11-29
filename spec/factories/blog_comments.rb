FactoryBot.define do
  factory :blog_comment do
    association :blog_post
    association :user
    content { "This is a comment on the blog post." }
  end
end
