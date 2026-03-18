FactoryBot.define do
  factory :sprint_winner do
    association :sprint
    association :group
    completion_percentage { 80 }
    on_schedule_percentage { 70 }
  end
end
