class CreateStatWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :stat_windows do |t|
      t.string :title
      t.date :begin_date
      t.date :end_date
      t.references :challenge, null: false, foreign_key: true

      t.timestamps
    end
  end
end
