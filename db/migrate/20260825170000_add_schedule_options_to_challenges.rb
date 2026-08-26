# frozen_string_literal: true

class AddScheduleOptionsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :chapters_per_day, :integer, default: 1, null: false
    add_column :challenges, :skip_days_of_week, :text, default: "[]"
    add_column :challenges, :skip_dates, :text, default: "[]"
  end
end
