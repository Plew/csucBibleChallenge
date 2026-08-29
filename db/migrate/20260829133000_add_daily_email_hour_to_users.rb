class AddDailyEmailHourToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :daily_email_hour, :integer, default: 6, null: false
  end
end
