FactoryBot.define do
  factory :user_reading do
    user
    reading
    completed_on { Date.today }
  end
end
