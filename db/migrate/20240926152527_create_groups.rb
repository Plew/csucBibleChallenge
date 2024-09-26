class CreateGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :groups do |t|
      t.integer :creator_id
      t.string :name

      t.timestamps
    end
  end
end
