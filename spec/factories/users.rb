FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    # no key here, it should be generated upon create
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
