class CreateCheckIns < ActiveRecord::Migration[7.2]
  def change
    create_table :check_ins do |t|
      t.date :recorded_on
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :check_ins, :recorded_on
  end
end
