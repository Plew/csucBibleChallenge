class CreateReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :readings do |t|
      t.references :challenge, null: false, foreign_key: true
      t.string :title
      t.date :scheduled_date

      t.timestamps
    end
  end
end
