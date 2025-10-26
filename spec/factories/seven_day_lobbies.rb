# frozen_string_literal: true

FactoryBot.define do
  factory :seven_day_lobby do
    association :challenge
    association :user
  end
end
