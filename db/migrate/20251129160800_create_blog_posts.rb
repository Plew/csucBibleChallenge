class CreateBlogPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_posts do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.boolean :visible, default: true, null: false

      t.timestamps
    end

    add_index :blog_posts, [ :challenge_id, :created_at ]
    add_index :blog_posts, :visible
  end
end
