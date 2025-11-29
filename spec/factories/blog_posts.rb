FactoryBot.define do
  factory :blog_post do
    association :challenge
    association :user
    sequence(:title) { |n| "Blog Post #{n}" }
    content { "This is a blog post content with **markdown** support." }
    visible { true }

    trait :hidden do
      visible { false }
    end

    trait :with_comments do
      after(:create) do |blog_post|
        create_list(:blog_comment, 3, blog_post: blog_post)
      end
    end
  end
end
