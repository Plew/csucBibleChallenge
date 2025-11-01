class AddMessageOfTheDayToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :message_of_the_day, :text
  end
end
