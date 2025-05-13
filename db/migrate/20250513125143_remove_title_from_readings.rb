class RemoveTitleFromReadings < ActiveRecord::Migration[8.0]
  def change
    remove_column :readings, :title, :string
  end
end
