FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" } # has_secure_password will handle the digest
    version { "KJV" }

    trait :admin do
      admin { true }
    end

    trait :with_avatar do
      after(:create) do |user|
        # Note: In real usage, you'd attach an actual file
        # user.avatar.attach(io: File.open('spec/fixtures/files/avatar.png'), filename: 'avatar.png')
      end
    end

    trait :german do
      version { "LUTH1545" }
    end
  end
end
