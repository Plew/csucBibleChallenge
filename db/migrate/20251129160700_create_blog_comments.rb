class CreateBlogComments < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_comments do |t|
      t.references :blog_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :blog_comments, [:blog_post_id, :created_at]
  end
end
