FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    # no key here, it should be generated upon create
  end
end
