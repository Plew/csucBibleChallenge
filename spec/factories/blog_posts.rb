FactoryBot.define do
  factory :blog_post do
    association :challenge
    association :user, factory: :user, admin: true
    sequence(:title) { |n| "Blog Post #{n}" }
    content { "This is a blog post content with some **markdown** formatting." }
    visible { true }
  end
end
