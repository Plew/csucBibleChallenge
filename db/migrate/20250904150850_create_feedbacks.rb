class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: true, foreign_key: true
      t.integer :category
      t.string :subject
      t.text :message

      t.timestamps
    end
  end
end
