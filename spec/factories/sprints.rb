FactoryBot.define do
  factory :sprint do
    title { "Test Sprint" }
    association :challenge

    transient do
      offset_days { 30 }
    end

    begin_date { challenge.start_date + offset_days.days }
    end_date { begin_date + 30.days }
  end
end
