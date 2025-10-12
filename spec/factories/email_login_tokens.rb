FactoryBot.define do
  factory :email_login_token do
    association :user
    association :challenge
    association :reading
    token { SecureRandom.urlsafe_base64(32) }
    sent_at { Time.current }
    clicked_at { nil }
  end
end
