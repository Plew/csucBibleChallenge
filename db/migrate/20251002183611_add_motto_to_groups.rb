class AddMottoToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :motto, :text
  end
end
