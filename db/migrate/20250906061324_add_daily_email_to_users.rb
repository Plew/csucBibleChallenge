class AddDailyEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :daily_email, :boolean, default: true
  end
end
